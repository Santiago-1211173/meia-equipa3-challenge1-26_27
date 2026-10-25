package com.levis.devolucoes.persistencia.entidade;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/**
 * Avaliação guardada: os campos de saída principais (para consulta), os factos de entrada e a
 * decisão completa em JSON, a versão da base de conhecimento e o rasto das regras. Separada dos
 * factos Drools (convenções do projeto, README): os enums são guardados como texto.
 */
@Entity
@Table(name = "avaliacao")
public class AvaliacaoEntity {

  @Id private UUID id;

  @Column(name = "pedido_id", nullable = false)
  private String pedidoId;

  @Column(name = "criada_em", nullable = false)
  private LocalDateTime criadaEm;

  @Column(name = "loja_codigo")
  private String lojaCodigo;

  @Column(name = "colaborador_id")
  private String colaboradorId;

  /** groupId:artifactId:version do kjar usado (auditoria). */
  @Column(name = "versao_base_conhecimento", nullable = false)
  private String versaoBaseConhecimento;

  /** Versão do ficheiro de parâmetros de incerteza (docs/08); nula antes da camada de incerteza. */
  @Column(name = "versao_parametros_incerteza")
  private String versaoParametrosIncerteza;

  private String elegibilidade;

  @Column(name = "tipo_verificacao")
  private String tipoVerificacao;

  @Column(name = "tipo_transacao")
  private String tipoTransacao;

  @Column(name = "valor_devolucao")
  private BigDecimal valorDevolucao;

  @Column(name = "base_valor")
  private String baseValor;

  @Column(name = "meio_reembolso")
  private String meioReembolso;

  private String aprovacao;

  private String processo;

  @Column(nullable = false)
  private boolean terminal;

  @Column(name = "excecao_recusada", nullable = false)
  private boolean excecaoRecusada;

  /** Pedido tal como foi submetido (antes da avaliação), para reavaliar e explicar. */
  @JdbcTypeCode(SqlTypes.JSON)
  @Column(name = "pedido_json", nullable = false)
  private String pedidoJson;

  @JdbcTypeCode(SqlTypes.JSON)
  @Column(name = "indicadores_fraude_json", nullable = false)
  private String indicadoresFraudeJson = "[]";

  /** Decisão completa (OUT-001 a OUT-008 e resultados por artigo). */
  @JdbcTypeCode(SqlTypes.JSON)
  @Column(name = "decisao_json", nullable = false)
  private String decisaoJson;

  @OneToMany(mappedBy = "avaliacao", cascade = CascadeType.ALL, orphanRemoval = true)
  @OrderBy("ordem")
  private List<RegistoRegraEntity> registos = new ArrayList<>();

  @OneToMany(mappedBy = "avaliacao", cascade = CascadeType.ALL, orphanRemoval = true)
  private List<ExcecaoAprovadaEntity> excecoesAprovadas = new ArrayList<>();

  /** Acrescenta um registo do rasto, ligando-o a esta avaliação. */
  public void acrescentarRegisto(RegistoRegraEntity registo) {
    registo.setAvaliacao(this);
    registos.add(registo);
  }

  /** Acrescenta o registo de uma exceção aprovada (EX-007). */
  public void acrescentarExcecao(ExcecaoAprovadaEntity excecao) {
    excecao.setAvaliacao(this);
    excecoesAprovadas.add(excecao);
  }

  public UUID getId() {
    return id;
  }

  public void setId(UUID id) {
    this.id = id;
  }

  public String getPedidoId() {
    return pedidoId;
  }

  public void setPedidoId(String pedidoId) {
    this.pedidoId = pedidoId;
  }

  public LocalDateTime getCriadaEm() {
    return criadaEm;
  }

  public void setCriadaEm(LocalDateTime criadaEm) {
    this.criadaEm = criadaEm;
  }

  public String getLojaCodigo() {
    return lojaCodigo;
  }

  public void setLojaCodigo(String lojaCodigo) {
    this.lojaCodigo = lojaCodigo;
  }

  public String getColaboradorId() {
    return colaboradorId;
  }

  public void setColaboradorId(String colaboradorId) {
    this.colaboradorId = colaboradorId;
  }

  public String getVersaoBaseConhecimento() {
    return versaoBaseConhecimento;
  }

  public void setVersaoBaseConhecimento(String versaoBaseConhecimento) {
    this.versaoBaseConhecimento = versaoBaseConhecimento;
  }

  public String getVersaoParametrosIncerteza() {
    return versaoParametrosIncerteza;
  }

  public void setVersaoParametrosIncerteza(String versaoParametrosIncerteza) {
    this.versaoParametrosIncerteza = versaoParametrosIncerteza;
  }

  public String getElegibilidade() {
    return elegibilidade;
  }

  public void setElegibilidade(String elegibilidade) {
    this.elegibilidade = elegibilidade;
  }

  public String getTipoVerificacao() {
    return tipoVerificacao;
  }

  public void setTipoVerificacao(String tipoVerificacao) {
    this.tipoVerificacao = tipoVerificacao;
  }

  public String getTipoTransacao() {
    return tipoTransacao;
  }

  public void setTipoTransacao(String tipoTransacao) {
    this.tipoTransacao = tipoTransacao;
  }

  public BigDecimal getValorDevolucao() {
    return valorDevolucao;
  }

  public void setValorDevolucao(BigDecimal valorDevolucao) {
    this.valorDevolucao = valorDevolucao;
  }

  public String getBaseValor() {
    return baseValor;
  }

  public void setBaseValor(String baseValor) {
    this.baseValor = baseValor;
  }

  public String getMeioReembolso() {
    return meioReembolso;
  }

  public void setMeioReembolso(String meioReembolso) {
    this.meioReembolso = meioReembolso;
  }

  public String getAprovacao() {
    return aprovacao;
  }

  public void setAprovacao(String aprovacao) {
    this.aprovacao = aprovacao;
  }

  public String getProcesso() {
    return processo;
  }

  public void setProcesso(String processo) {
    this.processo = processo;
  }

  public boolean isTerminal() {
    return terminal;
  }

  public void setTerminal(boolean terminal) {
    this.terminal = terminal;
  }

  public boolean isExcecaoRecusada() {
    return excecaoRecusada;
  }

  public void setExcecaoRecusada(boolean excecaoRecusada) {
    this.excecaoRecusada = excecaoRecusada;
  }

  public String getPedidoJson() {
    return pedidoJson;
  }

  public void setPedidoJson(String pedidoJson) {
    this.pedidoJson = pedidoJson;
  }

  public String getIndicadoresFraudeJson() {
    return indicadoresFraudeJson;
  }

  public void setIndicadoresFraudeJson(String indicadoresFraudeJson) {
    this.indicadoresFraudeJson = indicadoresFraudeJson;
  }

  public String getDecisaoJson() {
    return decisaoJson;
  }

  public void setDecisaoJson(String decisaoJson) {
    this.decisaoJson = decisaoJson;
  }

  public List<RegistoRegraEntity> getRegistos() {
    return registos;
  }

  public List<ExcecaoAprovadaEntity> getExcecoesAprovadas() {
    return excecoesAprovadas;
  }
}
