package com.levis.devolucoes.model.decisao;

import com.levis.devolucoes.model.enums.Elegibilidade;
import com.levis.devolucoes.model.enums.Modulo;
import java.time.Clock;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Comportamento comum a {@link Decisao} (pedido) e {@link DecisaoArtigo} (artigo): elegibilidade,
 * paragem do fluxo e rasto das regras. A semântica está descrita no ADR 0004.
 */
public abstract class DecisaoBase {

  private Elegibilidade elegibilidade;
  private boolean terminal;
  private List<RegistoRegra> registos = new ArrayList<>();
  private Clock relogio = Clock.systemDefaultZone();

  /**
   * Aplica o resultado de uma regra. Nunca baixa a severidade já registada; marca {@code terminal}
   * quando a regra é uma paragem obrigatória e o resultado é RECUSAR ou ENCAMINHAR.
   */
  public void aplicar(String regra, Modulo modulo, Elegibilidade resultado, String mensagem) {
    registar(regra, modulo, resultado, mensagem);
    if (resultado.maisSeveroQue(elegibilidade)) {
      elegibilidade = resultado;
    }
    if (RegrasParagem.isParagem(regra)
        && (resultado == Elegibilidade.RECUSAR || resultado == Elegibilidade.ENCAMINHAR)) {
      terminal = true;
    }
  }

  /**
   * Resolve uma revisão: passa de REVER a PERMITIR (ex.: PC-002 com IN-010 = sim). Sem efeito na
   * elegibilidade se esta não for REVER; a regra fica sempre registada.
   */
  public void resolverRevisao(String regra, Modulo modulo, String mensagem) {
    registar(regra, modulo, Elegibilidade.PERMITIR, mensagem);
    if (elegibilidade == Elegibilidade.REVER) {
      elegibilidade = Elegibilidade.PERMITIR;
    }
  }

  /** Regista uma regra que só define uma ação, um valor ou documentação, sem resultado. */
  public void registar(String regra, Modulo modulo, String mensagem) {
    registar(regra, modulo, null, mensagem);
  }

  /** Termina o fluxo sem passar pelo conjunto de paragens (usado por EX-008, ADR 0004). */
  protected void terminar() {
    terminal = true;
  }

  /** Define a elegibilidade diretamente, sem a regra de severidade (usado por EX-008). */
  protected void definirElegibilidade(Elegibilidade elegibilidade) {
    this.elegibilidade = elegibilidade;
  }

  /** Acrescenta uma entrada ao rasto, sem alterar a elegibilidade. */
  protected void registar(String regra, Modulo modulo, Elegibilidade resultado, String mensagem) {
    registos.add(new RegistoRegra(regra, modulo, resultado, mensagem, LocalDateTime.now(relogio)));
  }

  /** Indica se a regra indicada já disparou sobre esta decisão. */
  public boolean disparou(String regra) {
    return registos.stream().anyMatch(r -> r.getCodigoRegra().equals(regra));
  }

  /** Indica se a regra indicada já disparou sobre esta decisão com o resultado indicado. */
  public boolean disparouCom(String regra, Elegibilidade resultado) {
    return registos.stream()
        .anyMatch(r -> r.getCodigoRegra().equals(regra) && r.getResultado() == resultado);
  }

  /** Relógio usado nos instantes do rasto; permite testes determinísticos. */
  public void usarRelogio(Clock relogio) {
    this.relogio = relogio;
  }

  public Elegibilidade getElegibilidade() {
    return elegibilidade;
  }

  public void setElegibilidade(Elegibilidade elegibilidade) {
    this.elegibilidade = elegibilidade;
  }

  public boolean isTerminal() {
    return terminal;
  }

  public void setTerminal(boolean terminal) {
    this.terminal = terminal;
  }

  public List<RegistoRegra> getRegistos() {
    return registos;
  }

  public void setRegistos(List<RegistoRegra> registos) {
    this.registos = registos;
  }
}
