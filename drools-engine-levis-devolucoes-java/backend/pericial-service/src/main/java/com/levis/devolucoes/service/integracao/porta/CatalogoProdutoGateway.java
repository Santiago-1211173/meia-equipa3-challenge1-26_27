package com.levis.devolucoes.service.integracao.porta;

import com.levis.devolucoes.dto.enums.CategoriaProduto;
import com.levis.devolucoes.dto.enums.Marca;
import java.math.BigDecimal;
import java.util.Optional;

/** Catálogo de produtos (IN-007): marca, categoria, canal, preços e saldo. */
public interface CatalogoProdutoGateway {

  Optional<ProdutoCatalogo> produto(String sku);

  /** Dados de catálogo de um SKU. */
  record ProdutoCatalogo(
      String sku,
      Marca marca,
      CategoriaProduto categoria,
      boolean grossista,
      boolean vendidoNaLoja,
      boolean produtoFranquia,
      BigDecimal pvpOriginal,
      BigDecimal precoAtual,
      boolean emSaldo,
      boolean defeitoConhecido) {}
}
