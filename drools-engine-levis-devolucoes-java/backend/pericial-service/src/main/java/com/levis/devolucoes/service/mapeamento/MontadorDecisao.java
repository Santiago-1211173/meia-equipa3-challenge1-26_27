package com.levis.devolucoes.service.mapeamento;

import com.levis.devolucoes.dto.decisao.DecisaoResponse;
import com.levis.devolucoes.dto.decisao.RegistoRegraResponse;
import com.levis.devolucoes.dto.decisao.ResultadoArtigoResponse;
import com.levis.devolucoes.dto.enums.BaseValor;
import com.levis.devolucoes.dto.enums.MeioReembolso;
import com.levis.devolucoes.dto.enums.NivelAprovacao;
import com.levis.devolucoes.dto.enums.ProcessoObrigatorio;
import com.levis.devolucoes.dto.enums.TipoTransacao;
import com.levis.devolucoes.dto.enums.TipoVerificacao;
import com.levis.devolucoes.explicacao.catalogo.CatalogoRegras;
import com.levis.devolucoes.explicacao.catalogo.MetadadosRegra;
import com.levis.devolucoes.explicacao.motor.ResultadoExecucao;
import com.levis.devolucoes.explicacao.rastreio.EventoRegra;
import com.levis.devolucoes.model.decisao.Decisao;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Component;

/** Monta a resposta da decisão a partir do resultado do motor e do rastreio. */
@Component
public class MontadorDecisao {

  private final DecisaoMapper mapper;
  private final CatalogoRegras catalogo;

  public MontadorDecisao(DecisaoMapper mapper, CatalogoRegras catalogo) {
    this.mapper = mapper;
    this.catalogo = catalogo;
  }

  public DecisaoResponse montar(
      ResultadoExecucao resultado, UUID avaliacaoId, LocalDateTime avaliadaEm, String versao) {
    Decisao d = resultado.decisao();
    List<ResultadoArtigoResponse> artigos =
        resultado.artigos().values().stream().map(mapper::artigo).toList();

    List<RegistoRegraResponse> regras = new ArrayList<>();
    List<String> aValidar = new ArrayList<>();
    for (EventoRegra disparo : resultado.rastreio().disparos()) {
      boolean marcada =
          catalogo.porNome(disparo.nomeRegra()).map(MetadadosRegra::aValidar).orElse(false);
      regras.add(
          new RegistoRegraResponse(
              regras.size() + 1,
              disparo.codigoRegra(),
              disparo.nomeRegra(),
              disparo.modulo(),
              disparo.artigoId(),
              mapper.elegibilidade(disparo.resultado()),
              disparo.mensagem(),
              marcada));
      if (marcada && !aValidar.contains(disparo.codigoRegra())) {
        aValidar.add(disparo.codigoRegra());
      }
    }

    return new DecisaoResponse(
        avaliacaoId,
        d.getPedidoId(),
        avaliadaEm,
        versao,
        mapper.elegibilidade(d.getElegibilidade()),
        porNome(TipoVerificacao.class, d.getTipoVerificacao()),
        porNome(TipoTransacao.class, d.getTipoTransacao()),
        d.getValorDevolucao(),
        porNome(BaseValor.class, d.getBaseValor()),
        porNome(MeioReembolso.class, d.getMeioReembolso()),
        porNome(NivelAprovacao.class, d.getAprovacao()),
        porNome(ProcessoObrigatorio.class, d.getProcesso()),
        d.isTerminal(),
        d.isExcecaoRecusada(),
        mapper.documentacao(d.getDocumentacao()),
        artigos,
        regras,
        aValidar,
        mapper.graus(d.getGrausCrenca()));
  }

  private static <E extends Enum<E>> E porNome(Class<E> tipo, Enum<?> valor) {
    return valor == null ? null : Enum.valueOf(tipo, valor.name());
  }
}
