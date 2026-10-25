package com.levis.devolucoes.explicacao.porque;

import static com.levis.devolucoes.explicacao.porque.DadoEntrada.CANAL;
import static com.levis.devolucoes.explicacao.porque.DadoEntrada.CLIENTE;
import static com.levis.devolucoes.explicacao.porque.DadoEntrada.COLABORADOR;
import static com.levis.devolucoes.explicacao.porque.DadoEntrada.COMPROVATIVO;
import static com.levis.devolucoes.explicacao.porque.DadoEntrada.ESTADO;
import static com.levis.devolucoes.explicacao.porque.DadoEntrada.EXCECAO;
import static com.levis.devolucoes.explicacao.porque.DadoEntrada.FRAUDE;
import static com.levis.devolucoes.explicacao.porque.DadoEntrada.MERCADO;
import static com.levis.devolucoes.explicacao.porque.DadoEntrada.MOMENTO;
import static com.levis.devolucoes.explicacao.porque.DadoEntrada.ONLINE;
import static com.levis.devolucoes.explicacao.porque.DadoEntrada.PAGAMENTO;
import static com.levis.devolucoes.explicacao.porque.DadoEntrada.PEDIDO;
import static com.levis.devolucoes.explicacao.porque.DadoEntrada.PRODUTO;
import static com.levis.devolucoes.explicacao.porque.DadoEntrada.REVENDA;
import static com.levis.devolucoes.explicacao.porque.DadoEntrada.TIPO_LOJA;

import java.util.Collections;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

/**
 * Dados de entrada que cada condição lê. Permite responder "Porquê esta pergunta?": as regras cujas
 * condições leem o dado perguntado dependem da resposta.
 */
public final class DependenciasDados {

  private final Map<String, Set<DadoEntrada>> porCondicao = new HashMap<>();

  public DependenciasDados() {
    le(
        CANAL,
        "canalGrossista",
        "canalFranquiaCanada",
        "canalLoja",
        "canalDesconhecido",
        "compraMainlineOuOutlet",
        "compraEmLoja",
        "compraForaDaLoja",
        "compraBackPocket",
        "compraOnline",
        "compraNaoOnline",
        "origemMainlineOuOnline",
        "entreCanais",
        "promocaoEscaloes",
        "stylistDaVendaConhecido",
        "semAjusteAnterior",
        "ajusteAnterior");
    le(TIPO_LOJA, "lojaOutlet");
    le(MERCADO, "mercadoCanada");
    le(
        COMPROVATIVO,
        "comprovativoValido",
        "comprovativoConfirmaCompra",
        "semComprovativoValido",
        "reciboOriginal",
        "reciboOriginalImpresso",
        "mais14DiasOuSemReciboOriginal");
    le(
        ONLINE,
        "encomendaEncontrada",
        "encomendaNaoEncontrada",
        "portalDisponivel",
        "portalIndisponivel",
        "politicaPermiteAsCegasOnline",
        "politicaNaoPermiteAsCegasOnline",
        "devolucaoAsCegasOnlinePermitida");
    le(
        PEDIDO,
        "ajustePreco",
        "naoEAjustePreco",
        "devolucaoOferta",
        "naoEOferta",
        "pedidoTroca",
        "apenasMudaTamanho",
        "mudaModeloOuCor",
        "pedidoDeExcecaoAoMeio");
    le(
        MOMENTO,
        "ate30DiasDesdeCompra",
        "mais30DiasDesdeCompra",
        "ate14DiasDesdeCompra",
        "ate30DiasDesdeEnvio",
        "mais30DiasDesdeEnvio",
        "mais14DiasOuSemReciboOriginal");
    le(
        PRODUTO,
        "skuReconhecido",
        "skuNaoReconhecido",
        "produtoFranquia",
        "produtoNaoFranquia",
        "marcaExcluidaOuGrossistaNaoVendido",
        "bodywear",
        "naoBodywear",
        "emSaldo",
        "naoEmSaldo",
        "noSortidoDaLojaRecetora",
        "foraDoSortidoDaLojaRecetora",
        "bodywearAceite");
    le(
        ESTADO,
        "produtoModificado",
        "naoModificado",
        "naoUsado",
        "usado",
        "lavado",
        "etiquetasColocadas",
        "etiquetasSoltas",
        "etiquetasAusentes",
        "defeitoFabricoConfirmado",
        "semDefeito",
        "sujoOuInseguro",
        "artigoSujoOuInseguro",
        "embalagemIntacta",
        "semEmbalagem",
        "conjuntoCompleto",
        "conjuntoIncompletoOuUsado",
        "defeitoFabricoAceite");
    le(
        REVENDA,
        "revendivel",
        "naoRevendivel",
        "revendivelPorAvaliar",
        "artigoRevendivel",
        "artigoNaoRevendivel",
        "artigoRevendivelPorAvaliar");
    le(
        PAGAMENTO,
        "pagamentoAfterpay",
        "naoAfterpay",
        "pagamentoCreditoOuDebito",
        "pagamentoDebito",
        "pagamentoContactless",
        "pagamentoComCartao",
        "pagamentoPaypalOuVenmo",
        "pagamentoInterac",
        "pagamentoNumerarioOuCartaoOferta",
        "pagamentoSemProcessoProprio",
        "acessoAplicacao",
        "semAcessoAplicacao",
        "cartaoFisicoPresente",
        "cartaoFisicoAusente",
        "contaAtivaCartaoPerdido",
        "contaEncerrada",
        "reembolsoOriginalRecusado",
        "reembolsoOriginalNaoRecusado");
    le(
        COLABORADOR,
        "colaboradorAutorizado",
        "colaboradorNaoAutorizado",
        "credencialPosPropria",
        "processadorLeadCashierOuElevatedStylist");
    le(CLIENTE, "clienteContesta", "clienteAgitado", "clienteNaoForneceDadosOuBarreiraLinguistica");
    le(FRAUDE, "indicioFraudeRelevante", "baixoRisco", "pedidoNaoSuspenso");
    // Camada de incerteza (docs/08): respostas que alimentam as evidências EF e ED
    le(FRAUDE, "pedeNumerario", "semIndicioFraudeRelevante");
    le(COMPROVATIVO, "semComprovativoQueConfirme");
    le(ESTADO, "todosOsArtigosSemEtiquetas", "alegaDefeito", "grauUsoConhecido");
    le(MOMENTO, "dataCompraConhecida");
    le(
        EXCECAO,
        "pedidoExcecao",
        "aprovacaoGestaoPendente",
        "aprovadoPelaGestao",
        "recusadoPelaGestao",
        "excecaoAprovada",
        "concluivelNoSistema",
        "exigeControloObrigatorio",
        "pedidoDeExcecaoAoMeio");
  }

  private void le(DadoEntrada dado, String... condicoes) {
    for (String condicao : condicoes) {
      porCondicao.computeIfAbsent(condicao, c -> EnumSet.noneOf(DadoEntrada.class)).add(dado);
    }
  }

  /** Dados que a condição lê; vazio para condições sobre o resultado de outras regras. */
  public Set<DadoEntrada> dados(String condicao) {
    return Collections.unmodifiableSet(
        porCondicao.getOrDefault(condicao, EnumSet.noneOf(DadoEntrada.class)));
  }

  public boolean le(String condicao, DadoEntrada dado) {
    return dados(condicao).contains(dado);
  }

  public Set<String> condicoes() {
    return Collections.unmodifiableSet(porCondicao.keySet());
  }
}
