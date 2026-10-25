package com.levis.devolucoes.service.motor;

import com.levis.devolucoes.explicacao.catalogo.CatalogoRegras;
import com.levis.devolucoes.explicacao.emfalta.DetetorDadosEmFalta;
import com.levis.devolucoes.explicacao.esenao.ClonadorFactos;
import com.levis.devolucoes.explicacao.motor.ExecutorSessao;
import com.levis.devolucoes.explicacao.porque.DependenciasDados;
import com.levis.devolucoes.explicacao.porquenao.AvaliadorCondicoes;
import com.levis.devolucoes.explicacao.porquenao.RegistoPredicados;
import com.levis.devolucoes.incerteza.ServicoIncerteza;
import com.levis.devolucoes.regras.OrdemAgenda;
import java.time.Clock;
import org.kie.api.KieServices;
import org.kie.api.runtime.KieContainer;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Motor de regras e peças das explicações (ADR 0005): o kjar do classpath, o executor com a ordem
 * da agenda, o catálogo, os predicados e a versão da base de conhecimento.
 */
@Configuration
public class MotorRegrasConfig {

  @Bean
  @ConditionalOnMissingBean
  public Clock relogio() {
    return Clock.systemDefaultZone();
  }

  @Bean
  public KieContainer kieContainer() {
    return KieServices.Factory.get().getKieClasspathContainer();
  }

  /**
   * Camada de incerteza com o ficheiro de parâmetros demonstrativos; falha no arranque se for
   * inválido.
   */
  @Bean
  @ConditionalOnMissingBean
  public ServicoIncerteza servicoIncerteza() {
    return ServicoIncerteza.padrao();
  }

  @Bean
  public ExecutorSessao executorSessao(
      KieContainer kieContainer, Clock relogio, ServicoIncerteza servicoIncerteza) {
    return new ExecutorSessao(
        kieContainer, OrdemAgenda.SESSAO, OrdemAgenda.GRUPOS, relogio, servicoIncerteza);
  }

  @Bean
  public VersaoBaseConhecimento versaoBaseConhecimento(KieContainer kieContainer) {
    return VersaoBaseConhecimento.de(kieContainer);
  }

  @Bean
  public CatalogoRegras catalogoRegras(KieContainer kieContainer) {
    return CatalogoRegras.de(kieContainer.getKieBase("pericial"));
  }

  @Bean
  public RegistoPredicados registoPredicados() {
    return new RegistoPredicados();
  }

  @Bean
  public AvaliadorCondicoes avaliadorCondicoes(RegistoPredicados registoPredicados) {
    return new AvaliadorCondicoes(registoPredicados);
  }

  @Bean
  public DependenciasDados dependenciasDados() {
    return new DependenciasDados();
  }

  @Bean
  public DetetorDadosEmFalta detetorDadosEmFalta() {
    return new DetetorDadosEmFalta();
  }

  @Bean
  public ClonadorFactos clonadorFactos() {
    return new ClonadorFactos();
  }
}
