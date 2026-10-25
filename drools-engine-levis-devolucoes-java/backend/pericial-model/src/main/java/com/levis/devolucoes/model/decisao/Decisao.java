package com.levis.devolucoes.model.decisao;

import com.levis.devolucoes.model.enums.BaseValor;
import com.levis.devolucoes.model.enums.Elegibilidade;
import com.levis.devolucoes.model.enums.MeioReembolso;
import com.levis.devolucoes.model.enums.Modulo;
import com.levis.devolucoes.model.enums.NivelAprovacao;
import com.levis.devolucoes.model.enums.ProcessoObrigatorio;
import com.levis.devolucoes.model.enums.TipoTransacao;
import com.levis.devolucoes.model.enums.TipoVerificacao;
import com.levis.devolucoes.model.incerteza.GrauCrenca;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

/** Facto de saída do pedido: preenche os campos OUT-001 a OUT-008 e guarda o rasto das regras. */
public class Decisao extends DecisaoBase {

  private String pedidoId;
  private TipoVerificacao tipoVerificacao = TipoVerificacao.NAO_DETERMINADA;
  private TipoTransacao tipoTransacao;
  private BigDecimal valorDevolucao;
  private BaseValor baseValor;
  private MeioReembolso meioReembolso;
  private NivelAprovacao aprovacao = NivelAprovacao.NENHUMA;
  private ProcessoObrigatorio processo;
  private Documentacao documentacao = new Documentacao();

  /** O pedido de exceção do cliente foi recusado (HS-005, EX-006), sem alterar a elegibilidade. */
  private boolean excecaoRecusada;

  /** Resultados por artigo, agregados no fim da avaliação (ADR 0002). */
  private List<DecisaoArtigo> resultadosArtigos = new ArrayList<>();

  /** Graus calculados pela camada de incerteza (docs/08), com os passos do cálculo. */
  private List<GrauCrenca> grausCrenca = new ArrayList<>();

  /** Versão do ficheiro de parâmetros de incerteza usado na avaliação. */
  private String versaoParametrosIncerteza;

  public Decisao() {}

  public Decisao(String pedidoId) {
    this.pedidoId = pedidoId;
  }

  /**
   * EX-008: suspende a transação. Termina o fluxo, fica em REVER e exige escalonamento para
   * District ou Area (ADR 0004).
   */
  public void suspender(String regra, Modulo modulo, String mensagem) {
    registar(regra, modulo, Elegibilidade.REVER, mensagem);
    definirElegibilidade(Elegibilidade.REVER);
    aprovacao = NivelAprovacao.DISTRICT_AREA;
    terminar();
  }

  /**
   * Termina o fluxo do pedido quando todos os artigos pararam numa paragem obrigatória: não resta
   * nada a decidir para a transação (ADR 0004). A elegibilidade do pedido é agregada em OUT-001.
   */
  public void terminarPorParagemDosArtigos() {
    terminar();
  }

  /**
   * Recusa o pedido de exceção do cliente (HS-005, EX-006). O registo fica com o resultado RECUSAR,
   * mas a elegibilidade do pedido não muda: a transação continua pelo processo obrigatório.
   */
  public void recusarExcecao(String regra, Modulo modulo, String mensagem) {
    registar(regra, modulo, Elegibilidade.RECUSAR, mensagem);
    excecaoRecusada = true;
  }

  /**
   * Agrega os resultados por artigo no pedido (ADR 0002): a elegibilidade do pedido passa a ser a
   * mais severa entre a do pedido e as dos artigos; se todos os artigos forem recusados, não há
   * transação. Os artigos sem resultado não contam.
   */
  public void agregarArtigos(String regra, Modulo modulo, List<DecisaoArtigo> artigos) {
    resultadosArtigos = new ArrayList<>(artigos);
    resultadosArtigos.sort(Comparator.comparing(DecisaoArtigo::getArtigoId));

    Elegibilidade pior = null;
    long permitidos = 0;
    long recusados = 0;
    long emRevisao = 0;
    for (DecisaoArtigo artigo : resultadosArtigos) {
      Elegibilidade resultado = artigo.getElegibilidade();
      if (resultado == null) {
        continue;
      }
      if (resultado.maisSeveroQue(pior)) {
        pior = resultado;
      }
      permitidos += resultado == Elegibilidade.PERMITIR ? 1 : 0;
      recusados += resultado == Elegibilidade.RECUSAR ? 1 : 0;
      emRevisao += resultado == Elegibilidade.REVER ? 1 : 0;
    }
    if (pior != null && pior.maisSeveroQue(getElegibilidade())) {
      definirElegibilidade(pior);
    }
    if (!resultadosArtigos.isEmpty() && recusados == resultadosArtigos.size()) {
      tipoTransacao = TipoTransacao.NENHUMA;
    }
    registar(
        regra,
        modulo,
        getElegibilidade(),
        resultadosArtigos.size()
            + " artigo(s): "
            + permitidos
            + " permitido(s), "
            + emRevisao
            + " em revisão, "
            + recusados
            + " recusado(s). Elegibilidade do pedido: "
            + getElegibilidade()
            + ".");
  }

  public boolean isExcecaoRecusada() {
    return excecaoRecusada;
  }

  public void setExcecaoRecusada(boolean excecaoRecusada) {
    this.excecaoRecusada = excecaoRecusada;
  }

  public String getPedidoId() {
    return pedidoId;
  }

  public void setPedidoId(String pedidoId) {
    this.pedidoId = pedidoId;
  }

  public TipoVerificacao getTipoVerificacao() {
    return tipoVerificacao;
  }

  public void setTipoVerificacao(TipoVerificacao tipoVerificacao) {
    this.tipoVerificacao = tipoVerificacao;
  }

  public TipoTransacao getTipoTransacao() {
    return tipoTransacao;
  }

  public void setTipoTransacao(TipoTransacao tipoTransacao) {
    this.tipoTransacao = tipoTransacao;
  }

  public BigDecimal getValorDevolucao() {
    return valorDevolucao;
  }

  public void setValorDevolucao(BigDecimal valorDevolucao) {
    this.valorDevolucao = valorDevolucao;
  }

  public BaseValor getBaseValor() {
    return baseValor;
  }

  public void setBaseValor(BaseValor baseValor) {
    this.baseValor = baseValor;
  }

  public MeioReembolso getMeioReembolso() {
    return meioReembolso;
  }

  public void setMeioReembolso(MeioReembolso meioReembolso) {
    this.meioReembolso = meioReembolso;
  }

  /** Exige pelo menos o nível de aprovação indicado; a aprovação nunca desce (docs/08 §5.3). */
  public void exigirAprovacao(NivelAprovacao nivel) {
    if (aprovacao == null || nivel.compareTo(aprovacao) > 0) {
      aprovacao = nivel;
    }
  }

  public NivelAprovacao getAprovacao() {
    return aprovacao;
  }

  public void setAprovacao(NivelAprovacao aprovacao) {
    this.aprovacao = aprovacao;
  }

  public ProcessoObrigatorio getProcesso() {
    return processo;
  }

  public void setProcesso(ProcessoObrigatorio processo) {
    this.processo = processo;
  }

  public Documentacao getDocumentacao() {
    return documentacao;
  }

  public void setDocumentacao(Documentacao documentacao) {
    this.documentacao = documentacao;
  }

  public List<DecisaoArtigo> getResultadosArtigos() {
    return resultadosArtigos;
  }

  public void setResultadosArtigos(List<DecisaoArtigo> resultadosArtigos) {
    this.resultadosArtigos = resultadosArtigos;
  }

  /** Acrescenta um grau calculado pela camada de incerteza e guarda a versão dos parâmetros. */
  public void acrescentarGrau(GrauCrenca grau) {
    grausCrenca.add(grau);
    versaoParametrosIncerteza = grau.getVersaoParametros();
  }

  public List<GrauCrenca> getGrausCrenca() {
    return grausCrenca;
  }

  public void setGrausCrenca(List<GrauCrenca> grausCrenca) {
    this.grausCrenca = grausCrenca;
  }

  public String getVersaoParametrosIncerteza() {
    return versaoParametrosIncerteza;
  }

  public void setVersaoParametrosIncerteza(String versaoParametrosIncerteza) {
    this.versaoParametrosIncerteza = versaoParametrosIncerteza;
  }
}
