package com.levis.devolucoes.explicacao.porquenao;

import com.levis.devolucoes.model.decisao.Decisao;
import com.levis.devolucoes.model.decisao.DecisaoArtigo;
import com.levis.devolucoes.model.decisao.IndicadorFraude;
import com.levis.devolucoes.model.enums.CanalCompra;
import com.levis.devolucoes.model.enums.CategoriaProduto;
import com.levis.devolucoes.model.enums.ClassificacaoIncerteza;
import com.levis.devolucoes.model.enums.CondicaoUso;
import com.levis.devolucoes.model.enums.Elegibilidade;
import com.levis.devolucoes.model.enums.EstadoConta;
import com.levis.devolucoes.model.enums.EstadoEtiquetas;
import com.levis.devolucoes.model.enums.Funcao;
import com.levis.devolucoes.model.enums.Hipotese;
import com.levis.devolucoes.model.enums.Marca;
import com.levis.devolucoes.model.enums.MeioPagamento;
import com.levis.devolucoes.model.enums.MeioReembolso;
import com.levis.devolucoes.model.enums.Mercado;
import com.levis.devolucoes.model.enums.NivelRisco;
import com.levis.devolucoes.model.enums.TipoComprovativo;
import com.levis.devolucoes.model.enums.TipoLoja;
import com.levis.devolucoes.model.enums.TipoPedido;
import com.levis.devolucoes.model.enums.TipoTransacao;
import com.levis.devolucoes.model.enums.TipoVerificacao;
import com.levis.devolucoes.model.incerteza.GrauCrenca;
import com.levis.devolucoes.model.pedido.Colaborador;
import com.levis.devolucoes.model.pedido.CompraOriginal;
import com.levis.devolucoes.model.pedido.Comprovativo;
import com.levis.devolucoes.model.pedido.Pagamento;
import com.levis.devolucoes.model.pedido.PedidoExcecao;
import com.levis.devolucoes.model.produto.ArtigoDevolvido;
import com.levis.devolucoes.model.produto.ArtigoTroca;
import com.levis.devolucoes.model.produto.EstadoProduto;
import com.levis.devolucoes.model.produto.Produto;
import java.math.BigDecimal;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.function.Function;
import java.util.function.Predicate;

/**
 * Predicados Java das condições declaradas em {@code @condicoes}. Cada predicado reproduz a
 * condição correspondente do DRL; o teste de coerência verifica que, em cada regra disparada, as
 * condições sobre os dados de entrada são verdadeiras.
 */
public final class RegistoPredicados {

  private final Map<String, Predicado> predicados = new LinkedHashMap<>();

  public RegistoPredicados() {
    registarCanalEComprovativo();
    registarPrazo();
    registarProduto();
    registarPagamento();
    registarClienteEColaborador();
    registarExcecoes();
    registarEstadoDaDecisao();
    registarIncerteza();
  }

  public Optional<Predicado> predicado(String nome) {
    return Optional.ofNullable(predicados.get(nome));
  }

  public Set<String> nomes() {
    return Collections.unmodifiableSet(predicados.keySet());
  }

  // -------------------------------------------------------------------------------------------
  // Registo
  // -------------------------------------------------------------------------------------------

  private void pedido(
      String nome,
      String descricao,
      Predicate<ContextoAvaliacao> teste,
      Function<ContextoAvaliacao, String> valor) {
    predicados.put(nome, new Predicado(nome, descricao, false, true, teste, valor));
  }

  private void artigo(
      String nome,
      String descricao,
      Predicate<ContextoAvaliacao> teste,
      Function<ContextoAvaliacao, String> valor) {
    predicados.put(nome, new Predicado(nome, descricao, true, true, teste, valor));
  }

  private void estadoPedido(String nome, String descricao, Predicate<ContextoAvaliacao> teste) {
    predicados.put(nome, new Predicado(nome, descricao, false, false, teste, null));
  }

  private void estadoArtigo(String nome, String descricao, Predicate<ContextoAvaliacao> teste) {
    predicados.put(nome, new Predicado(nome, descricao, true, false, teste, null));
  }

  // -------------------------------------------------------------------------------------------
  // Acesso aos factos
  // -------------------------------------------------------------------------------------------

  private static CompraOriginal compra(ContextoAvaliacao c) {
    return c.pedido().getCompraOriginal();
  }

  private static CanalCompra canal(ContextoAvaliacao c) {
    return compra(c) == null ? null : compra(c).getCanal();
  }

  private static Pagamento pagamento(ContextoAvaliacao c) {
    return compra(c) == null ? null : compra(c).getPagamento();
  }

  private static MeioPagamento meio(ContextoAvaliacao c) {
    return pagamento(c) == null ? null : pagamento(c).getMeio();
  }

  private static boolean meioEm(ContextoAvaliacao c, MeioPagamento... meios) {
    MeioPagamento meio = meio(c);
    for (MeioPagamento m : meios) {
      if (m == meio) {
        return true;
      }
    }
    return false;
  }

  private static Comprovativo comprovativo(ContextoAvaliacao c) {
    return c.pedido().getComprovativo();
  }

  private static PedidoExcecao excecao(ContextoAvaliacao c) {
    return c.pedido().getPedidoExcecao();
  }

  private static Colaborador colaborador(ContextoAvaliacao c) {
    return c.pedido().getColaborador();
  }

  private static Produto produto(ContextoAvaliacao c) {
    return c.artigo().getProduto();
  }

  private static EstadoProduto estado(ContextoAvaliacao c) {
    return c.artigo().getEstado();
  }

  private static boolean bodywear(ContextoAvaliacao c) {
    return produto(c) != null && produto(c).getCategoria() == CategoriaProduto.BODYWEAR;
  }

  private static boolean uso(ContextoAvaliacao c, CondicaoUso condicao) {
    return estado(c) != null && estado(c).getCondicaoUso() == condicao;
  }

  private static boolean etiquetas(ContextoAvaliacao c, EstadoEtiquetas valor) {
    return estado(c) != null && estado(c).getEtiquetas() == valor;
  }

  private static Long diasCompra(ContextoAvaliacao c) {
    return c.pedido().getDiasDesdeCompra();
  }

  private static Long diasEnvio(ContextoAvaliacao c) {
    return c.pedido().getDiasDesdeEnvio();
  }

  private static Decisao decisao(ContextoAvaliacao c) {
    return c.decisao();
  }

  private static boolean elegivel(DecisaoArtigo a) {
    return !a.isTerminal()
        && (a.getElegibilidade() == Elegibilidade.PERMITIR
            || a.getElegibilidade() == Elegibilidade.REVER);
  }

  private static ArtigoDevolvido artigoPorId(ContextoAvaliacao c, String id) {
    return c.pedido().getArtigos().stream()
        .filter(a -> id.equals(a.getId()))
        .findFirst()
        .orElse(null);
  }

  private static boolean fraudeRelevante(ContextoAvaliacao c) {
    // O indício registado pela IU-11 a partir de um risco alto (docs/08 §2.3)
    if (classe(c, Hipotese.FRAUDE, null) == ClassificacaoIncerteza.RISCO_ALTO) {
      return true;
    }
    for (IndicadorFraude f : c.fraudes()) {
      if (c.pedido().getId().equals(f.getPedidoId())
          && (f.getNivelRisco() == NivelRisco.SIGNIFICATIVO
              || f.getNivelRisco() == NivelRisco.CONFIRMADO)) {
        return true;
      }
    }
    return false;
  }

  private static BigDecimal precoTroca(ContextoAvaliacao c) {
    BigDecimal total = BigDecimal.ZERO;
    for (ArtigoTroca troca : c.pedido().getArtigosTroca()) {
      if (troca.getPrecoVenda() != null) {
        total = total.add(troca.getPrecoVenda());
      }
    }
    return total;
  }

  private static String de(Object valor) {
    return String.valueOf(valor);
  }

  // -------------------------------------------------------------------------------------------
  // Canal, comprovativo e tipo de pedido
  // -------------------------------------------------------------------------------------------

  private void registarCanalEComprovativo() {
    Function<ContextoAvaliacao, String> valorCanal = c -> "canal = " + de(canal(c));
    pedido(
        "canalGrossista",
        "Compra num retalhista grossista",
        c -> canal(c) == CanalCompra.GROSSISTA,
        valorCanal);
    pedido(
        "canalFranquiaCanada",
        "Compra na franquia do Canadá",
        c -> canal(c) == CanalCompra.FRANQUIA_CANADA,
        valorCanal);
    pedido(
        "canalLoja",
        "Compra Mainline ou Outlet",
        c -> canal(c) == CanalCompra.MAINLINE || canal(c) == CanalCompra.OUTLET,
        valorCanal);
    pedido(
        "canalDesconhecido",
        "Canal de compra desconhecido",
        c -> canal(c) == CanalCompra.DESCONHECIDO,
        valorCanal);
    pedido(
        "compraMainlineOuOutlet",
        "Compra em loja Mainline ou Outlet",
        c -> canal(c) == CanalCompra.MAINLINE || canal(c) == CanalCompra.OUTLET,
        valorCanal);
    pedido(
        "compraEmLoja",
        "Compra em loja (não online)",
        c -> compra(c) != null && !c.pedido().isCompraOnline(),
        valorCanal);
    pedido(
        "compraForaDaLoja",
        "Compra fora das lojas Mainline e Outlet",
        c ->
            compra(c) != null && canal(c) != CanalCompra.MAINLINE && canal(c) != CanalCompra.OUTLET,
        valorCanal);
    pedido(
        "compraBackPocket",
        "Compra BackPocket",
        c -> canal(c) == CanalCompra.BACKPOCKET,
        valorCanal);
    pedido(
        "compraOnline",
        "Compra em levi.com ou levi.ca",
        c -> c.pedido().isCompraOnline(),
        valorCanal);
    pedido(
        "compraNaoOnline",
        "Compra que não é online",
        c -> !c.pedido().isCompraOnline(),
        valorCanal);
    pedido(
        "origemMainlineOuOnline",
        "Compra Mainline ou online",
        c ->
            canal(c) == CanalCompra.MAINLINE
                || canal(c) == CanalCompra.LEVI_COM
                || canal(c) == CanalCompra.LEVI_CA,
        valorCanal);
    pedido(
        "lojaOutlet",
        "A loja recetora é Outlet",
        c -> c.pedido().getLoja() != null && c.pedido().getLoja().getTipoLoja() == TipoLoja.OUTLET,
        c ->
            "loja = " + (c.pedido().getLoja() == null ? null : c.pedido().getLoja().getTipoLoja()));
    pedido(
        "mercadoCanada",
        "Loja no Canadá",
        c -> c.pedido().getLoja() != null && c.pedido().getLoja().getMercado() == Mercado.CANADA,
        c ->
            "mercado = "
                + (c.pedido().getLoja() == null ? null : c.pedido().getLoja().getMercado()));

    Function<ContextoAvaliacao, String> valorComprovativo =
        c ->
            comprovativo(c) == null
                ? "sem comprovativo"
                : "comprovativo = "
                    + comprovativo(c).getTipo()
                    + ", confirma = "
                    + comprovativo(c).isConfirmaCompra()
                    + ", original = "
                    + comprovativo(c).isReciboOriginal();
    pedido(
        "comprovativoValido",
        "Comprovativo válido (PT-001)",
        c -> comprovativo(c) != null && comprovativo(c).isValido(),
        valorComprovativo);
    pedido(
        "comprovativoConfirmaCompra",
        "O comprovativo confirma a compra",
        c -> comprovativo(c) != null && comprovativo(c).isConfirmaCompra(),
        valorComprovativo);
    pedido(
        "semComprovativoValido",
        "Sem comprovativo válido que confirme a compra",
        c ->
            comprovativo(c) == null
                || !comprovativo(c).isValido()
                || !comprovativo(c).isConfirmaCompra(),
        valorComprovativo);
    pedido(
        "reciboOriginal",
        "Recibo original",
        c -> comprovativo(c) != null && comprovativo(c).isReciboOriginal(),
        valorComprovativo);
    pedido(
        "reciboOriginalImpresso",
        "Recibo original impresso",
        c ->
            comprovativo(c) != null
                && comprovativo(c).isReciboOriginal()
                && comprovativo(c).getTipo() == TipoComprovativo.RECIBO_IMPRESSO,
        valorComprovativo);
    pedido(
        "encomendaEncontrada",
        "A encomenda online foi encontrada",
        c -> compra(c) != null && compra(c).isEncomendaEncontrada(),
        c -> "encomendaEncontrada = " + (compra(c) != null && compra(c).isEncomendaEncontrada()));
    pedido(
        "encomendaNaoEncontrada",
        "A encomenda online não foi encontrada",
        c -> compra(c) != null && !compra(c).isEncomendaEncontrada(),
        c -> "encomendaEncontrada = " + (compra(c) != null && compra(c).isEncomendaEncontrada()));
    pedido(
        "portalDisponivel",
        "Portal de devoluções online disponível",
        c -> c.pedido().isPortalOnlineDisponivel(),
        c -> "portal = " + c.pedido().isPortalOnlineDisponivel());
    pedido(
        "portalIndisponivel",
        "Portal de devoluções online indisponível",
        c -> !c.pedido().isPortalOnlineDisponivel(),
        c -> "portal = " + c.pedido().isPortalOnlineDisponivel());
    pedido(
        "politicaPermiteAsCegasOnline",
        "A política permite a devolução online às cegas",
        c -> c.pedido().isPoliticaPermiteAsCegasOnline(),
        c -> "politica = " + c.pedido().isPoliticaPermiteAsCegasOnline());
    pedido(
        "politicaNaoPermiteAsCegasOnline",
        "A política não permite a devolução online às cegas",
        c -> !c.pedido().isPoliticaPermiteAsCegasOnline(),
        c -> "politica = " + c.pedido().isPoliticaPermiteAsCegasOnline());
    pedido(
        "promocaoEscaloes",
        "Promoção por escalões",
        c -> compra(c) != null && compra(c).isPromocaoEscaloes(),
        c -> "promocaoEscaloes = " + (compra(c) != null && compra(c).isPromocaoEscaloes()));
    pedido(
        "stylistDaVendaConhecido",
        "Stylist da venda original conhecido",
        c -> compra(c) != null && compra(c).getIdStylistVenda() != null,
        c -> "stylist = " + (compra(c) == null ? null : compra(c).getIdStylistVenda()));

    Function<ContextoAvaliacao, String> valorTipo = c -> "pedido = " + c.pedido().getTipoPedido();
    pedido(
        "ajustePreco",
        "Pedido de ajuste de preço",
        c -> c.pedido().getTipoPedido() == TipoPedido.AJUSTE_PRECO,
        valorTipo);
    pedido(
        "naoEAjustePreco",
        "Não é um ajuste de preço",
        c -> c.pedido().getTipoPedido() != TipoPedido.AJUSTE_PRECO,
        valorTipo);
    pedido(
        "devolucaoOferta",
        "Devolução de oferta",
        c -> c.pedido().getTipoPedido() == TipoPedido.DEVOLUCAO_OFERTA,
        valorTipo);
    pedido(
        "naoEOferta",
        "Não é devolução de oferta",
        c -> c.pedido().getTipoPedido() != TipoPedido.DEVOLUCAO_OFERTA,
        valorTipo);
    pedido(
        "pedidoTroca",
        "Pedido de troca",
        c -> c.pedido().getTipoPedido() == TipoPedido.TROCA,
        valorTipo);
    pedido(
        "apenasMudaTamanho",
        "A troca muda apenas o tamanho",
        c ->
            !c.pedido().getArtigosTroca().isEmpty()
                && c.pedido().getArtigosTroca().stream().allMatch(ArtigoTroca::isApenasMudaTamanho),
        null);
    pedido(
        "mudaModeloOuCor",
        "A troca muda o modelo ou a cor",
        c -> c.pedido().getArtigosTroca().stream().anyMatch(t -> !t.isApenasMudaTamanho()),
        null);
    // EX-008 altera o pedido (suspenso): é estado da avaliação, não um dado de entrada
    estadoPedido("pedidoNaoSuspenso", "Transação não suspensa", c -> !c.pedido().isSuspenso());
  }

  // -------------------------------------------------------------------------------------------
  // Prazos
  // -------------------------------------------------------------------------------------------

  private void registarPrazo() {
    Function<ContextoAvaliacao, String> compra = c -> "dias desde a compra = " + diasCompra(c);
    Function<ContextoAvaliacao, String> envio = c -> "dias desde o envio = " + diasEnvio(c);
    pedido(
        "ate30DiasDesdeCompra",
        "Até 30 dias desde a compra",
        c -> diasCompra(c) != null && diasCompra(c) <= 30,
        compra);
    pedido(
        "mais30DiasDesdeCompra",
        "Mais de 30 dias desde a compra",
        c -> diasCompra(c) != null && diasCompra(c) > 30,
        compra);
    pedido(
        "ate14DiasDesdeCompra",
        "Até 14 dias desde a compra",
        c -> diasCompra(c) != null && diasCompra(c) <= 14,
        compra);
    pedido(
        "mais14DiasOuSemReciboOriginal",
        "Mais de 14 dias ou sem recibo original",
        c ->
            comprovativo(c) == null
                || !comprovativo(c).isReciboOriginal()
                || diasCompra(c) == null
                || diasCompra(c) > 14,
        compra);
    pedido(
        "ate30DiasDesdeEnvio",
        "Até 30 dias desde o envio",
        c -> diasEnvio(c) == null || diasEnvio(c) <= 30,
        envio);
    pedido(
        "mais30DiasDesdeEnvio",
        "Mais de 30 dias desde o envio",
        c -> diasEnvio(c) != null && diasEnvio(c) > 30,
        envio);
    pedido(
        "semAjusteAnterior",
        "Sem ajuste de preço anterior",
        c -> compra(c) != null && !compra(c).isAjustePrecoAplicado(),
        null);
    pedido(
        "ajusteAnterior",
        "Já houve um ajuste de preço",
        c -> compra(c) != null && compra(c).isAjustePrecoAplicado(),
        null);
  }

  // -------------------------------------------------------------------------------------------
  // Produto e estado do artigo
  // -------------------------------------------------------------------------------------------

  private void registarProduto() {
    Function<ContextoAvaliacao, String> sku =
        c ->
            "sku = "
                + (produto(c) == null ? null : produto(c).getSku())
                + ", reconhecido = "
                + (produto(c) != null && produto(c).isSkuReconhecidoPOS());
    artigo(
        "skuReconhecido",
        "SKU reconhecido no POS",
        c -> produto(c) != null && produto(c).isSkuReconhecidoPOS(),
        sku);
    artigo(
        "skuNaoReconhecido",
        "SKU não reconhecido no POS",
        c -> produto(c) != null && !produto(c).isSkuReconhecidoPOS(),
        sku);
    artigo(
        "produtoFranquia",
        "Produto da franquia do Canadá",
        c -> produto(c) != null && produto(c).isProdutoFranquia(),
        null);
    artigo(
        "produtoNaoFranquia",
        "Produto que não é da franquia do Canadá",
        c -> produto(c) != null && !produto(c).isProdutoFranquia(),
        null);
    artigo(
        "marcaExcluidaOuGrossistaNaoVendido",
        "Dockers, LS Signature, Beyond Yoga ou grossista não vendido na loja",
        c ->
            produto(c) != null
                && (produto(c).getMarca() == Marca.DOCKERS
                    || produto(c).getMarca() == Marca.LS_SIGNATURE
                    || produto(c).getMarca() == Marca.BEYOND_YOGA
                    || (produto(c).isGrossista() && !produto(c).isVendidoNaLoja())),
        c ->
            produto(c) == null
                ? null
                : "marca = " + produto(c).getMarca() + ", grossista = " + produto(c).isGrossista());
    artigo(
        "produtoModificado",
        "Produto personalizado, alterado ou embainhado",
        c -> estado(c) != null && estado(c).isModificado(),
        null);
    artigo(
        "naoModificado",
        "Produto não personalizado nem alterado (HS-003 prevalece)",
        c -> estado(c) != null && !estado(c).isModificado(),
        null);

    Function<ContextoAvaliacao, String> categoria =
        c -> "categoria = " + (produto(c) == null ? null : produto(c).getCategoria());
    artigo("bodywear", "Bodywear", RegistoPredicados::bodywear, categoria);
    artigo("naoBodywear", "Não é bodywear", c -> produto(c) != null && !bodywear(c), categoria);

    Function<ContextoAvaliacao, String> condicao =
        c ->
            estado(c) == null
                ? null
                : "uso = "
                    + estado(c).getCondicaoUso()
                    + ", etiquetas = "
                    + estado(c).getEtiquetas();
    artigo("naoUsado", "Não usado", c -> uso(c, CondicaoUso.NAO_USADO), condicao);
    artigo("usado", "Claramente usado", c -> uso(c, CondicaoUso.USADO), condicao);
    artigo("lavado", "Lavado", c -> uso(c, CondicaoUso.LAVADO), condicao);
    artigo(
        "etiquetasColocadas",
        "Etiquetas originais colocadas",
        c -> etiquetas(c, EstadoEtiquetas.COLOCADAS),
        condicao);
    artigo(
        "etiquetasSoltas", "Etiquetas soltas", c -> etiquetas(c, EstadoEtiquetas.SOLTAS), condicao);
    artigo(
        "etiquetasAusentes",
        "Sem etiquetas",
        c -> etiquetas(c, EstadoEtiquetas.AUSENTES),
        condicao);
    artigo(
        "defeitoFabricoConfirmado",
        "Defeito de fabrico confirmado",
        c -> estado(c) != null && estado(c).isDefeitoFabricoConfirmado(),
        null);
    artigo(
        "semDefeito",
        "Sem defeito de fabrico confirmado",
        c -> estado(c) != null && !estado(c).isDefeitoFabricoConfirmado(),
        null);
    artigo(
        "sujoOuInseguro",
        "Sujo, contaminado ou inseguro",
        c -> estado(c) != null && estado(c).isSujoOuInseguro(),
        null);
    artigo(
        "artigoSujoOuInseguro",
        "Artigo sujo, contaminado ou inseguro de manusear",
        c -> estado(c) != null && estado(c).isSujoOuInseguro(),
        null);
    artigo(
        "embalagemIntacta",
        "Embalagem original intacta",
        c -> estado(c) != null && estado(c).isEmbalagemIntacta(),
        null);
    artigo(
        "semEmbalagem",
        "Sem a embalagem original",
        c -> estado(c) != null && !estado(c).isEmbalagemIntacta(),
        null);
    artigo(
        "conjuntoCompleto",
        "Conjunto completo",
        c -> estado(c) != null && estado(c).isConjuntoCompleto(),
        null);
    artigo(
        "conjuntoIncompletoOuUsado",
        "Faltam unidades do conjunto ou foi usado",
        c ->
            estado(c) != null
                && (!estado(c).isConjuntoCompleto()
                    || estado(c).getCondicaoUso() == CondicaoUso.USADO),
        condicao);

    Function<ContextoAvaliacao, String> revenda =
        c -> "revendivel (IN-010) = " + c.artigo().getRevendivel();
    artigo(
        "revendivel",
        "Verificável, reetiquetável e revendível (IN-010)",
        c -> Boolean.TRUE.equals(c.artigo().getRevendivel()),
        revenda);
    artigo(
        "naoRevendivel",
        "Não revendível (IN-010)",
        c -> Boolean.FALSE.equals(c.artigo().getRevendivel()),
        revenda);
    artigo(
        "revendivelPorAvaliar",
        "Possibilidade de revenda ainda por avaliar (IN-010)",
        c -> c.artigo().getRevendivel() == null,
        revenda);
    artigo(
        "entreCanais",
        "Artigo comprado noutro canal ou loja",
        c -> c.artigo().isEntreCanais(),
        null);
    artigo("emSaldo", "Já está em saldo", c -> produto(c) != null && produto(c).isEmSaldo(), null);
    artigo(
        "naoEmSaldo",
        "Não está em saldo",
        c -> produto(c) != null && !produto(c).isEmSaldo(),
        null);
    artigo(
        "noSortidoDaLojaRecetora",
        "Está ou esteve no sortido da loja recetora",
        c ->
            c.pedido().getLoja() != null
                && produto(c) != null
                && c.pedido().getLoja().estaNoSortido(produto(c).getSku()),
        null);
    artigo(
        "foraDoSortidoDaLojaRecetora",
        "Fora do sortido da loja recetora",
        c ->
            c.pedido().getLoja() != null
                && produto(c) != null
                && !c.pedido().getLoja().estaNoSortido(produto(c).getSku()),
        null);
  }

  // -------------------------------------------------------------------------------------------
  // Pagamento
  // -------------------------------------------------------------------------------------------

  private void registarPagamento() {
    Function<ContextoAvaliacao, String> valorMeio = c -> "meio = " + meio(c);
    pedido(
        "pagamentoAfterpay",
        "Pago com Afterpay",
        c -> meioEm(c, MeioPagamento.AFTERPAY),
        valorMeio);
    pedido(
        "naoAfterpay", "Não pago com Afterpay", c -> !meioEm(c, MeioPagamento.AFTERPAY), valorMeio);
    pedido(
        "pagamentoCreditoOuDebito",
        "Pago a crédito ou débito",
        c -> meioEm(c, MeioPagamento.CREDITO, MeioPagamento.DEBITO),
        valorMeio);
    pedido("pagamentoDebito", "Pago a débito", c -> meioEm(c, MeioPagamento.DEBITO), valorMeio);
    pedido(
        "pagamentoContactless",
        "Pago com Apple Pay ou Google Pay",
        c -> meioEm(c, MeioPagamento.APPLE_PAY, MeioPagamento.GOOGLE_PAY),
        valorMeio);
    pedido(
        "pagamentoComCartao",
        "Pago com cartão (crédito, débito ou contactless)",
        c ->
            meioEm(
                c,
                MeioPagamento.CREDITO,
                MeioPagamento.DEBITO,
                MeioPagamento.APPLE_PAY,
                MeioPagamento.GOOGLE_PAY),
        valorMeio);
    pedido(
        "pagamentoPaypalOuVenmo",
        "Pago com PayPal ou Venmo",
        c -> meioEm(c, MeioPagamento.PAYPAL, MeioPagamento.VENMO),
        valorMeio);
    pedido(
        "pagamentoInterac", "Pago com Interac", c -> meioEm(c, MeioPagamento.INTERAC), valorMeio);
    pedido(
        "pagamentoNumerarioOuCartaoOferta",
        "Pago em numerário ou cartão de oferta",
        c -> meioEm(c, MeioPagamento.NUMERARIO, MeioPagamento.CARTAO_OFERTA),
        valorMeio);
    pedido(
        "pagamentoSemProcessoProprio",
        "Meio sem processo próprio (não Afterpay, PayPal nem Venmo)",
        c ->
            pagamento(c) == null
                || !meioEm(c, MeioPagamento.AFTERPAY, MeioPagamento.PAYPAL, MeioPagamento.VENMO),
        valorMeio);
    pedido(
        "acessoAplicacao",
        "O cliente acede à aplicação de pagamento",
        c -> pagamento(c) != null && pagamento(c).isAcessoAplicacaoPagamento(),
        null);
    pedido(
        "semAcessoAplicacao",
        "O cliente não acede à aplicação de pagamento",
        c -> pagamento(c) != null && !pagamento(c).isAcessoAplicacaoPagamento(),
        null);
    pedido(
        "cartaoFisicoPresente",
        "Apresenta o mesmo cartão físico",
        c -> pagamento(c) != null && pagamento(c).isCartaoFisicoPresente(),
        null);
    pedido(
        "cartaoFisicoAusente",
        "Não apresenta o mesmo cartão físico",
        c -> pagamento(c) != null && !pagamento(c).isCartaoFisicoPresente(),
        null);
    Function<ContextoAvaliacao, String> conta =
        c -> "conta = " + (pagamento(c) == null ? null : pagamento(c).getEstadoConta());
    pedido(
        "contaAtivaCartaoPerdido",
        "Cartão perdido ou roubado com a conta ativa",
        c ->
            pagamento(c) != null
                && pagamento(c).getEstadoConta() == EstadoConta.ATIVA_CARTAO_PERDIDO,
        conta);
    pedido(
        "contaEncerrada",
        "Conta do cartão original encerrada",
        c -> pagamento(c) != null && pagamento(c).getEstadoConta() == EstadoConta.ENCERRADA,
        conta);
    pedido(
        "reembolsoOriginalRecusado",
        "O reembolso ao meio original foi recusado",
        c -> pagamento(c) != null && pagamento(c).isReembolsoOriginalRecusado(),
        null);
    pedido(
        "reembolsoOriginalNaoRecusado",
        "O reembolso ao meio original não foi recusado",
        c -> pagamento(c) != null && !pagamento(c).isReembolsoOriginalRecusado(),
        null);
  }

  // -------------------------------------------------------------------------------------------
  // Cliente, colaborador e fraude
  // -------------------------------------------------------------------------------------------

  private void registarClienteEColaborador() {
    Function<ContextoAvaliacao, String> funcao =
        c -> "função = " + (colaborador(c) == null ? null : colaborador(c).getFuncao());
    pedido(
        "colaboradorAutorizado",
        "Colaborador autorizado (HS-006)",
        c -> colaborador(c) != null && colaborador(c).isAutorizado(),
        funcao);
    pedido(
        "colaboradorNaoAutorizado",
        "Colaborador não autorizado",
        c -> colaborador(c) == null || !colaborador(c).isAutorizado(),
        funcao);
    pedido(
        "credencialPosPropria",
        "Credencial de POS própria",
        c -> colaborador(c) != null && colaborador(c).getIdCredencialPOS() != null,
        null);
    pedido(
        "processadorLeadCashierOuElevatedStylist",
        "Processador Lead Cashier ou Elevated Stylist",
        c ->
            colaborador(c) != null
                && (colaborador(c).getFuncao() == Funcao.LEAD_CASHIER
                    || colaborador(c).getFuncao() == Funcao.ELEVATED_STYLIST),
        funcao);
    pedido(
        "clienteContesta",
        "O cliente contesta o resultado",
        c -> c.pedido().getCliente() != null && c.pedido().getCliente().isContestaResultado(),
        null);
    pedido(
        "clienteAgitado",
        "O cliente está irritado ou causa perturbação",
        c -> c.pedido().getCliente() != null && c.pedido().getCliente().isAgitado(),
        null);
    pedido(
        "clienteNaoForneceDadosOuBarreiraLinguistica",
        "O cliente não dá dados pessoais ou há barreira linguística",
        c ->
            c.pedido().getCliente() != null
                && (!c.pedido().getCliente().isForneceDados()
                    || c.pedido().getCliente().isBarreiraLinguistica()),
        null);
    pedido(
        "indicioFraudeRelevante",
        "Indício de fraude significativo ou confirmado",
        RegistoPredicados::fraudeRelevante,
        null);
    pedido(
        "baixoRisco",
        "Sem indício de fraude significativo ou confirmado",
        c -> !fraudeRelevante(c),
        null);
  }

  // -------------------------------------------------------------------------------------------
  // Pedido de exceção
  // -------------------------------------------------------------------------------------------

  private void registarExcecoes() {
    Function<ContextoAvaliacao, String> aprovada =
        c -> "aprovada = " + (excecao(c) == null ? null : excecao(c).getAprovada());
    pedido("pedidoExcecao", "Há um pedido de exceção", c -> excecao(c) != null, null);
    pedido(
        "aprovacaoGestaoPendente",
        "Decisão da gestão pendente",
        c -> excecao(c) == null || excecao(c).getAprovada() == null,
        aprovada);
    pedido(
        "aprovadoPelaGestao",
        "Aprovado pela gestão",
        c -> excecao(c) != null && Boolean.TRUE.equals(excecao(c).getAprovada()),
        aprovada);
    pedido(
        "recusadoPelaGestao",
        "Recusado pela gestão",
        c -> excecao(c) != null && Boolean.FALSE.equals(excecao(c).getAprovada()),
        aprovada);
    pedido(
        "excecaoAprovada",
        "Exceção aprovada",
        c -> excecao(c) != null && Boolean.TRUE.equals(excecao(c).getAprovada()),
        aprovada);
    pedido(
        "concluivelNoSistema",
        "O resultado pode ser concluído no sistema",
        c -> excecao(c) != null && excecao(c).isConcluivelNoSistema(),
        null);
    pedido(
        "exigeControloObrigatorio",
        "A exceção exige meio proibido, SKU incorreto, produto excluído ou contornar um processo obrigatório",
        c ->
            excecao(c) != null
                && (excecao(c).isExigeMeioProibido()
                    || excecao(c).isExigeSkuIncorreto()
                    || excecao(c).isEnvolveProdutoExcluido()
                    || excecao(c).isContornaProcessoObrigatorio()),
        null);
    pedido(
        "pedidoDeExcecaoAoMeio",
        "Pede troca ou outro meio de reembolso",
        c ->
            c.pedido().getTipoPedido() == TipoPedido.TROCA
                || (excecao(c) != null
                    && (excecao(c).isExigeMeioProibido()
                        || excecao(c).isContornaProcessoObrigatorio())),
        null);
  }

  // -------------------------------------------------------------------------------------------
  // Estado da decisão (resultado de outras regras)
  // -------------------------------------------------------------------------------------------

  private void registarEstadoDaDecisao() {
    estadoPedido(
        "devolucaoVerificada",
        "Devolução verificada (PT-001 ou CH-002)",
        c -> decisao(c).getTipoVerificacao() == TipoVerificacao.VERIFICADA);
    estadoPedido(
        "devolucaoAsCegas",
        "Devolução às cegas (PT-002 ou CH-003)",
        c -> decisao(c).getTipoVerificacao() == TipoVerificacao.AS_CEGAS);
    estadoPedido(
        "devolucaoAsCegasOnlinePermitida",
        "Devolução online às cegas permitida (CH-003)",
        c ->
            decisao(c).getTipoVerificacao() == TipoVerificacao.AS_CEGAS
                && c.pedido().isPoliticaPermiteAsCegasOnline());
    estadoPedido(
        "artigoElegivel",
        "Há pelo menos um artigo elegível (G3)",
        c -> c.decisoesArtigos().stream().anyMatch(RegistoPredicados::elegivel));
    estadoPedido(
        "artigoRevendivel",
        "Todos os artigos elegíveis são revendíveis",
        c ->
            c.decisoesArtigos().stream().anyMatch(RegistoPredicados::elegivel)
                && c.decisoesArtigos().stream()
                    .filter(RegistoPredicados::elegivel)
                    .allMatch(
                        a ->
                            artigoPorId(c, a.getArtigoId()) != null
                                && Boolean.TRUE.equals(
                                    artigoPorId(c, a.getArtigoId()).getRevendivel())));
    estadoPedido(
        "artigoNaoRevendivel",
        "Há um artigo elegível não revendível",
        c ->
            c.decisoesArtigos().stream()
                .filter(RegistoPredicados::elegivel)
                .anyMatch(
                    a ->
                        artigoPorId(c, a.getArtigoId()) != null
                            && Boolean.FALSE.equals(
                                artigoPorId(c, a.getArtigoId()).getRevendivel())));
    estadoPedido(
        "artigoRevendivelPorAvaliar",
        "Há um artigo elegível com a revenda por avaliar (IN-010)",
        c ->
            c.decisoesArtigos().stream()
                .filter(RegistoPredicados::elegivel)
                .anyMatch(
                    a ->
                        artigoPorId(c, a.getArtigoId()) != null
                            && artigoPorId(c, a.getArtigoId()).getRevendivel() == null));
    estadoPedido(
        "encaminhadaBackPocket",
        "Encaminhada para a BackPocket (CH-002)",
        c -> decisao(c).disparou("CH-002"));
    estadoPedido(
        "tokenizacaoAplicada", "Reembolso tokenizado (TN-001)", c -> decisao(c).disparou("TN-001"));
    estadoPedido(
        "interacVerificado",
        "Cartão Interac verificado (TN-011)",
        c -> decisao(c).disparou("TN-011"));
    estadoPedido(
        "assinaturasObtidas", "Assinaturas obtidas (CT-005)", c -> decisao(c).disparou("CT-005"));
    estadoPedido(
        "escaladoResponsavelSenior",
        "Escalado para o responsável sénior (EX-003)",
        c -> decisao(c).disparou("EX-003"));
    estadoPedido(
        "politicaExplicada",
        "Política explicada ao cliente (EX-002)",
        c -> decisao(c).disparou("EX-002"));
    estadoPedido(
        "excecaoEmAvaliacao",
        "Exceção em avaliação (EX-001 ou EX-004)",
        c -> decisao(c).disparou("EX-001") || decisao(c).disparou("EX-004"));
    estadoPedido(
        "excecaoNaoRecusada", "A exceção não foi recusada", c -> !decisao(c).isExcecaoRecusada());
    estadoPedido(
        "semParagemHs",
        "Nenhuma regra HS disparou",
        c ->
            decisao(c).getRegistos().stream().noneMatch(r -> r.getCodigoRegra().startsWith("HS-"))
                && c.decisoesArtigos().stream()
                    .flatMap(a -> a.getRegistos().stream())
                    .noneMatch(r -> r.getCodigoRegra().startsWith("HS-")));
    estadoPedido(
        "paragemOuNaoVerificadaOuRiscoOuNaoConcluivel",
        "Há uma paragem HS, a compra não é verificada, o risco não é baixo ou não é concluível",
        c ->
            !(predicados.get("semParagemHs").teste().test(c)
                && decisao(c).getTipoVerificacao() == TipoVerificacao.VERIFICADA
                && !fraudeRelevante(c)
                && excecao(c) != null
                && excecao(c).isConcluivelNoSistema()));
    estadoPedido(
        "resultadoRever",
        "Um resultado é REVER",
        c ->
            decisao(c).getElegibilidade() == Elegibilidade.REVER
                || c.decisoesArtigos().stream()
                    .anyMatch(a -> !a.isTerminal() && a.getElegibilidade() == Elegibilidade.REVER));
    estadoPedido(
        "resultadoEmitido",
        "Já foi emitido um resultado",
        c ->
            decisao(c).getElegibilidade() != null
                || c.decisoesArtigos().stream().anyMatch(a -> a.getElegibilidade() != null));
    estadoPedido(
        "trocaPermitida",
        "Troca permitida",
        c -> decisao(c).getTipoTransacao() == TipoTransacao.TROCA);
    estadoPedido(
        "trocaVerificada",
        "Troca verificada",
        c ->
            decisao(c).getTipoTransacao() == TipoTransacao.TROCA
                && decisao(c).getTipoVerificacao() == TipoVerificacao.VERIFICADA);
    estadoPedido(
        "reembolsoVerificadoNoMeioOriginal",
        "Reembolso verificado no meio original",
        c ->
            decisao(c).getTipoVerificacao() == TipoVerificacao.VERIFICADA
                && decisao(c).getMeioReembolso() == MeioReembolso.MEIO_ORIGINAL
                && decisao(c).getElegibilidade() != Elegibilidade.RECUSAR);
    estadoPedido(
        "reembolsoNoMeioOriginalOuEmRevisao",
        "Reembolso no meio original ou em revisão (CH-004)",
        c ->
            decisao(c).getMeioReembolso() == MeioReembolso.MEIO_ORIGINAL
                || decisao(c).disparou("CH-004"));
    estadoPedido(
        "transacaoAProcessar",
        "Transação a processar (não recusada e com tipo definido)",
        c ->
            !decisao(c).isTerminal()
                && decisao(c).getElegibilidade() != null
                && decisao(c).getElegibilidade() != Elegibilidade.RECUSAR
                && decisao(c).getTipoTransacao() != null
                && decisao(c).getTipoTransacao() != TipoTransacao.NENHUMA);
    estadoPedido(
        "baseValorDefinida", "Base do valor definida", c -> decisao(c).getBaseValor() != null);
    estadoPedido(
        "valoresDosArtigos",
        "Há artigos elegíveis com valor",
        c ->
            c.decisoesArtigos().stream()
                .anyMatch(a -> elegivel(a) && a.getValorDevolucao() != null));
    estadoPedido(
        "valorDevolucaoMaiorQueTroca",
        "O valor devolvido é maior do que o preço da troca",
        c ->
            decisao(c).getValorDevolucao() != null
                && decisao(c).getValorDevolucao().compareTo(precoTroca(c)) > 0);

    estadoArtigo(
        "artigoAceite",
        "Artigo aceite ou em revisão",
        c -> c.decisaoArtigo() != null && elegivel(c.decisaoArtigo()));
    estadoArtigo(
        "bodywearAceite",
        "Bodywear aceite (PC-007)",
        c -> bodywear(c) && c.decisaoArtigo() != null && c.decisaoArtigo().disparou("PC-007"));
    estadoArtigo(
        "defeitoFabricoAceite",
        "Artigo com defeito aceite",
        c ->
            estado(c) != null
                && estado(c).isDefeitoFabricoConfirmado()
                && c.decisaoArtigo() != null
                && elegivel(c.decisaoArtigo()));
    estadoArtigo(
        "inspecionado",
        "Artigo inspecionado (CT-008)",
        c -> c.decisaoArtigo() != null && c.decisaoArtigo().disparou("CT-008"));
    estadoArtigo(
        "semDestino",
        "Destino ainda por definir",
        c -> c.decisaoArtigo() != null && c.decisaoArtigo().getDestino() == null);
    estadoArtigo(
        "semBaseEspecifica",
        "Sem base de valor própria do artigo",
        c -> c.decisaoArtigo() != null && c.decisaoArtigo().getBaseValor() == null);
    estadoArtigo(
        "artigoOuPedidoRecusado",
        "Artigo ou pedido recusado",
        c ->
            (c.decisaoArtigo() != null
                    && c.decisaoArtigo().getElegibilidade() == Elegibilidade.RECUSAR)
                || decisao(c).getElegibilidade() == Elegibilidade.RECUSAR);
  }

  // -------------------------------------------------------------------------------------------
  // Camada de incerteza (docs/08): evidências e graus de crença
  // -------------------------------------------------------------------------------------------

  /** Grau de crença da hipótese, no artigo indicado (ou do pedido, se for nulo). */
  private static Optional<GrauCrenca> grau(
      ContextoAvaliacao c, Hipotese hipotese, String artigoId) {
    return c.decisao().getGrausCrenca().stream()
        .filter(g -> g.getHipotese() == hipotese && Objects.equals(g.getArtigoId(), artigoId))
        .findFirst();
  }

  private static ClassificacaoIncerteza classe(
      ContextoAvaliacao c, Hipotese hipotese, String artigoId) {
    return grau(c, hipotese, artigoId).map(GrauCrenca::getClassificacao).orElse(null);
  }

  private static ClassificacaoIncerteza classeDoArtigo(ContextoAvaliacao c, Hipotese hipotese) {
    return classe(c, hipotese, c.artigo().getId());
  }

  private void registarIncerteza() {
    pedido(
        "semComprovativoQueConfirme",
        "Sem comprovativo, ou o comprovativo não confirma a compra (EF-01)",
        c -> comprovativo(c) == null || !comprovativo(c).isConfirmaCompra(),
        c ->
            comprovativo(c) == null
                ? "sem comprovativo"
                : "confirma a compra: " + comprovativo(c).isConfirmaCompra());
    pedido(
        "todosOsArtigosSemEtiquetas",
        "Todos os artigos sem etiquetas (EF-02)",
        c ->
            !c.pedido().getArtigos().isEmpty()
                && c.pedido().getArtigos().stream()
                    .allMatch(
                        a ->
                            a.getEstado() != null
                                && a.getEstado().getEtiquetas() == EstadoEtiquetas.AUSENTES),
        null);
    estadoPedido(
        "estadosMuitoDiferentes",
        "Artigos em estados muito diferentes (EF-03)",
        c ->
            grau(c, Hipotese.FRAUDE, null)
                .map(
                    g -> g.getContribuicoes().stream().anyMatch(k -> k.getCodigo().equals("EF-03")))
                .orElse(false));
    pedido(
        "pedeNumerario",
        "O cliente pede numerário (EF-05)",
        c -> c.pedido().getCliente() != null && c.pedido().getCliente().isPedeNumerario(),
        null);
    artigo(
        "alegaDefeito",
        "O cliente alega um defeito",
        c -> estado(c) != null && estado(c).isAlegaDefeito(),
        null);
    pedido(
        "dataCompraConhecida",
        "Data da compra conhecida",
        c -> c.pedido().getDiasDesdeCompra() != null,
        c -> String.valueOf(c.pedido().getDiasDesdeCompra()));
    estadoPedido(
        "riscoFraudeAlto",
        "Risco de fraude alto",
        c -> classe(c, Hipotese.FRAUDE, null) == ClassificacaoIncerteza.RISCO_ALTO);
    estadoPedido(
        "riscoFraudeMedio",
        "Risco de fraude médio",
        c -> classe(c, Hipotese.FRAUDE, null) == ClassificacaoIncerteza.RISCO_MEDIO);
    pedido(
        "semIndicioFraudeRelevante",
        "Sem indício de fraude significativo ou confirmado registado pelo colaborador",
        c ->
            c.fraudes().stream()
                .noneMatch(
                    f ->
                        f.getNivelRisco() == NivelRisco.SIGNIFICATIVO
                            || f.getNivelRisco() == NivelRisco.CONFIRMADO),
        null);
    artigo(
        "grauUsoConhecido",
        "Grau de uso conhecido",
        c -> estado(c) != null && estado(c).getGrauUso() != null,
        c -> estado(c) == null ? null : String.valueOf(estado(c).getGrauUso()));
    estadoArtigo(
        "revendibilidadeAlta",
        "Grau de revendibilidade alto",
        c -> classeDoArtigo(c, Hipotese.REVENDIBILIDADE) == ClassificacaoIncerteza.REVENDIVEL);
    estadoArtigo(
        "revendibilidadeIndeterminada",
        "Grau de revendibilidade intermédio",
        c ->
            classeDoArtigo(c, Hipotese.REVENDIBILIDADE)
                == ClassificacaoIncerteza.REVENDIBILIDADE_INDETERMINADA);
    estadoArtigo(
        "revendibilidadeBaixa",
        "Grau de revendibilidade baixo",
        c -> classeDoArtigo(c, Hipotese.REVENDIBILIDADE) == ClassificacaoIncerteza.NAO_REVENDIVEL);
    estadoArtigo(
        "defeitoProvavel",
        "Defeito de fabrico provável",
        c -> classeDoArtigo(c, Hipotese.DEFEITO_FABRICO) == ClassificacaoIncerteza.PROPOR_PC006);
    estadoArtigo(
        "defeitoPossivel",
        "Defeito de fabrico possível",
        c -> classeDoArtigo(c, Hipotese.DEFEITO_FABRICO) == ClassificacaoIncerteza.REVER_DEFEITO);
    estadoArtigo(
        "desgasteProvavel",
        "Desgaste provável",
        c -> classeDoArtigo(c, Hipotese.DEFEITO_FABRICO) == ClassificacaoIncerteza.DESGASTE);
    estadoArtigo(
        "semSuspeitaDefeito",
        "Sem defeito de fabrico provável nem possível por decidir",
        c -> {
          ClassificacaoIncerteza classe = classeDoArtigo(c, Hipotese.DEFEITO_FABRICO);
          return classe != ClassificacaoIncerteza.PROPOR_PC006
              && classe != ClassificacaoIncerteza.REVER_DEFEITO;
        });
    estadoPedido(
        "pt004EmRevisao",
        "A PT-004 deixou a devolução em revisão",
        c -> c.decisao().disparouCom("PT-004", Elegibilidade.REVER));
    estadoArtigo(
        "artigoPermitidoOuPorDecidir",
        "Artigo permitido ou ainda sem resultado",
        c ->
            c.decisaoArtigo() != null
                && (c.decisaoArtigo().getElegibilidade() == null
                    || c.decisaoArtigo().getElegibilidade() == Elegibilidade.PERMITIR
                    || c.decisaoArtigo().disparou("IU-50")));
  }
}
