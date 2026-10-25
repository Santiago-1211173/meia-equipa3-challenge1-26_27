package com.levis.devolucoes.regras.suporte;

import com.levis.devolucoes.incerteza.FabricaEvidencias;
import com.levis.devolucoes.incerteza.ServicoIncerteza;
import com.levis.devolucoes.model.decisao.Decisao;
import com.levis.devolucoes.model.decisao.DecisaoArtigo;
import com.levis.devolucoes.model.decisao.IndicadorFraude;
import com.levis.devolucoes.model.pedido.PedidoDevolucao;
import com.levis.devolucoes.model.produto.ArtigoDevolvido;
import com.levis.devolucoes.regras.OrdemAgenda;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.drools.base.definitions.rule.impl.RuleImpl;
import org.kie.api.KieBase;
import org.kie.api.KieServices;
import org.kie.api.definition.rule.Rule;
import org.kie.api.event.rule.AfterMatchFiredEvent;
import org.kie.api.event.rule.DefaultAgendaEventListener;
import org.kie.api.runtime.KieContainer;
import org.kie.api.runtime.KieSession;

/**
 * Executa a base de conhecimento compilada (kjar do classpath) sobre um pedido, como fará o
 * MotorRegrasService: insere o pedido, cada artigo com a sua DecisaoArtigo, a Decisao e os indícios
 * de fraude, e dá o foco aos agenda-groups pela ordem de {@link OrdemAgenda}.
 */
public final class MotorTeste {

  /** Limite de disparos: acima disto há um ciclo nas regras. */
  public static final int LIMITE_DISPAROS = 1_000;

  private static final Clock RELOGIO =
      Clock.fixed(Instant.parse("2026-03-31T10:00:00Z"), ZoneOffset.UTC);

  private static final KieContainer CONTENTOR =
      KieServices.Factory.get().getKieClasspathContainer();

  /** Camada de incerteza com os parâmetros fixos de teste (docs/08 §6). */
  public static final ServicoIncerteza INCERTEZA =
      ServicoIncerteza.comParametros("parametros-incerteza-teste.yml");

  private static final FabricaEvidencias EVIDENCIAS = new FabricaEvidencias(INCERTEZA);

  private MotorTeste() {}

  public static KieBase kieBase() {
    return CONTENTOR.getKieBase("pericial");
  }

  /** Regras da kbase, sem as consultas (que a API também devolve em {@code getRules()}). */
  public static List<Rule> regras() {
    return kieBase().getKiePackages().stream()
        .flatMap(p -> p.getRules().stream())
        .filter(r -> !((RuleImpl) r).isQuery())
        .toList();
  }

  public static ResultadoAvaliacao avaliar(PedidoDevolucao pedido, IndicadorFraude... fraudes) {
    return avaliar(pedido, List.of(fraudes));
  }

  public static ResultadoAvaliacao avaliar(PedidoDevolucao pedido, List<IndicadorFraude> fraudes) {
    KieSession sessao = CONTENTOR.newKieSession(OrdemAgenda.SESSAO);
    sessao.setGlobal("incerteza", INCERTEZA);
    List<String> disparos = new ArrayList<>();
    sessao.addEventListener(
        new DefaultAgendaEventListener() {
          @Override
          public void afterMatchFired(AfterMatchFiredEvent evento) {
            disparos.add(String.valueOf(evento.getMatch().getRule().getMetaData().get("id")));
          }
        });
    try {
      Decisao decisao = new Decisao(pedido.getId());
      decisao.usarRelogio(RELOGIO);
      Map<String, DecisaoArtigo> artigos = new LinkedHashMap<>();

      sessao.insert(pedido);
      for (ArtigoDevolvido artigo : pedido.getArtigos()) {
        DecisaoArtigo decisaoArtigo = new DecisaoArtigo(pedido.getId(), artigo.getId());
        decisaoArtigo.usarRelogio(RELOGIO);
        artigos.put(artigo.getId(), decisaoArtigo);
        sessao.insert(artigo);
        sessao.insert(decisaoArtigo);
      }
      sessao.insert(decisao);
      EVIDENCIAS.evidencias(pedido).forEach(sessao::insert);
      for (IndicadorFraude fraude : fraudes) {
        sessao.insert(fraude);
      }

      for (String grupo : OrdemAgenda.ordemDeFoco()) {
        sessao.getAgenda().getAgendaGroup(grupo).setFocus();
      }
      int total = sessao.fireAllRules(LIMITE_DISPAROS);
      if (total >= LIMITE_DISPAROS) {
        throw new IllegalStateException("Possível ciclo nas regras: " + total + " disparos");
      }
      return new ResultadoAvaliacao(decisao, artigos, List.copyOf(disparos));
    } finally {
      sessao.dispose();
    }
  }
}
