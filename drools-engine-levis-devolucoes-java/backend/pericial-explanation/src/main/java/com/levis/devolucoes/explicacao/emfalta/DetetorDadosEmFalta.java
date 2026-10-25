package com.levis.devolucoes.explicacao.emfalta;

import com.levis.devolucoes.incerteza.FabricaEvidencias;
import com.levis.devolucoes.model.enums.CategoriaProduto;
import com.levis.devolucoes.model.enums.CondicaoUso;
import com.levis.devolucoes.model.enums.EstadoEtiquetas;
import com.levis.devolucoes.model.pedido.CompraOriginal;
import com.levis.devolucoes.model.pedido.PedidoDevolucao;
import com.levis.devolucoes.model.produto.ArtigoDevolvido;
import com.levis.devolucoes.model.produto.EstadoProduto;
import com.levis.devolucoes.model.produto.Produto;
import java.util.ArrayList;
import java.util.List;

/**
 * "O que falta?": antes da avaliação, lista os dados de entrada (IN-001 a IN-010) em falta para se
 * poder decidir. Os dados opcionais por natureza (comprovativo nas devoluções às cegas, data da
 * compra sem comprovativo, A-16) não são pedidos.
 */
public class DetetorDadosEmFalta {

  public List<DadoEmFalta> detetar(PedidoDevolucao pedido) {
    List<DadoEmFalta> emFalta = new ArrayList<>();

    if (pedido.getColaborador() == null || pedido.getColaborador().getFuncao() == null) {
      emFalta.add(
          new DadoEmFalta(
              "HS-006", "colaborador.funcao", "Função do colaborador que processa", true));
    }
    if (pedido.getLoja() == null || pedido.getLoja().getMercado() == null) {
      emFalta.add(
          new DadoEmFalta("IN-001", "loja.mercado", "Mercado (Estados Unidos ou Canadá)", true));
    }
    if (pedido.getLoja() == null || pedido.getLoja().getTipoLoja() == null) {
      emFalta.add(
          new DadoEmFalta("IN-002", "loja.tipoLoja", "Tipo de loja (Mainline ou Outlet)", true));
    }
    CompraOriginal compra = pedido.getCompraOriginal();
    if (compra == null || compra.getCanal() == null) {
      emFalta.add(
          new DadoEmFalta(
              "IN-003", "compraOriginal.canal", "Canal de compra (ou \"desconhecido\")", true));
    }
    if (pedido.getComprovativo() != null && pedido.getComprovativo().getTipo() == null) {
      emFalta.add(
          new DadoEmFalta("IN-004", "comprovativo.tipo", "Tipo de comprovativo apresentado", true));
    }
    if (pedido.getTipoPedido() == null) {
      emFalta.add(
          new DadoEmFalta(
              "IN-005",
              "tipoPedido",
              "Pedido do cliente (devolução, troca, oferta ou ajuste)",
              true));
    }
    detetarMomento(pedido, compra, emFalta);
    detetarPagamento(pedido, compra, emFalta);

    for (int i = 0; i < pedido.getArtigos().size(); i++) {
      detetarArtigo(pedido, pedido.getArtigos().get(i), "artigos[" + i + "].", emFalta);
    }
    if (pedido.getArtigos().isEmpty()) {
      emFalta.add(new DadoEmFalta("IN-007", "artigos", "Pelo menos um artigo devolvido", true));
    }
    return emFalta;
  }

  private static void detetarMomento(
      PedidoDevolucao pedido, CompraOriginal compra, List<DadoEmFalta> emFalta) {
    if (pedido.getDataPedido() == null) {
      emFalta.add(new DadoEmFalta("IN-006", "dataPedido", "Data do pedido", true));
    }
    if (compra == null) {
      return;
    }
    if (pedido.isCompraOnline()) {
      if (compra.getDataEnvio() == null) {
        emFalta.add(
            new DadoEmFalta(
                "IN-006", "compraOriginal.dataEnvio", "Data de envio da encomenda online", true));
      }
    } else if (pedido.getComprovativo() != null && compra.getDataCompra() == null) {
      emFalta.add(
          new DadoEmFalta(
              "IN-006",
              "compraOriginal.dataCompra",
              "Data da compra indicada no comprovativo",
              true));
    }
  }

  private static void detetarPagamento(
      PedidoDevolucao pedido, CompraOriginal compra, List<DadoEmFalta> emFalta) {
    boolean verificavel = pedido.getComprovativo() != null || pedido.isCompraOnline();
    if (!verificavel || compra == null) {
      return;
    }
    if (compra.getPagamento() == null || compra.getPagamento().getMeio() == null) {
      emFalta.add(
          new DadoEmFalta(
              "IN-009", "compraOriginal.pagamento.meio", "Meio de pagamento original", true));
    }
  }

  private static void detetarArtigo(
      PedidoDevolucao pedido, ArtigoDevolvido artigo, String prefixo, List<DadoEmFalta> emFalta) {
    Produto produto = artigo.getProduto();
    if (produto == null) {
      emFalta.add(
          new DadoEmFalta(
              "IN-007", prefixo + "produto", "Produto do artigo " + artigo.getId(), true));
    } else {
      if (produto.getSku() == null) {
        emFalta.add(
            new DadoEmFalta(
                "IN-007", prefixo + "produto.sku", "SKU do artigo " + artigo.getId(), true));
      }
      if (produto.getMarca() == null) {
        emFalta.add(
            new DadoEmFalta(
                "IN-007", prefixo + "produto.marca", "Marca do artigo " + artigo.getId(), true));
      }
      if (produto.getCategoria() == null) {
        emFalta.add(
            new DadoEmFalta(
                "IN-007",
                prefixo + "produto.categoria",
                "Categoria do artigo " + artigo.getId(),
                true));
      }
    }
    EstadoProduto estado = artigo.getEstado();
    if (estado == null || estado.getCondicaoUso() == null) {
      emFalta.add(
          new DadoEmFalta(
              "IN-008",
              prefixo + "estado.condicaoUso",
              "Estado de uso do artigo " + artigo.getId(),
              true));
      return;
    }
    boolean bodywear = produto != null && produto.getCategoria() == CategoriaProduto.BODYWEAR;
    if (!bodywear
        && estado.getCondicaoUso() == CondicaoUso.NAO_USADO
        && estado.getEtiquetas() == null) {
      emFalta.add(
          new DadoEmFalta(
              "IN-008",
              prefixo + "estado.etiquetas",
              "Estado das etiquetas do artigo " + artigo.getId(),
              true));
    }
    if (artigo.getRevendivel() == null && precisaDeAvaliarRevenda(pedido, artigo, bodywear)) {
      emFalta.add(
          new DadoEmFalta(
              "IN-010",
              prefixo + "revendivel",
              "Possibilidade de verificar, reetiquetar e revender o artigo " + artigo.getId(),
              false));
      if (!bodywear && estado.getGrauUso() == null) {
        // Com o grau de uso, a camada de incerteza recomenda à gestão (docs/08 §4.1)
        emFalta.add(
            new DadoEmFalta(
                "IN-008",
                prefixo + "estado.grauUso",
                "Grau de uso do artigo " + artigo.getId() + " (ajuda a avaliar a revenda)",
                false));
      }
    }
    if (estado.isAlegaDefeito() && !estado.isDefeitoFabricoConfirmado() && !bodywear) {
      // Perguntas da inspeção do defeito por responder (Sim, Não ou Não sei; docs/08 §3.3)
      FabricaEvidencias.INSPECAO_COLABORADOR.stream()
          .sorted()
          .filter(codigo -> !estado.getInspecaoDefeito().containsKey(codigo))
          .forEach(
              codigo ->
                  emFalta.add(
                      new DadoEmFalta(
                          "IN-008",
                          prefixo + "estado.inspecaoDefeito." + codigo,
                          "Inspeção do defeito do artigo " + artigo.getId() + " (" + codigo + ")",
                          false)));
    }
  }

  /** IN-010 é necessário para resolver PC-002, PC-003, PT-004 e BW-001. */
  private static boolean precisaDeAvaliarRevenda(
      PedidoDevolucao pedido, ArtigoDevolvido artigo, boolean bodywear) {
    EstadoProduto estado = artigo.getEstado();
    boolean naoUsado = estado.getCondicaoUso() == CondicaoUso.NAO_USADO;
    boolean semEtiquetasColocadas =
        estado.getEtiquetas() == EstadoEtiquetas.SOLTAS
            || estado.getEtiquetas() == EstadoEtiquetas.AUSENTES;
    if (!bodywear && naoUsado && semEtiquetasColocadas && !estado.isDefeitoFabricoConfirmado()) {
      return true;
    }
    if (bodywear && naoUsado && estado.isEmbalagemIntacta() && estado.isConjuntoCompleto()) {
      return true;
    }
    Long dias = pedido.getDiasDesdeCompra();
    return pedido.getComprovativo() != null
        && !pedido.isCompraOnline()
        && dias != null
        && dias > 30;
  }

  /** Só os dados obrigatórios. */
  public List<DadoEmFalta> obrigatorios(PedidoDevolucao pedido) {
    return detetar(pedido).stream().filter(DadoEmFalta::obrigatorio).toList();
  }
}
