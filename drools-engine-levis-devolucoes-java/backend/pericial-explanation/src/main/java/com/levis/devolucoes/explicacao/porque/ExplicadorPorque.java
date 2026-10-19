package com.levis.devolucoes.explicacao.porque;

import com.levis.devolucoes.explicacao.catalogo.CatalogoRegras;
import com.levis.devolucoes.explicacao.catalogo.MetadadosRegra;
import com.levis.devolucoes.explicacao.emfalta.DadoEmFalta;
import com.levis.devolucoes.explicacao.motor.ResultadoExecucao;
import com.levis.devolucoes.explicacao.porquenao.AvaliadorCondicoes;
import com.levis.devolucoes.explicacao.porquenao.ContextoAvaliacao;
import com.levis.devolucoes.explicacao.porquenao.ResultadoCondicao;
import com.levis.devolucoes.explicacao.texto.GeradorTexto;
import com.levis.devolucoes.model.produto.ArtigoDevolvido;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * "Porquê?": justifica porque é que o sistema faz uma pergunta ao colaborador. Indica as regras que
 * dependem da resposta e, no pedido atual, as que só esperam por ela para concluir (as outras
 * condições já se cumprem), com as conclusões que cada uma produziria.
 */
public class ExplicadorPorque {

  private final CatalogoRegras catalogo;
  private final AvaliadorCondicoes avaliador;
  private final DependenciasDados dependencias;
  private final GeradorTexto texto;

  public ExplicadorPorque(
      CatalogoRegras catalogo,
      AvaliadorCondicoes avaliador,
      DependenciasDados dependencias,
      GeradorTexto texto) {
    this.catalogo = catalogo;
    this.avaliador = avaliador;
    this.dependencias = dependencias;
    this.texto = texto;
  }

  /** Porquê de um dado em falta devolvido pelo "O que falta?". */
  public ExplicacaoPorque explicar(DadoEmFalta emFalta, ResultadoExecucao resultadoAtual) {
    DadoEntrada dado =
        DadoEntrada.deCodigo(emFalta.codigo())
            .orElseThrow(
                () -> new IllegalArgumentException("Dado desconhecido: " + emFalta.codigo()));
    return explicar(dado, resultadoAtual);
  }

  /**
   * @param dado pergunta
   * @param resultadoAtual avaliação do pedido tal como está (possivelmente incompleto)
   */
  public ExplicacaoPorque explicar(DadoEntrada dado, ResultadoExecucao resultadoAtual) {
    List<MetadadosRegra> relacionadas =
        catalogo.regras().stream()
            .filter(r -> r.condicoes().stream().anyMatch(c -> dependencias.le(c, dado)))
            .toList();
    List<String> ids = relacionadas.stream().map(MetadadosRegra::id).distinct().toList();

    List<RegraEmEspera> emEspera = new ArrayList<>();
    for (MetadadosRegra regra : relacionadas) {
      for (ContextoAvaliacao contexto : contextos(regra, resultadoAtual)) {
        String artigoId = contexto.temArtigo() ? contexto.artigo().getId() : null;
        if (resultadoAtual.rastreio().eventos().stream()
            .anyMatch(
                e -> e.disparou() && e.nomeRegra().equals(regra.nome()) && e.doArtigo(artigoId))) {
          continue;
        }
        if (bloqueada(regra, contexto)) {
          continue;
        }
        List<ResultadoCondicao> condicoes = avaliador.avaliar(regra, contexto);
        boolean outrasCumpridas =
            condicoes.stream()
                .filter(c -> !dependencias.le(c.nome(), dado))
                .noneMatch(c -> Boolean.FALSE.equals(c.cumprida()));
        if (outrasCumpridas) {
          emEspera.add(
              new RegraEmEspera(
                  regra.id(),
                  regra.nome(),
                  regra.modulo(),
                  artigoId,
                  regra.conclusoes(),
                  condicoes.stream().filter(c -> dependencias.le(c.nome(), dado)).toList()));
        }
      }
    }

    String resumo =
        emEspera.isEmpty()
            ? texto.formatar("porque.sem_espera", dado.racional(), String.join(", ", ids))
            : texto.formatar(
                "porque.pergunta",
                dado.pergunta(),
                emEspera.size(),
                emEspera.stream()
                    .map(
                        r ->
                            r.codigoRegra()
                                + (r.artigoId() == null ? "" : " [" + r.artigoId() + "]")
                                + (r.conclusoes().isEmpty() ? "" : " → " + r.conclusoes()))
                    .collect(Collectors.joining("; ")));
    return new ExplicacaoPorque(dado, dado.pergunta(), ids, emEspera, resumo);
  }

  /** A regra não pode disparar por causa de uma paragem anterior (a guarda terminal). */
  private static boolean bloqueada(MetadadosRegra regra, ContextoAvaliacao contexto) {
    if (regra.semGuardaTerminal()) {
      return false;
    }
    return contexto.decisao().isTerminal()
        || (contexto.decisaoArtigo() != null && contexto.decisaoArtigo().isTerminal());
  }

  private List<ContextoAvaliacao> contextos(MetadadosRegra regra, ResultadoExecucao resultado) {
    List<ContextoAvaliacao> contextos = new ArrayList<>();
    if (!avaliador.temCondicoesDeArtigo(regra)) {
      contextos.add(ContextoAvaliacao.doPedido(resultado));
      return contextos;
    }
    for (ArtigoDevolvido artigo : resultado.pedido().getArtigos()) {
      contextos.add(ContextoAvaliacao.doArtigo(resultado, artigo.getId()));
    }
    return contextos;
  }
}
