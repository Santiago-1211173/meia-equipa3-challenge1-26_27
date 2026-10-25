package com.levis.devolucoes.explicacao;

import com.levis.devolucoes.explicacao.catalogo.CatalogoRegras;
import com.levis.devolucoes.explicacao.motor.ExecutorSessao;
import com.levis.devolucoes.explicacao.motor.ResultadoExecucao;
import com.levis.devolucoes.explicacao.porquenao.AvaliadorCondicoes;
import com.levis.devolucoes.explicacao.porquenao.RegistoPredicados;
import com.levis.devolucoes.explicacao.texto.GeradorTexto;
import com.levis.devolucoes.incerteza.ServicoIncerteza;
import com.levis.devolucoes.model.decisao.IndicadorFraude;
import com.levis.devolucoes.model.pedido.PedidoDevolucao;
import com.levis.devolucoes.regras.OrdemAgenda;
import com.levis.devolucoes.regras.cenarios.CarregadorCenarios;
import com.levis.devolucoes.regras.cenarios.Cenario;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import org.kie.api.KieServices;
import org.kie.api.runtime.KieContainer;

/** Peças das explicações montadas sobre o kjar do classpath, partilhadas pelos testes. */
public final class SuporteExplicacoes {

  public static final KieContainer CONTENTOR = KieServices.Factory.get().getKieClasspathContainer();

  public static final ExecutorSessao EXECUTOR =
      new ExecutorSessao(
          CONTENTOR,
          OrdemAgenda.SESSAO,
          OrdemAgenda.GRUPOS,
          Clock.fixed(Instant.parse("2026-03-31T10:00:00Z"), ZoneOffset.UTC),
          ServicoIncerteza.comParametros("parametros-incerteza-teste.yml"));

  public static final CatalogoRegras CATALOGO = CatalogoRegras.de(CONTENTOR.getKieBase("pericial"));

  public static final RegistoPredicados PREDICADOS = new RegistoPredicados();

  public static final AvaliadorCondicoes AVALIADOR = new AvaliadorCondicoes(PREDICADOS);

  public static final GeradorTexto TEXTO = GeradorTexto.portugues();

  private SuporteExplicacoes() {}

  public static ResultadoExecucao executar(PedidoDevolucao pedido, IndicadorFraude... fraudes) {
    return EXECUTOR.executar(pedido, List.of(fraudes));
  }

  /** Executa um cenário de docs/06 (factos novos em cada chamada). */
  public static ResultadoExecucao cenario(int numero) {
    Cenario cenario = CarregadorCenarios.ler(numero);
    return EXECUTOR.executar(
        cenario.pedido(),
        cenario.indicadoresFraude() == null ? List.of() : cenario.indicadoresFraude());
  }

  /** Pedido de um cenário, por avaliar. */
  public static PedidoDevolucao pedidoDoCenario(int numero) {
    return CarregadorCenarios.ler(numero).pedido();
  }
}
