package com.levis.devolucoes.dto.pedido;

import com.levis.devolucoes.dto.enums.CategoriaProduto;
import com.levis.devolucoes.dto.enums.Marca;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.PositiveOrZero;
import java.math.BigDecimal;

/**
 * Produto (IN-007). Só o SKU é obrigatório: os campos vazios são consultados no POS e no catálogo e
 * nunca sobrepõem o que o colaborador indicou.
 *
 * @param defeitoConhecido defeito de fabrico conhecido para o SKU (ED-04, docs/08); consultado no
 *     catálogo se vazio
 */
public record ProdutoRequest(
    @NotBlank String sku,
    Boolean skuReconhecidoPOS,
    Marca marca,
    CategoriaProduto categoria,
    Boolean grossista,
    Boolean vendidoNaLoja,
    Boolean produtoFranquia,
    @PositiveOrZero BigDecimal pvpOriginal,
    @PositiveOrZero BigDecimal precoAtual,
    Boolean emSaldo,
    Boolean defeitoConhecido) {}
