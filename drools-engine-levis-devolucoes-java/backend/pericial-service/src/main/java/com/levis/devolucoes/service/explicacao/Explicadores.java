package com.levis.devolucoes.service.explicacao;

import com.levis.devolucoes.explicacao.catalogo.CatalogoRegras;
import com.levis.devolucoes.explicacao.como.ExplicadorComo;
import com.levis.devolucoes.explicacao.esenao.ClonadorFactos;
import com.levis.devolucoes.explicacao.esenao.SimuladorCenario;
import com.levis.devolucoes.explicacao.incerteza.ExplicadorIncerteza;
import com.levis.devolucoes.explicacao.motor.ExecutorSessao;
import com.levis.devolucoes.explicacao.porque.DependenciasDados;
import com.levis.devolucoes.explicacao.porque.ExplicadorPorque;
import com.levis.devolucoes.explicacao.porquenao.AvaliadorCondicoes;
import com.levis.devolucoes.explicacao.porquenao.ExplicadorPorqueNao;
import com.levis.devolucoes.explicacao.texto.GeradorTexto;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.stereotype.Component;

/**
 * Fábrica dos explicadores no idioma pedido (pt-PT ou en). Os explicadores são leves; os textos são
 * guardados por idioma.
 */
@Component
public class Explicadores {

  private final CatalogoRegras catalogo;
  private final AvaliadorCondicoes avaliador;
  private final DependenciasDados dependencias;
  private final ExecutorSessao executor;
  private final ClonadorFactos clonador;
  private final Map<Locale, GeradorTexto> textos = new ConcurrentHashMap<>();

  public Explicadores(
      CatalogoRegras catalogo,
      AvaliadorCondicoes avaliador,
      DependenciasDados dependencias,
      ExecutorSessao executor,
      ClonadorFactos clonador) {
    this.catalogo = catalogo;
    this.avaliador = avaliador;
    this.dependencias = dependencias;
    this.executor = executor;
    this.clonador = clonador;
  }

  /** Textos no idioma pedido; inglês para "en", português nos restantes casos. */
  public GeradorTexto texto(Locale locale) {
    Locale idioma =
        locale != null && "en".equals(locale.getLanguage()) ? Locale.ENGLISH : GeradorTexto.PT_PT;
    return textos.computeIfAbsent(idioma, GeradorTexto::new);
  }

  public ExplicadorComo como(Locale locale) {
    return new ExplicadorComo(catalogo, avaliador, texto(locale));
  }

  public ExplicadorPorqueNao porqueNao(Locale locale) {
    return new ExplicadorPorqueNao(catalogo, avaliador, texto(locale));
  }

  public ExplicadorPorque porque(Locale locale) {
    return new ExplicadorPorque(catalogo, avaliador, dependencias, texto(locale));
  }

  /** Explicações dos graus da camada de incerteza (docs/08 §7.2). */
  public ExplicadorIncerteza incerteza(Locale locale) {
    return new ExplicadorIncerteza(executor.incerteza(), texto(locale));
  }

  public SimuladorCenario simulador(Locale locale) {
    return new SimuladorCenario(executor, clonador, texto(locale));
  }
}
