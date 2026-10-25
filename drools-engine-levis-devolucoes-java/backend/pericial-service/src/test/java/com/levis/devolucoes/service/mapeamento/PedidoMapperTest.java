package com.levis.devolucoes.service.mapeamento;

import static org.assertj.core.api.Assertions.assertThat;

import com.levis.devolucoes.dto.enums.CanalCompra;
import com.levis.devolucoes.dto.enums.NivelRisco;
import com.levis.devolucoes.dto.pedido.ArtigoRequest;
import com.levis.devolucoes.dto.pedido.ClienteRequest;
import com.levis.devolucoes.dto.pedido.CompraRequest;
import com.levis.devolucoes.dto.pedido.EstadoProdutoRequest;
import com.levis.devolucoes.dto.pedido.IndicadorFraudeRequest;
import com.levis.devolucoes.dto.pedido.PagamentoRequest;
import com.levis.devolucoes.dto.pedido.PedidoAvaliacaoRequest;
import com.levis.devolucoes.dto.pedido.PedidoExcecaoRequest;
import com.levis.devolucoes.dto.pedido.ProdutoRequest;
import com.levis.devolucoes.model.decisao.IndicadorFraude;
import com.levis.devolucoes.model.enums.MeioPagamento;
import com.levis.devolucoes.model.pedido.PedidoDevolucao;
import com.levis.devolucoes.model.produto.ArtigoDevolvido;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.mapstruct.factory.Mappers;

/** Valores por omissão do modelo para os campos opcionais vazios do pedido da API. */
class PedidoMapperTest {

  private final PedidoMapper mapper = Mappers.getMapper(PedidoMapper.class);

  @Test
  void camposVaziosRecebemOsValoresPorOmissaoDoModelo() {
    PedidoAvaliacaoRequest pedido =
        new PedidoAvaliacaoRequest(
            "P-1",
            null,
            null,
            null,
            new ClienteRequest(null, null, false, false, false, null, false),
            new CompraRequest(
                "T-1",
                CanalCompra.MAINLINE,
                null,
                null,
                new PagamentoRequest(
                    com.levis.devolucoes.dto.enums.MeioPagamento.PAYPAL,
                    null,
                    null,
                    false,
                    false,
                    null),
                null,
                1,
                false,
                null,
                false,
                false),
            null,
            List.of(
                new ArtigoRequest(
                    "A-1",
                    new ProdutoRequest(
                        "501", null, null, null, null, null, null, null, null, null, null),
                    null,
                    null,
                    new EstadoProdutoRequest(
                        null, null, false, false, false, false, false, false, null, null, false,
                        null, null, false, null),
                    false,
                    null,
                    null)),
            null,
            null,
            null,
            new PedidoExcecaoRequest(
                "motivo", null, false, false, false, false, null, null, null, null),
            null);

    PedidoDevolucao factos = mapper.paraModelo(pedido);

    assertThat(factos.isPortalOnlineDisponivel()).isTrue();
    assertThat(factos.isPoliticaPermiteAsCegasOnline()).isFalse();
    assertThat(factos.getCliente().isForneceDados()).isTrue();
    assertThat(factos.getCompraOriginal().getPagamento().getMeio()).isEqualTo(MeioPagamento.PAYPAL);
    assertThat(factos.getCompraOriginal().getPagamento().isAcessoAplicacaoPagamento()).isTrue();
    assertThat(factos.getPedidoExcecao().isConcluivelNoSistema()).isTrue();
    assertThat(factos.getPedidoExcecao().getAprovada()).isNull();
    assertThat(factos.getArtigosTroca()).isEmpty();
    ArtigoDevolvido artigo = factos.getArtigos().getFirst();
    assertThat(artigo.getQuantidade()).isEqualTo(1);
    assertThat(artigo.getRevendivel()).isNull();
    assertThat(artigo.getEstado().isEtiquetaPrecoCorreta()).isTrue();
    assertThat(artigo.getEstado().isRfidCorreto()).isTrue();
    assertThat(artigo.getEstado().isConjuntoCompleto()).isTrue();
    assertThat(artigo.getProduto().isSkuReconhecidoPOS()).isFalse();
    assertThat(factos.getColaborador()).isNull();
  }

  @Test
  void indicioDeFraudeFicaLigadoAoPedido() {
    IndicadorFraude fraude =
        mapper.fraude(
            new IndicadorFraudeRequest("Recibo adulterado", NivelRisco.CONFIRMADO), "P-9");

    assertThat(fraude.getPedidoId()).isEqualTo("P-9");
    assertThat(fraude.getNivelRisco())
        .isEqualTo(com.levis.devolucoes.model.enums.NivelRisco.CONFIRMADO);
  }
}
