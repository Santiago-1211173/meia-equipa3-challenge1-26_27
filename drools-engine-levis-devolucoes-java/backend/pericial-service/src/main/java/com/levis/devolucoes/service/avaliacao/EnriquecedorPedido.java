package com.levis.devolucoes.service.avaliacao;

import com.levis.devolucoes.dto.enums.CanalCompra;
import com.levis.devolucoes.dto.pedido.ArtigoRequest;
import com.levis.devolucoes.dto.pedido.ArtigoTrocaRequest;
import com.levis.devolucoes.dto.pedido.CompraRequest;
import com.levis.devolucoes.dto.pedido.PagamentoRequest;
import com.levis.devolucoes.dto.pedido.PedidoAvaliacaoRequest;
import com.levis.devolucoes.dto.pedido.ProdutoRequest;
import com.levis.devolucoes.service.integracao.porta.BackPocketGateway;
import com.levis.devolucoes.service.integracao.porta.CatalogoProdutoGateway;
import com.levis.devolucoes.service.integracao.porta.CatalogoProdutoGateway.ProdutoCatalogo;
import com.levis.devolucoes.service.integracao.porta.PagamentoGateway;
import com.levis.devolucoes.service.integracao.porta.PosGateway;
import java.util.List;
import java.util.Optional;
import org.springframework.stereotype.Component;

/**
 * Completa o pedido com as integrações (POS, catálogo, BackPocket, pagamentos). Só preenche campos
 * vazios: nunca sobrepõe o que o colaborador indicou.
 */
@Component
public class EnriquecedorPedido {

  private final PosGateway pos;
  private final CatalogoProdutoGateway catalogo;
  private final BackPocketGateway backPocket;
  private final PagamentoGateway pagamentos;

  public EnriquecedorPedido(
      PosGateway pos,
      CatalogoProdutoGateway catalogo,
      BackPocketGateway backPocket,
      PagamentoGateway pagamentos) {
    this.pos = pos;
    this.catalogo = catalogo;
    this.backPocket = backPocket;
    this.pagamentos = pagamentos;
  }

  public PedidoAvaliacaoRequest enriquecer(PedidoAvaliacaoRequest r) {
    List<ArtigoRequest> artigos =
        r.artigos() == null ? List.of() : r.artigos().stream().map(this::artigo).toList();
    List<ArtigoTrocaRequest> trocas =
        r.artigosTroca() == null ? List.of() : r.artigosTroca().stream().map(this::troca).toList();
    Boolean portal =
        r.portalOnlineDisponivel() != null
            ? r.portalOnlineDisponivel()
            : backPocket.portalDisponivel();
    return new PedidoAvaliacaoRequest(
        r.id(),
        r.dataPedido(),
        r.tipoPedido(),
        r.loja(),
        r.cliente(),
        compra(r.compraOriginal()),
        r.comprovativo(),
        artigos,
        trocas,
        portal,
        r.politicaPermiteAsCegasOnline(),
        r.pedidoExcecao(),
        r.indicadoresFraude());
  }

  private ArtigoRequest artigo(ArtigoRequest a) {
    ProdutoRequest produto = produto(a.produto(), true);
    return new ArtigoRequest(
        a.id(),
        produto,
        a.quantidade(),
        a.precoPago(),
        a.estado(),
        a.entreCanais(),
        a.revendivel(),
        a.valorCalculadoPos());
  }

  private ArtigoTrocaRequest troca(ArtigoTrocaRequest t) {
    return new ArtigoTrocaRequest(
        produto(t.produto(), false), t.apenasMudaTamanho(), t.precoVenda());
  }

  private ProdutoRequest produto(ProdutoRequest p, boolean consultarPos) {
    if (p == null) {
      return null;
    }
    boolean temSku = p.sku() != null && !p.sku().isBlank();
    Optional<ProdutoCatalogo> c = temSku ? catalogo.produto(p.sku()) : Optional.empty();
    Boolean reconhecido = p.skuReconhecidoPOS();
    if (reconhecido == null && consultarPos && temSku) {
      reconhecido = pos.skuReconhecido(p.sku());
    }
    return new ProdutoRequest(
        p.sku(),
        reconhecido,
        p.marca() != null ? p.marca() : c.map(ProdutoCatalogo::marca).orElse(null),
        p.categoria() != null ? p.categoria() : c.map(ProdutoCatalogo::categoria).orElse(null),
        p.grossista() != null ? p.grossista() : c.map(ProdutoCatalogo::grossista).orElse(null),
        p.vendidoNaLoja() != null
            ? p.vendidoNaLoja()
            : c.map(ProdutoCatalogo::vendidoNaLoja).orElse(null),
        p.produtoFranquia() != null
            ? p.produtoFranquia()
            : c.map(ProdutoCatalogo::produtoFranquia).orElse(null),
        p.pvpOriginal() != null
            ? p.pvpOriginal()
            : c.map(ProdutoCatalogo::pvpOriginal).orElse(null),
        p.precoAtual() != null ? p.precoAtual() : c.map(ProdutoCatalogo::precoAtual).orElse(null),
        p.emSaldo() != null ? p.emSaldo() : c.map(ProdutoCatalogo::emSaldo).orElse(null),
        p.defeitoConhecido() != null
            ? p.defeitoConhecido()
            : c.map(ProdutoCatalogo::defeitoConhecido).orElse(null));
  }

  private CompraRequest compra(CompraRequest c) {
    if (c == null) {
      return null;
    }
    boolean online = c.canal() == CanalCompra.LEVI_COM || c.canal() == CanalCompra.LEVI_CA;
    Boolean encontrada =
        c.encomendaEncontrada() != null || !online
            ? c.encomendaEncontrada()
            : backPocket.encomendaEncontrada(c.idTransacao()).orElse(null);
    return new CompraRequest(
        c.idTransacao(),
        c.canal(),
        c.dataCompra(),
        c.dataEnvio(),
        pagamento(c.pagamento(), c.idTransacao()),
        c.idStylistVenda(),
        c.quantidadeComprada(),
        c.promocaoEscaloes(),
        encontrada,
        c.ajustePrecoAplicado(),
        c.compraOferta());
  }

  private PagamentoRequest pagamento(PagamentoRequest p, String idTransacao) {
    if (p == null || p.estadoConta() != null) {
      return p;
    }
    return new PagamentoRequest(
        p.meio(),
        p.valorPago(),
        pagamentos.estadoConta(idTransacao).orElse(null),
        p.cartaoFisicoPresente(),
        p.reembolsoOriginalRecusado(),
        p.acessoAplicacaoPagamento());
  }
}
