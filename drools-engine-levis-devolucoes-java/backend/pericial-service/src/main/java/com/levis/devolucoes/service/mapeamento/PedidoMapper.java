package com.levis.devolucoes.service.mapeamento;

import com.levis.devolucoes.dto.comum.ColaboradorDto;
import com.levis.devolucoes.dto.enums.Resposta;
import com.levis.devolucoes.dto.pedido.ArtigoRequest;
import com.levis.devolucoes.dto.pedido.ArtigoTrocaRequest;
import com.levis.devolucoes.dto.pedido.ClienteRequest;
import com.levis.devolucoes.dto.pedido.CompraRequest;
import com.levis.devolucoes.dto.pedido.ComprovativoRequest;
import com.levis.devolucoes.dto.pedido.EstadoProdutoRequest;
import com.levis.devolucoes.dto.pedido.IndicadorFraudeRequest;
import com.levis.devolucoes.dto.pedido.LojaRequest;
import com.levis.devolucoes.dto.pedido.PagamentoRequest;
import com.levis.devolucoes.dto.pedido.PedidoAvaliacaoRequest;
import com.levis.devolucoes.dto.pedido.PedidoExcecaoRequest;
import com.levis.devolucoes.dto.pedido.ProdutoRequest;
import com.levis.devolucoes.model.decisao.IndicadorFraude;
import com.levis.devolucoes.model.pedido.Cliente;
import com.levis.devolucoes.model.pedido.Colaborador;
import com.levis.devolucoes.model.pedido.CompraOriginal;
import com.levis.devolucoes.model.pedido.Comprovativo;
import com.levis.devolucoes.model.pedido.Loja;
import com.levis.devolucoes.model.pedido.Pagamento;
import com.levis.devolucoes.model.pedido.PedidoDevolucao;
import com.levis.devolucoes.model.pedido.PedidoExcecao;
import com.levis.devolucoes.model.produto.ArtigoDevolvido;
import com.levis.devolucoes.model.produto.ArtigoTroca;
import com.levis.devolucoes.model.produto.EstadoProduto;
import com.levis.devolucoes.model.produto.Produto;
import java.util.LinkedHashMap;
import java.util.Map;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.NullValueMappingStrategy;

/**
 * Pedido da API (DTO) para os factos do modelo. Os campos opcionais vazios recebem os valores por
 * omissão do modelo (ex.: etiqueta de preço e RFID corretos, conjunto completo, portal disponível).
 * O colaborador é o utilizador autenticado e é definido à parte (A-24).
 */
@Mapper(nullValueIterableMappingStrategy = NullValueMappingStrategy.RETURN_DEFAULT)
public interface PedidoMapper {

  @Mapping(target = "colaborador", ignore = true)
  @Mapping(target = "suspenso", ignore = true)
  @Mapping(target = "moduloAtual", ignore = true)
  @Mapping(target = "portalOnlineDisponivel", defaultValue = "true")
  @Mapping(target = "politicaPermiteAsCegasOnline", defaultValue = "false")
  PedidoDevolucao paraModelo(PedidoAvaliacaoRequest pedido);

  Loja loja(LojaRequest loja);

  @Mapping(target = "forneceDados", defaultValue = "true")
  Cliente cliente(ClienteRequest cliente);

  @Mapping(target = "encomendaEncontrada", defaultValue = "false")
  CompraOriginal compra(CompraRequest compra);

  @Mapping(target = "acessoAplicacaoPagamento", defaultValue = "true")
  Pagamento pagamento(PagamentoRequest pagamento);

  Comprovativo comprovativo(ComprovativoRequest comprovativo);

  @Mapping(target = "quantidade", defaultValue = "1")
  @Mapping(target = "destino", ignore = true)
  @Mapping(target = "descontoSaldo", ignore = true)
  ArtigoDevolvido artigo(ArtigoRequest artigo);

  @Mapping(target = "skuReconhecidoPOS", defaultValue = "false")
  @Mapping(target = "grossista", defaultValue = "false")
  @Mapping(target = "vendidoNaLoja", defaultValue = "false")
  @Mapping(target = "produtoFranquia", defaultValue = "false")
  @Mapping(target = "emSaldo", defaultValue = "false")
  @Mapping(target = "defeitoConhecido", defaultValue = "false")
  Produto produto(ProdutoRequest produto);

  @Mapping(target = "etiquetaPrecoCorreta", defaultValue = "true")
  @Mapping(target = "rfidCorreto", defaultValue = "true")
  @Mapping(target = "conjuntoCompleto", defaultValue = "true")
  EstadoProduto estado(EstadoProdutoRequest estado);

  ArtigoTroca troca(ArtigoTrocaRequest troca);

  @Mapping(target = "concluivelNoSistema", defaultValue = "true")
  PedidoExcecao excecao(PedidoExcecaoRequest excecao);

  Colaborador colaborador(ColaboradorDto colaborador);

  @Mapping(target = "pedidoId", source = "pedidoId")
  @Mapping(target = "comunicadoGSS", ignore = true)
  IndicadorFraude fraude(IndicadorFraudeRequest indicador, String pedidoId);

  /** Resposta do colaborador (docs/08): SIM = presente, NAO = ausente, NAO_SEI = desconhecida. */
  default Boolean resposta(Resposta resposta) {
    if (resposta == null || resposta == Resposta.NAO_SEI) {
      return null;
    }
    return resposta == Resposta.SIM;
  }

  /** Respostas da inspeção do defeito, por evidência (ED-xx). */
  default Map<String, Boolean> inspecao(Map<String, Resposta> respostas) {
    Map<String, Boolean> inspecao = new LinkedHashMap<>();
    if (respostas != null) {
      respostas.forEach((codigo, resposta) -> inspecao.put(codigo, resposta(resposta)));
    }
    return inspecao;
  }
}
