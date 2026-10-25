package com.levis.devolucoes.service.auditoria;

import com.levis.devolucoes.dto.decisao.DecisaoResponse;
import com.levis.devolucoes.explicacao.motor.ResultadoExecucao;
import com.levis.devolucoes.explicacao.rastreio.EventoRegra;
import com.levis.devolucoes.model.pedido.PedidoExcecao;
import com.levis.devolucoes.persistencia.entidade.AvaliacaoEntity;
import com.levis.devolucoes.persistencia.entidade.ExcecaoAprovadaEntity;
import com.levis.devolucoes.persistencia.entidade.RegistoRegraEntity;
import com.levis.devolucoes.persistencia.repositorio.AvaliacaoRepository;
import com.levis.devolucoes.service.excecao.RecursoNaoEncontradoException;
import com.levis.devolucoes.service.mapeamento.JsonServico;
import java.time.LocalDateTime;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Grava cada avaliação com a versão da base de conhecimento, o pedido tal como foi avaliado, a
 * decisão e o rasto das regras; regista as exceções aprovadas (EX-007).
 */
@Service
public class AuditoriaService {

  private final AvaliacaoRepository avaliacoes;

  public AuditoriaService(AvaliacaoRepository avaliacoes) {
    this.avaliacoes = avaliacoes;
  }

  /** Avaliação gravada, com os factos necessários para a reavaliar e explicar. */
  public record AvaliacaoGravada(
      UUID id,
      String versaoBaseConhecimento,
      String pedidoJson,
      String fraudesJson,
      String decisaoJson) {}

  @Transactional
  public void gravar(
      DecisaoResponse decisao,
      ResultadoExecucao resultado,
      String pedidoJson,
      String fraudesJson,
      LocalDateTime avaliadaEm) {
    AvaliacaoEntity entidade = new AvaliacaoEntity();
    entidade.setId(decisao.avaliacaoId());
    entidade.setPedidoId(decisao.pedidoId());
    entidade.setCriadaEm(avaliadaEm);
    entidade.setLojaCodigo(
        resultado.pedido().getLoja() == null ? null : resultado.pedido().getLoja().getCodigo());
    entidade.setColaboradorId(
        resultado.pedido().getColaborador() == null
            ? null
            : resultado.pedido().getColaborador().getId());
    entidade.setVersaoBaseConhecimento(decisao.versaoBaseConhecimento());
    entidade.setVersaoParametrosIncerteza(resultado.decisao().getVersaoParametrosIncerteza());
    entidade.setElegibilidade(nome(decisao.elegibilidade()));
    entidade.setTipoVerificacao(nome(decisao.tipoVerificacao()));
    entidade.setTipoTransacao(nome(decisao.tipoTransacao()));
    entidade.setValorDevolucao(decisao.valorDevolucao());
    entidade.setBaseValor(nome(decisao.baseValor()));
    entidade.setMeioReembolso(nome(decisao.meioReembolso()));
    entidade.setAprovacao(nome(decisao.aprovacao()));
    entidade.setProcesso(nome(decisao.processo()));
    entidade.setTerminal(decisao.terminal());
    entidade.setExcecaoRecusada(decisao.excecaoRecusada());
    entidade.setPedidoJson(pedidoJson);
    entidade.setIndicadoresFraudeJson(fraudesJson);
    entidade.setDecisaoJson(JsonServico.escrever(decisao));

    int ordem = 0;
    for (EventoRegra disparo : resultado.rastreio().disparos()) {
      ordem++;
      entidade.acrescentarRegisto(
          new RegistoRegraEntity(
              ordem,
              disparo.codigoRegra(),
              disparo.nomeRegra(),
              disparo.modulo(),
              disparo.artigoId(),
              nome(disparo.resultado()),
              disparo.mensagem(),
              avaliadaEm));
    }
    if (resultado.rastreio().disparou("EX-007", null)) {
      entidade.acrescentarExcecao(excecaoAprovada(decisao, resultado, avaliadaEm));
    }
    avaliacoes.save(entidade);
  }

  private static ExcecaoAprovadaEntity excecaoAprovada(
      DecisaoResponse decisao, ResultadoExecucao resultado, LocalDateTime avaliadaEm) {
    PedidoExcecao pedido = resultado.pedido().getPedidoExcecao();
    ExcecaoAprovadaEntity excecao = new ExcecaoAprovadaEntity();
    excecao.setId(UUID.randomUUID());
    excecao.setRegistadaEm(avaliadaEm);
    excecao.setMotivo(pedido == null ? null : pedido.getMotivo());
    excecao.setAprovador(
        pedido == null || pedido.getAprovador() == null
            ? null
            : pedido.getAprovador().getNome() + " (" + pedido.getAprovador().getFuncao() + ")");
    excecao.setValor(decisao.valorDevolucao());
    excecao.setResultado(nome(decisao.tipoTransacao()));
    excecao.setPreocupacaoCliente(pedido == null ? null : pedido.getPreocupacaoCliente());
    excecao.setDestinoProduto(
        decisao.artigos().stream()
            .map(a -> a.artigoId() + ": " + nome(a.destino()))
            .collect(Collectors.joining("; ")));
    excecao.setRegisto(
        decisao.documentacao() == null || decisao.documentacao().registoExcecao() == null
            ? "Exceção aprovada"
            : decisao.documentacao().registoExcecao());
    return excecao;
  }

  @Transactional(readOnly = true)
  public AvaliacaoGravada carregar(UUID id) {
    AvaliacaoEntity entidade =
        avaliacoes
            .findById(id)
            .orElseThrow(() -> new RecursoNaoEncontradoException("Avaliação inexistente: " + id));
    return new AvaliacaoGravada(
        entidade.getId(),
        entidade.getVersaoBaseConhecimento(),
        entidade.getPedidoJson(),
        entidade.getIndicadoresFraudeJson(),
        entidade.getDecisaoJson());
  }

  @Transactional(readOnly = true)
  public Page<AvaliacaoEntity> listar(String lojaCodigo, Pageable pagina) {
    return lojaCodigo == null || lojaCodigo.isBlank()
        ? avaliacoes.findAll(pagina)
        : avaliacoes.findByLojaCodigo(lojaCodigo, pagina);
  }

  private static String nome(Enum<?> valor) {
    return valor == null ? null : valor.name();
  }
}
