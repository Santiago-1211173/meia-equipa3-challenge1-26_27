package com.levis.devolucoes.explicacao.porque;

import java.util.Optional;

/**
 * Pergunta que o sistema pode fazer ao colaborador: um dado de entrada (IN-001 a IN-010) ou outro
 * dado do pedido de que as regras dependem.
 */
public enum DadoEntrada {
  MERCADO(
      "IN-001",
      "loja.mercado",
      "Em que mercado fica a loja (Estados Unidos ou Canadá)?",
      "O mercado da transação (Estados Unidos vs Canadá) determina a aplicação de regras "
          + "fiscais e meios de pagamento exclusivos como débito Interac (TN-011) ou restrições a "
          + "franquias canadianas (CH-007, HS-004)."),
  TIPO_LOJA(
      "IN-002",
      "loja.tipoLoja",
      "A loja é Mainline ou Outlet?",
      "O formato da loja recetora (Mainline vs Outlet) condiciona as regras de cálculo do valor "
          + "de reembolso, aceitação de devoluções cruzadas e preços de liquidação promocional "
          + "(CH-001, CH-009, CH-010)."),
  CANAL(
      "IN-003",
      "compraOriginal.canal",
      "Onde e em que condições foi feita a compra (canal, Stylist, promoção por escalões, ajuste anterior)?",
      "O canal de compra original determina se o processo corre diretamente em loja física, via "
          + "portal online/BackPocket (CH-002), se deve ser recusado (grossistas via CH-008) ou se "
          + "pertence a franquia canadiana (CH-007)."),
  COMPROVATIVO(
      "IN-004",
      "comprovativo",
      "Que comprovativo de compra apresenta o cliente e o que confirma?",
      "O comprovativo apresentado é o pilar que classifica a devolução como verificada (PT-001) "
          + "com direito a estorno integral, ou como devolução às cegas (PT-002, PT-005) sujeita a "
          + "crédito de loja ou troca."),
  PEDIDO(
      "IN-005",
      "tipoPedido",
      "O que pede o cliente e, numa troca, o que leva?",
      "O tipo de pedido (devolução, devolução de oferta, troca de produto ou ajuste de preço) "
          + "define a árvore de dedução: elegibilidade de reembolso (PT-003), paridade de valor em "
          + "trocas (EP-001) ou limite de 14 dias para ajuste de preço (PT-007)."),
  MOMENTO(
      "IN-006",
      "compraOriginal.dataCompra",
      "Quando foi feita a compra ou o envio da encomenda?",
      "O prazo decorrido desde a compra/envio é o critério temporal regulamentar: até 30 dias "
          + "permite reembolso total (PT-003); após 30 dias requer autorização da gerência para "
          + "crédito de loja (PT-004); para ajuste de preço o limite máximo é de 14 dias (PT-007, "
          + "PT-008)."),
  PRODUTO(
      "IN-007",
      "artigos[].produto",
      "Que produto é devolvido (SKU, marca, categoria, sortido, saldo)?",
      "A verificação de SKU e marca atua como paragem obrigatória (Hard Stop): artigos com SKU "
          + "não reconhecido (HS-001) ou de marcas não autorizadas como Dockers ou Signature (HS-002) "
          + "são imediatamente recusados no balcão."),
  ESTADO(
      "IN-008",
      "artigos[].estado",
      "Em que estado está o artigo (uso, etiquetas, alterações, defeito, embalagem, segurança)?",
      "A condição física do produto dita a sua aprovação imediata (PC-001 para artigos "
          + "intactos), necessidade de inspeção de vendabilidade (PC-002/PC-003), ou recusa "
          + "categórica e isolamento de segurança para peças contaminadas (PC-008)."),
  PAGAMENTO(
      "IN-009",
      "compraOriginal.pagamento",
      "Como foi paga a compra e em que estado está esse meio?",
      "O meio de pagamento original dita o canal obrigatório de estorno: reembolsos em cartão "
          + "são tokenizados automaticamente (TN-001), compras Afterpay recusam exceções de balcão "
          + "(HS-005), e transações canadianas exigem cartão físico Interac (TN-011)."),
  REVENDA(
      "IN-010",
      "artigos[].revendivel",
      "O artigo pode ser verificado, reetiquetado e revendido?",
      "A aptidão para revenda imediata (vendabilidade) é a premissa indispensável para que a "
          + "chefia possa autorizar a aceitação de artigos com etiquetas soltas (PC-002) ou em falta "
          + "(PC-003)."),
  COLABORADOR(
      "HS-006",
      "colaborador",
      "Quem processa a transação e com que credencial de POS?",
      "O controlo de acessos no POS impede transações não autorizadas ou por colaboradores sem "
          + "nível de permissão adequado (HS-006, CT-001)."),
  CLIENTE(
      "EX-002",
      "cliente",
      "O cliente fornece dados, contesta o resultado ou está agitado?",
      "Perante contestação firme ou agitação do cliente, o protocolo de atendimento exige "
          + "escalonamento formal para a liderança de loja (EX-002, EX-003) e ativação de medidas de "
          + "desescalada (EX-005)."),
  EXCECAO(
      "EX-001",
      "pedidoExcecao",
      "O cliente pede uma exceção e qual foi a decisão da gestão?",
      "A submissão e aprovação de exceção de balcão pelo Key Holder ou Store Manager (EX-001, "
          + "EX-003) habilita o override no terminal POS, desde que não viole regras intransponíveis "
          + "da política corporativa (EX-006, HS-005)."),
  FRAUDE(
      "EX-008",
      "indicadoresFraude",
      "Há indícios de fraude ou inconsistências relevantes?",
      "Indicadores de fraude ou devoluções em série obrigam à suspensão cautelar imediata da "
          + "transação e notificação da segurança (EX-008)."),
  ONLINE(
      "CH-002",
      "compraOriginal.encomendaEncontrada",
      "A encomenda online foi encontrada, o portal está disponível e a política permite a devolução às cegas?",
      "A confirmação da encomenda e estado operacional do portal online determinam se a "
          + "devolução segue o fluxo BackPocket ou se recai em devolução às cegas (CH-002, CH-003, "
          + "CH-004).");

  private final String codigo;
  private final String caminho;
  private final String pergunta;
  private final String racional;

  DadoEntrada(String codigo, String caminho, String pergunta, String racional) {
    this.codigo = codigo;
    this.caminho = caminho;
    this.pergunta = pergunta;
    this.racional = racional;
  }

  public String codigo() {
    return codigo;
  }

  public String caminho() {
    return caminho;
  }

  public String pergunta() {
    return pergunta;
  }

  public String racional() {
    return racional;
  }

  public String racionalNegocio() {
    return racional;
  }

  /** Dado com o código indicado (ex.: IN-010), como devolvido pelo "O que falta?". */
  public static Optional<DadoEntrada> deCodigo(String codigo) {
    for (DadoEntrada dado : values()) {
      if (dado.codigo.equalsIgnoreCase(codigo) || dado.name().equalsIgnoreCase(codigo)) {
        return Optional.of(dado);
      }
    }
    return Optional.empty();
  }
}
