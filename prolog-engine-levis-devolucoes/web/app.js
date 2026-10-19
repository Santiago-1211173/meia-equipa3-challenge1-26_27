/* Interface web do sistema pericial (motor SWI-Prolog).
 *
 * Usa a API REST do próprio servidor (/api/v1): o formulário monta o pedido no mesmo formato JSON
 * da API, "O que falta?" é atualizado a cada alteração, cada grupo de perguntas tem o seu "Porquê?"
 * e, depois de avaliar, a decisão mostra as explicações Como, Porque não e E se.
 */
'use strict';

// ---------------------------------------------------------------------------------------------
// Valores dos enumerados e rótulos
// ---------------------------------------------------------------------------------------------

const ENUMS = {
  FUNCAO: ['GESTAO_LOJA', 'KEY_HOLDER', 'XSTORE_MANAGER', 'LEAD_CASHIER', 'ELEVATED_STYLIST', 'STYLIST'],
  MERCADO: ['EUA', 'CANADA'],
  TIPO_LOJA: ['MAINLINE', 'OUTLET'],
  TIPO_PEDIDO: ['DEVOLUCAO', 'TROCA', 'DEVOLUCAO_OFERTA', 'AJUSTE_PRECO'],
  CANAL: ['MAINLINE', 'OUTLET', 'LEVI_COM', 'LEVI_CA', 'BACKPOCKET', 'FRANQUIA_CANADA', 'GROSSISTA', 'DESCONHECIDO'],
  COMPROVATIVO: ['RECIBO_IMPRESSO', 'RECIBO_DIGITAL', 'CONFIRMACAO_ENCOMENDA', 'RECIBO_OFERTA', 'CONSULTA_TRANSACAO',
                 'FOTOGRAFIA_RECIBO', 'CONSULTA_BACKPOCKET'],
  MEIO: ['CREDITO', 'DEBITO', 'APPLE_PAY', 'GOOGLE_PAY', 'PAYPAL', 'VENMO', 'AFTERPAY', 'INTERAC', 'NUMERARIO', 'CARTAO_OFERTA'],
  CONTA: ['ATIVA', 'ATIVA_CARTAO_PERDIDO', 'ENCERRADA'],
  MARCA: ['LEVIS', 'DOCKERS', 'LS_SIGNATURE', 'BEYOND_YOGA', 'OUTRA'],
  CATEGORIA: ['VESTUARIO', 'ACESSORIO', 'BODYWEAR'],
  USO: ['NAO_USADO', 'USADO', 'LAVADO'],
  ETIQUETAS: ['COLOCADAS', 'SOLTAS', 'AUSENTES'],
  TRANSACAO: ['REEMBOLSO', 'TROCA', 'TROCA_MESMO_ARTIGO', 'CREDITO_LOJA', 'AJUSTE_PRECO'],
  RISCO: ['BAIXO', 'SIGNIFICATIVO', 'CONFIRMADO'],
};

const ROTULOS = {
  GESTAO_LOJA: 'Gestão da Loja', KEY_HOLDER: 'Key Holder', XSTORE_MANAGER: 'XStore Manager',
  LEAD_CASHIER: 'Lead Cashier', ELEVATED_STYLIST: 'Elevated Stylist', STYLIST: 'Stylist',
  EUA: 'Estados Unidos', CANADA: 'Canadá', MAINLINE: 'Mainline', OUTLET: 'Outlet',
  DEVOLUCAO: 'Devolução', TROCA: 'Troca', DEVOLUCAO_OFERTA: 'Devolução de oferta', AJUSTE_PRECO: 'Ajuste de preço',
  LEVI_COM: 'levi.com', LEVI_CA: 'levi.ca', BACKPOCKET: 'BackPocket', FRANQUIA_CANADA: 'Franquia do Canadá',
  GROSSISTA: 'Grossista', DESCONHECIDO: 'Desconhecido',
  RECIBO_IMPRESSO: 'Recibo impresso', RECIBO_DIGITAL: 'Recibo digital', CONFIRMACAO_ENCOMENDA: 'Confirmação de encomenda',
  RECIBO_OFERTA: 'Recibo de oferta', CONSULTA_TRANSACAO: 'Consulta da transação', FOTOGRAFIA_RECIBO: 'Fotografia do recibo',
  CONSULTA_BACKPOCKET: 'Consulta BackPocket',
  CREDITO: 'Cartão de crédito', DEBITO: 'Cartão de débito', APPLE_PAY: 'Apple Pay', GOOGLE_PAY: 'Google Pay', PAYPAL: 'PayPal',
  VENMO: 'Venmo', AFTERPAY: 'Afterpay', INTERAC: 'Interac', NUMERARIO: 'Numerário', CARTAO_OFERTA: 'Cartão de oferta',
  ATIVA: 'Ativa', ATIVA_CARTAO_PERDIDO: 'Ativa, cartão perdido/roubado', ENCERRADA: 'Encerrada',
  LEVIS: "Levi's", DOCKERS: 'Dockers', LS_SIGNATURE: 'Levi Strauss Signature', BEYOND_YOGA: 'Beyond Yoga', OUTRA: 'Outra',
  VESTUARIO: 'Vestuário', ACESSORIO: 'Acessório', BODYWEAR: 'Bodywear',
  NAO_USADO: 'Não usado', USADO: 'Usado', LAVADO: 'Lavado', COLOCADAS: 'Colocadas', SOLTAS: 'Soltas', AUSENTES: 'Sem etiquetas',
  REEMBOLSO: 'Reembolso', TROCA_MESMO_ARTIGO: 'Troca pelo mesmo artigo', CREDITO_LOJA: 'Crédito de loja', NENHUMA: 'Nenhuma',
  BAIXO: 'Baixo', SIGNIFICATIVO: 'Significativo', CONFIRMADO: 'Confirmado',
  PERMITIR: 'Permitir', REVER: 'Rever', ENCAMINHAR: 'Encaminhar', RECUSAR: 'Recusar',
  NAO_DETERMINADA: 'Não determinada', VERIFICADA: 'Verificada', AS_CEGAS: 'Às cegas',
  VALOR_PAGO: 'valor pago', PRECO_ATUAL: 'preço atual', VALOR_PROMOCIONAL: 'valor promocional', VALOR_ESCALAO: 'valor do escalão',
  VALOR_POS: 'valor calculado pelo POS', PVP_ORIGINAL: 'PVP original',
  MEIO_ORIGINAL: 'Meio de pagamento original', CARTAO_OFERTA_ELETRONICO: 'Cartão de oferta eletrónico',
  MEIO_ALTERNATIVO: 'Meio alternativo (após recusa)', APLICACAO_PAGAMENTO: 'Aplicação de pagamento',
  NENHUMA_APROVACAO: 'Nenhuma', RESPONSAVEL_SENIOR: 'Responsável sénior', DISTRICT_AREA: 'District / Area Manager',
  POS: 'POS', PAYPAL_VENMO: 'Fluxo PayPal / Venmo', VERIFONE_INTERAC: 'VeriFone Interac', DANO: 'Processo de dano',
  RISCO_BIOLOGICO: 'Isolamento por risco biológico', AREA_VENDAS: 'Área de vendas', SALDOS: 'Saldos',
  REETIQUETAR: 'Reetiquetar', BAIXA_DANO: 'Baixa por dano', DEVOLUCAO_CLIENTE: 'Devolução ao cliente',
};

const rotulo = (v) => (v === null || v === undefined) ? '—' : (ROTULOS[v] || String(v));

// Valores possíveis de cada conclusão, para o "Porque não?"
const VALORES_SAIDA = {
  'OUT-001': ['PERMITIR', 'REVER', 'ENCAMINHAR', 'RECUSAR'],
  'OUT-002': ['REEMBOLSO', 'TROCA', 'TROCA_MESMO_ARTIGO', 'CREDITO_LOJA', 'AJUSTE_PRECO', 'NENHUMA'],
  'OUT-004': ['MEIO_ORIGINAL', 'CARTAO_OFERTA', 'MEIO_ALTERNATIVO', 'APLICACAO_PAGAMENTO', 'CREDITO_LOJA'],
  'OUT-005': ['NENHUMA', 'XSTORE_MANAGER', 'RESPONSAVEL_SENIOR', 'DISTRICT_AREA'],
  'OUT-006': ['POS', 'BACKPOCKET', 'AFTERPAY', 'PAYPAL_VENMO', 'VERIFONE_INTERAC', 'FRANQUIA_CANADA'],
  'OUT-007': ['AREA_VENDAS', 'SALDOS', 'REETIQUETAR', 'BAIXA_DANO', 'RISCO_BIOLOGICO', 'DEVOLUCAO_CLIENTE'],
};
const NOMES_SAIDA = {
  'OUT-001': 'Elegibilidade', 'OUT-002': 'Tipo de transação', 'OUT-003': 'Valor da devolução', 'OUT-004': 'Meio de reembolso',
  'OUT-005': 'Aprovação', 'OUT-006': 'Processo obrigatório', 'OUT-007': 'Destino do produto', 'OUT-008': 'Documentação',
};

// ---------------------------------------------------------------------------------------------
// Definição do formulário (as perguntas, agrupadas pelos dados de entrada IN-001..IN-010)
// ---------------------------------------------------------------------------------------------

const online = (p) => ['LEVI_COM', 'LEVI_CA'].includes(obter(p, 'compraOriginal.canal'));
const meio = (p) => obter(p, 'compraOriginal.pagamento.meio');

const SECOES = [
  { id: 'colaborador', titulo: 'Colaborador que processa', dado: 'HS-006', campos: [
    { c: 'colaborador.funcao', r: 'Função', t: 'enum', e: 'FUNCAO', rerender: true },
    { c: 'colaborador.aprovadoPeloDM', r: 'Aprovado pelo District Manager', t: 'bool',
      visivel: (p) => ['LEAD_CASHIER', 'ELEVATED_STYLIST'].includes(obter(p, 'colaborador.funcao')) },
    { c: 'colaborador.id', r: 'Identificador', t: 'texto' },
    { c: 'colaborador.idCredencialPOS', r: 'Credencial de POS', t: 'texto' },
  ] },
  { id: 'loja', titulo: 'Loja recetora', dado: 'IN-001', campos: [
    { c: 'loja.mercado', r: 'Mercado', t: 'enum', e: 'MERCADO', dado: 'IN-001' },
    { c: 'loja.tipoLoja', r: 'Tipo de loja', t: 'enum', e: 'TIPO_LOJA', dado: 'IN-002' },
    { c: 'loja.codigo', r: 'Código da loja', t: 'texto' },
    { c: 'loja.coberturaLojaUnica', r: 'Cobertura de loja única (SSC)', t: 'bool' },
    { c: 'loja.skusSortido', r: 'SKUs no sortido da loja (separados por vírgulas)', t: 'lista', largo: true },
  ] },
  { id: 'pedido', titulo: 'Pedido do cliente', dado: 'IN-005', campos: [
    { c: 'tipoPedido', r: 'O que pede o cliente', t: 'enum', e: 'TIPO_PEDIDO', rerender: true },
    { c: 'dataPedido', r: 'Data do pedido', t: 'data', dado: 'IN-006' },
    { c: 'id', r: 'Referência do pedido', t: 'texto' },
  ] },
  { id: 'compra', titulo: 'Compra original', dado: 'IN-003', campos: [
    { c: 'compraOriginal.canal', r: 'Canal de compra', t: 'enum', e: 'CANAL', rerender: true },
    { c: 'compraOriginal.dataCompra', r: 'Data da compra', t: 'data', dado: 'IN-006' },
    { c: 'compraOriginal.dataEnvio', r: 'Data de envio da encomenda', t: 'data', dado: 'IN-006', visivel: online },
    { c: 'compraOriginal.idTransacao', r: 'Transação / encomenda', t: 'texto' },
    { c: 'compraOriginal.idStylistVenda', r: 'Stylist da venda original', t: 'texto' },
    { c: 'compraOriginal.quantidadeComprada', r: 'Quantidade comprada', t: 'numero' },
    { c: 'compraOriginal.promocaoEscaloes', r: 'Comprado numa promoção por escalões', t: 'bool' },
    { c: 'compraOriginal.ajustePrecoAplicado', r: 'Já teve um ajuste de preço', t: 'bool',
      visivel: (p) => p.tipoPedido === 'AJUSTE_PRECO' },
  ] },
  { id: 'online', titulo: 'Encomenda online', dado: 'CH-002', visivel: online, campos: [
    { c: 'compraOriginal.encomendaEncontrada', r: 'A encomenda foi encontrada', t: 'bool' },
    { c: 'portalOnlineDisponivel', r: 'O portal de devoluções online está disponível', t: 'bool', omissao: true },
    { c: 'politicaPermiteAsCegasOnline', r: 'A política permite a devolução online às cegas', t: 'bool' },
  ] },
  { id: 'comprovativo', titulo: 'Comprovativo de compra', dado: 'IN-004', opcional: 'comprovativo',
    textoOpcional: 'O cliente apresenta comprovativo de compra', campos: [
    { c: 'comprovativo.tipo', r: 'Tipo de comprovativo', t: 'enum', e: 'COMPROVATIVO' },
    { c: 'comprovativo.confirmaCompra', r: 'Confirma a compra', t: 'bool' },
    { c: 'comprovativo.reciboOriginal', r: 'É o recibo original', t: 'bool' },
    { c: 'comprovativo.clienteMantemRecibo', r: 'O cliente fica com o recibo', t: 'bool' },
    { c: 'comprovativo.incluiOutrosArtigos', r: 'O recibo inclui outros artigos', t: 'bool' },
  ] },
  { id: 'pagamento', titulo: 'Pagamento original', dado: 'IN-009', opcional: 'compraOriginal.pagamento',
    textoOpcional: 'O meio de pagamento é conhecido', campos: [
    { c: 'compraOriginal.pagamento.meio', r: 'Meio de pagamento', t: 'enum', e: 'MEIO', rerender: true },
    { c: 'compraOriginal.pagamento.valorPago', r: 'Valor pago', t: 'numero' },
    { c: 'compraOriginal.pagamento.estadoConta', r: 'Estado da conta do cartão', t: 'enum', e: 'CONTA',
      visivel: (p) => ['CREDITO', 'DEBITO', 'APPLE_PAY', 'GOOGLE_PAY'].includes(meio(p)) },
    { c: 'compraOriginal.pagamento.reembolsoOriginalRecusado', r: 'O reembolso ao meio original já foi recusado', t: 'bool' },
    { c: 'compraOriginal.pagamento.cartaoFisicoPresente', r: 'Apresenta o mesmo cartão Interac', t: 'bool',
      visivel: (p) => meio(p) === 'INTERAC' },
    { c: 'compraOriginal.pagamento.acessoAplicacaoPagamento', r: 'Consegue aceder à aplicação de pagamento', t: 'bool',
      omissao: true, visivel: (p) => ['PAYPAL', 'VENMO'].includes(meio(p)) },
  ] },
  { id: 'artigos', titulo: 'Artigos devolvidos', dado: 'IN-007', lista: 'artigos', item: 'Artigo' },
  { id: 'troca', titulo: 'Artigos levados na troca', dado: 'IN-005', lista: 'artigosTroca', item: 'Artigo de troca',
    visivel: (p) => p.tipoPedido === 'TROCA' },
  { id: 'cliente', titulo: 'Cliente', dado: 'EX-002', campos: [
    { c: 'cliente.forneceDados', r: 'Fornece dados pessoais', t: 'bool', omissao: true },
    { c: 'cliente.barreiraLinguistica', r: 'Há barreira linguística', t: 'bool' },
    { c: 'cliente.contestaResultado', r: 'Contesta o resultado padrão', t: 'bool' },
    { c: 'cliente.agitado', r: 'Está irritado ou a causar perturbação', t: 'bool' },
  ] },
  { id: 'excecao', titulo: 'Pedido de exceção', dado: 'EX-001', opcional: 'pedidoExcecao',
    textoOpcional: 'O cliente pede uma exceção à política', campos: [
    { c: 'pedidoExcecao.motivo', r: 'Motivo', t: 'texto', largo: true },
    { c: 'pedidoExcecao.resolucaoPedida', r: 'Resolução pedida', t: 'enum', e: 'TRANSACAO' },
    { c: 'pedidoExcecao.aprovada', r: 'Decisão da gestão', t: 'bool3', textos: ['Pendente', 'Aprovada', 'Recusada'] },
    { c: 'pedidoExcecao.exigeMeioProibido', r: 'Exige um meio de pagamento proibido', t: 'bool' },
    { c: 'pedidoExcecao.exigeSkuIncorreto', r: 'Exige um SKU incorreto', t: 'bool' },
    { c: 'pedidoExcecao.envolveProdutoExcluido', r: 'Envolve um produto excluído', t: 'bool' },
    { c: 'pedidoExcecao.contornaProcessoObrigatorio', r: 'Contorna um processo obrigatório', t: 'bool' },
    { c: 'pedidoExcecao.concluivelNoSistema', r: 'O resultado pode ser concluído no sistema', t: 'bool', omissao: true },
    { c: 'pedidoExcecao.preocupacaoCliente', r: 'Preocupação do cliente', t: 'texto', largo: true },
  ] },
  { id: 'fraude', titulo: 'Indícios de fraude', dado: 'EX-008', lista: 'indicadoresFraude', item: 'Indício' },
];

const bodywear = (a) => (a.produto || {}).categoria === 'BODYWEAR';

const CAMPOS_LISTA = {
  artigos: [
    { g: 'Produto (IN-007)', c: 'produto.sku', r: 'SKU', t: 'texto' },
    { c: 'produto.skuReconhecidoPOS', r: 'SKU reconhecido no POS', t: 'bool' },
    { c: 'produto.marca', r: 'Marca', t: 'enum', e: 'MARCA' },
    { c: 'produto.categoria', r: 'Categoria', t: 'enum', e: 'CATEGORIA', rerender: true },
    { c: 'produto.pvpOriginal', r: 'PVP original', t: 'numero' },
    { c: 'produto.precoAtual', r: 'Preço de venda atual', t: 'numero' },
    { c: 'produto.produtoFranquia', r: 'Produto da franquia do Canadá', t: 'bool' },
    { c: 'produto.grossista', r: 'Produto grossista', t: 'bool' },
    { c: 'produto.vendidoNaLoja', r: 'Vendido nesta loja', t: 'bool' },
    { c: 'produto.emSaldo', r: 'Já está em saldo', t: 'bool' },
    { g: 'Compra do artigo', c: 'precoPago', r: 'Valor pago', t: 'numero' },
    { c: 'quantidade', r: 'Quantidade', t: 'numero' },
    { c: 'valorCalculadoPos', r: 'Valor calculado pelo POS', t: 'numero' },
    { c: 'entreCanais', r: 'Comprado noutro canal ou loja', t: 'bool', dado: 'IN-003' },
    { g: 'Estado (IN-008)', c: 'estado.condicaoUso', r: 'Estado de uso', t: 'enum', e: 'USO', dado: 'IN-008' },
    { c: 'estado.etiquetas', r: 'Etiquetas', t: 'enum', e: 'ETIQUETAS' },
    { c: 'estado.personalizado', r: 'Personalizado', t: 'bool' },
    { c: 'estado.alterado', r: 'Alterado', t: 'bool' },
    { c: 'estado.embainhado', r: 'Embainhado', t: 'bool' },
    { c: 'estado.defeitoFabricoConfirmado', r: 'Defeito de fabrico confirmado', t: 'bool' },
    { c: 'estado.sujoOuInseguro', r: 'Sujo, contaminado ou inseguro', t: 'bool' },
    { c: 'estado.danificado', r: 'Tem dano visível', t: 'bool' },
    { c: 'estado.etiquetaPrecoCorreta', r: 'Etiqueta de preço correta', t: 'bool', omissao: true },
    { c: 'estado.rfidCorreto', r: 'RFID correto', t: 'bool', omissao: true },
    { c: 'estado.embalagemIntacta', r: 'Embalagem original intacta', t: 'bool', visivel: bodywear },
    { c: 'estado.conjuntoCompleto', r: 'Conjunto completo', t: 'bool', omissao: true, visivel: bodywear },
    { g: 'Revenda (IN-010)', c: 'revendivel', r: 'Pode ser verificado, reetiquetado e revendido', t: 'bool3',
      textos: ['Ainda não avaliado', 'Sim', 'Não'], dado: 'IN-010', largo: true },
  ],
  artigosTroca: [
    { c: 'produto.sku', r: 'SKU do artigo levado', t: 'texto' },
    { c: 'precoVenda', r: 'Preço de venda', t: 'numero' },
    { c: 'apenasMudaTamanho', r: 'Muda apenas o tamanho', t: 'bool' },
  ],
  indicadoresFraude: [
    { c: 'descricao', r: 'Descrição', t: 'texto' },
    { c: 'nivelRisco', r: 'Nível de risco', t: 'enum', e: 'RISCO' },
  ],
};

const NOVOS_ITENS = {
  artigos: (i) => ({
    id: `A-${i + 1}`, quantidade: 1,
    produto: { sku: `501-A-${i + 1}`, skuReconhecidoPOS: true, marca: 'LEVIS', categoria: 'VESTUARIO', vendidoNaLoja: true },
    estado: { condicaoUso: 'NAO_USADO', etiquetas: 'COLOCADAS' },
  }),
  artigosTroca: () => ({ produto: { sku: '', skuReconhecidoPOS: true }, apenasMudaTamanho: true }),
  indicadoresFraude: () => ({ descricao: '', nivelRisco: 'SIGNIFICATIVO' }),
};

function pedidoNovo() {
  const hoje = new Date().toISOString().slice(0, 10);
  return {
    id: `WEB-${Date.now().toString(36).toUpperCase()}`,
    dataPedido: hoje,
    tipoPedido: 'DEVOLUCAO',
    loja: { codigo: 'LOJA-1', mercado: 'EUA', tipoLoja: 'MAINLINE' },
    colaborador: { id: 'C-1', funcao: 'KEY_HOLDER', idCredencialPOS: 'POS-C-1' },
    cliente: {},
    compraOriginal: { canal: 'MAINLINE', dataCompra: hoje, pagamento: { meio: 'CREDITO', estadoConta: 'ATIVA' } },
    comprovativo: { tipo: 'RECIBO_IMPRESSO', confirmaCompra: true, reciboOriginal: true },
    artigos: [NOVOS_ITENS.artigos(0)],
    artigosTroca: [],
    indicadoresFraude: [],
  };
}

// ---------------------------------------------------------------------------------------------
// Estado
// ---------------------------------------------------------------------------------------------

let pedido = pedidoNovo();
let avaliacao = null;          // última decisão (DecisaoResponse)
let pedidoAvaliado = null;     // JSON do pedido avaliado (para saber se ficou desatualizada)
let catalogo = [];             // /api/v1/regras
let temporizadorFalta = null;

const $ = (s, el = document) => el.querySelector(s);
const $$ = (s, el = document) => [...el.querySelectorAll(s)];
const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

function partes(caminho) { return caminho.replace(/\[(\d+)\]/g, '.$1').split('.'); }
function obter(o, caminho) { return partes(caminho).reduce((a, k) => (a == null ? undefined : a[k]), o); }
function definir(o, caminho, valor) {
  const ps = partes(caminho);
  let a = o;
  for (let i = 0; i < ps.length - 1; i++) {
    if (a[ps[i]] == null || typeof a[ps[i]] !== 'object') a[ps[i]] = /^\d+$/.test(ps[i + 1]) ? [] : {};
    a = a[ps[i]];
  }
  const ultimo = ps[ps.length - 1];
  if (valor === undefined) delete a[ultimo]; else a[ultimo] = valor;
}

//  O pedido a enviar: sem textos vazios nem campos por preencher.
function pedidoParaEnviar() {
  const limpar = (v) => {
    if (Array.isArray(v)) return v.map(limpar);
    if (v && typeof v === 'object') {
      const r = {};
      for (const [k, x] of Object.entries(v)) {
        if (x === '' || x === undefined) continue;
        r[k] = limpar(x);
      }
      return r;
    }
    return v;
  };
  return limpar(pedido);
}

// ---------------------------------------------------------------------------------------------
// API
// ---------------------------------------------------------------------------------------------

async function api(metodo, caminho, corpo) {
  const resposta = await fetch(caminho, {
    method: metodo,
    headers: corpo === undefined ? { Accept: 'application/json' } : { 'Content-Type': 'application/json', Accept: 'application/json' },
    body: corpo === undefined ? undefined : JSON.stringify(corpo),
  });
  const texto = await resposta.text();
  let dados = null;
  try { dados = texto ? JSON.parse(texto) : null; } catch { dados = { detail: texto }; }
  if (!resposta.ok) {
    const erro = new Error((dados && (dados.detail || dados.message)) || resposta.statusText);
    erro.estado = resposta.status;
    erro.dados = dados;
    throw erro;
  }
  return dados;
}

// ---------------------------------------------------------------------------------------------
// Formulário
// ---------------------------------------------------------------------------------------------

function renderFormulario() {
  const form = $('#formulario');
  const aberto = document.activeElement && document.activeElement.dataset ? document.activeElement.dataset.caminho : null;
  form.innerHTML = '';
  for (const s of SECOES) {
    if (s.visivel && !s.visivel(pedido)) continue;
    const secao = document.createElement('section');
    secao.className = 'secao';
    secao.innerHTML = `<header><h2>${esc(s.titulo)}</h2><span class="chip">${esc(s.dado)}</span>
      <button type="button" class="ligacao" data-porque="${esc(s.dado)}">Porquê?</button></header>`;

    if (s.opcional) {
      const presente = obter(pedido, s.opcional) != null;
      const linha = document.createElement('label');
      linha.className = 'interruptor';
      linha.innerHTML = `<input type="checkbox" ${presente ? 'checked' : ''}> <span>${esc(s.textoOpcional)}</span>`;
      linha.querySelector('input').addEventListener('change', (ev) => {
        definir(pedido, s.opcional, ev.target.checked ? {} : null);
        alterado(true);
      });
      secao.append(linha);
      if (!presente) { form.append(secao); continue; }
    }

    const corpo = document.createElement('div');
    corpo.className = 'corpo-secao';
    if (s.lista) renderLista(corpo, s);
    else for (const f of s.campos) {
      if (f.visivel && !f.visivel(pedido)) continue;
      corpo.append(renderCampo(f, f.c));
    }
    secao.append(corpo);
    form.append(secao);
  }
  if (aberto) { const el = $(`[data-caminho="${CSS.escape(aberto)}"] input, [data-caminho="${CSS.escape(aberto)}"] select`, form); if (el) el.focus(); }
  marcarEmFalta(ultimaFalta);
}

function renderLista(corpo, s) {
  const itens = obter(pedido, s.lista) || [];
  itens.forEach((item, i) => {
    const caixa = document.createElement('div');
    caixa.className = 'item-lista';
    const nome = s.lista === 'artigos' ? (item.id || `${s.item} ${i + 1}`) : `${s.item} ${i + 1}`;
    caixa.innerHTML = `<header><h3>${esc(nome)}</h3><button type="button" class="ligacao">Remover</button></header>`;
    caixa.querySelector('button').addEventListener('click', () => {
      itens.splice(i, 1);
      alterado(true);
    });
    for (const f of CAMPOS_LISTA[s.lista]) {
      if (f.visivel && !f.visivel(item)) continue;
      if (f.g) {
        const t = document.createElement('div');
        t.className = 'subtitulo-grupo';
        t.textContent = f.g;
        caixa.append(t);
      }
      caixa.append(renderCampo(f, `${s.lista}[${i}].${f.c}`));
    }
    corpo.append(caixa);
  });
  if (!itens.length && s.lista === 'indicadoresFraude') {
    const p = document.createElement('p');
    p.className = 'nota';
    p.style.gridColumn = '1 / -1';
    p.style.margin = '0';
    p.textContent = 'Sem indícios registados. Só um indício significativo ou confirmado suspende a transação (EX-008).';
    corpo.append(p);
  }
  const mais = document.createElement('button');
  mais.type = 'button';
  mais.className = 'botao secundario acrescentar';
  mais.textContent = `+ ${s.item}`;
  mais.addEventListener('click', () => {
    if (!Array.isArray(obter(pedido, s.lista))) definir(pedido, s.lista, []);
    const lista = obter(pedido, s.lista);
    lista.push(NOVOS_ITENS[s.lista](lista.length));
    alterado(true);
  });
  corpo.append(mais);
}

function renderCampo(f, caminho) {
  const valor = obter(pedido, caminho);
  const campo = document.createElement('label');
  campo.className = `campo ${f.t === 'bool' ? 'bool' : ''} ${f.largo ? 'largo' : ''}`;
  campo.dataset.caminho = caminho;
  const porque = f.dado ? ` <button type="button" class="ligacao" data-porque="${esc(f.dado)}">porquê?</button>` : '';
  let controlo;
  switch (f.t) {
    case 'enum':
      controlo = `<select><option value="">—</option>${ENUMS[f.e].map((v) =>
        `<option value="${v}" ${v === valor ? 'selected' : ''}>${esc(rotulo(v))}</option>`).join('')}</select>`;
      break;
    case 'bool': {
      const marcado = valor === undefined || valor === null ? !!f.omissao : !!valor;
      controlo = `<input type="checkbox" ${marcado ? 'checked' : ''}>`;
      break;
    }
    case 'bool3': {
      const [nada, sim, nao] = f.textos || ['—', 'Sim', 'Não'];
      const atual = valor === true ? 'true' : valor === false ? 'false' : '';
      controlo = `<select><option value="" ${atual === '' ? 'selected' : ''}>${esc(nada)}</option>
        <option value="true" ${atual === 'true' ? 'selected' : ''}>${esc(sim)}</option>
        <option value="false" ${atual === 'false' ? 'selected' : ''}>${esc(nao)}</option></select>`;
      break;
    }
    case 'numero':
      controlo = `<input type="number" step="0.01" value="${valor ?? ''}">`;
      break;
    case 'data':
      controlo = `<input type="date" value="${esc(valor ?? '')}">`;
      break;
    case 'lista':
      controlo = `<input type="text" value="${esc(Array.isArray(valor) ? valor.join(', ') : '')}">`;
      break;
    default:
      controlo = `<input type="text" value="${esc(valor ?? '')}">`;
  }
  campo.innerHTML = f.t === 'bool'
    ? `${controlo}<span>${esc(f.r)}${porque}</span>`
    : `<span>${esc(f.r)}${porque}</span>${controlo}`;
  const entrada = campo.querySelector('input, select');
  entrada.dataset.caminho = caminho;
  const evento = (f.t === 'texto' || f.t === 'numero' || f.t === 'lista') ? 'input' : 'change';
  entrada.addEventListener(evento, () => {
    let v;
    switch (f.t) {
      case 'bool': v = entrada.checked; break;
      case 'bool3': v = entrada.value === '' ? undefined : entrada.value === 'true'; break;
      case 'numero': v = entrada.value === '' ? undefined : Number(entrada.value); break;
      case 'lista': v = entrada.value.split(',').map((x) => x.trim()).filter(Boolean); break;
      default: v = entrada.value === '' ? undefined : entrada.value;
    }
    definir(pedido, caminho, v);
    alterado(!!f.rerender);
  });
  return campo;
}

function alterado(redesenhar) {
  if (redesenhar) renderFormulario();
  atualizarDesatualizada();
  clearTimeout(temporizadorFalta);
  temporizadorFalta = setTimeout(verificarFalta, 350);
}

// ---------------------------------------------------------------------------------------------
// O que falta? e Porquê?
// ---------------------------------------------------------------------------------------------

let ultimaFalta = null;
let pedidoFalta = 0;

async function verificarFalta() {
  const n = ++pedidoFalta;
  try {
    const falta = await api('POST', '/api/v1/avaliacoes/dados-em-falta', pedidoParaEnviar());
    if (n !== pedidoFalta) return;
    ultimaFalta = falta;
    renderFalta(falta);
    marcarEmFalta(falta);
  } catch (e) {
    if (n !== pedidoFalta) return;
    $('#painel-falta').innerHTML = `<h2>O que falta?</h2><p class="erro">${esc(e.message)}</p>`;
  }
}

function renderFalta(falta) {
  const resumo = $('#resumo-falta');
  resumo.textContent = falta.resumo;
  resumo.className = `resumo-falta ${falta.completo ? 'completo' : 'incompleto'}`;
  const painel = $('#painel-falta');
  if (!falta.dados.length) {
    painel.innerHTML = '<h2>O que falta?</h2><p class="nota">Nada: todos os dados de que as regras precisam estão indicados.</p>';
    return;
  }
  painel.innerHTML = `<h2>O que falta?</h2><p class="nota">${esc(falta.resumo)}</p>
    <ul class="lista-falta">${falta.dados.map((d) => `<li>
      <span class="${d.obrigatorio ? 'obrigatorio' : 'opcional'}">${d.obrigatorio ? 'OBRIGATÓRIO' : 'PARA DECIDIR'}</span>
      <span><strong>${esc(d.codigo)}</strong> ${esc(d.descricao)}
        <button type="button" class="ligacao" data-ir="${esc(d.caminho)}">ir</button>
        <button type="button" class="ligacao" data-porque="${esc(d.codigo)}">porquê?</button></span></li>`).join('')}</ul>`;
}

function marcarEmFalta(falta) {
  $$('.campo.em-falta, .campo.opcional-falta').forEach((c) => c.classList.remove('em-falta', 'opcional-falta'));
  if (!falta) return;
  for (const d of falta.dados) {
    const campo = document.querySelector(`.campo[data-caminho="${CSS.escape(d.caminho)}"]`);
    if (campo) campo.classList.add(d.obrigatorio ? 'em-falta' : 'opcional-falta');
  }
}

async function mostrarPorque(dado) {
  const painel = $('#painel-porque');
  painel.classList.remove('oculto');
  painel.innerHTML = `<p class="nota">A calcular o porquê de ${esc(dado)}…</p>`;
  try {
    const e = await api('POST', `/api/v1/avaliacoes/porque?dado=${encodeURIComponent(dado)}`, pedidoParaEnviar());
    painel.innerHTML = `<header><h2>Porquê?</h2><span class="chip">${esc(e.dado)}</span>
        <button type="button" class="ligacao" id="fechar-porque">fechar</button></header>
      <p><strong>${esc(e.pergunta)}</strong></p>
      <p class="resumo">${esc(e.resumo)}</p>
      ${e.regrasEmEspera.map((r) => `<div class="espera">
        <div class="titulo">${esc(r.codigoRegra)} ${r.artigoId ? `<span class="chip">${esc(r.artigoId)}</span>` : ''}
          <span class="nota" style="margin:0">${esc(r.nomeRegra.replace(r.codigoRegra, '').trim())}</span></div>
        ${r.conclusoes.length ? `<div class="nota">Concluiria: ${r.conclusoes.map(esc).join(', ')}</div>` : ''}
        ${renderCondicoes(r.condicoesDoDado)}</div>`).join('')}
      <p class="nota">Regras que usam esta resposta: ${e.regrasQueDependem.map(esc).join(', ')}</p>`;
    $('#fechar-porque').addEventListener('click', () => painel.classList.add('oculto'));
    painel.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
  } catch (e) {
    painel.innerHTML = `<p class="erro">${esc(e.message)}</p>`;
  }
}

// ---------------------------------------------------------------------------------------------
// Avaliação e decisão
// ---------------------------------------------------------------------------------------------

async function avaliar() {
  const botao = $('#avaliar');
  botao.disabled = true;
  botao.textContent = 'A avaliar…';
  try {
    const enviado = pedidoParaEnviar();
    avaliacao = await api('POST', '/api/v1/avaliacoes', enviado);
    pedidoAvaliado = JSON.stringify(enviado);
    renderDecisao();
    abrirExplicacao('como');
    renderComoCompleto();
  } catch (e) {
    const erros = (e.dados && e.dados.erros) || [];
    $('#painel-decisao').innerHTML = `<h2>${esc((e.dados && e.dados.title) || 'Não foi possível avaliar')}</h2>
      <p class="erro">${esc(e.message)}</p>${erros.length ? `<ul>${erros.map((x) => `<li>${esc(x)}</li>`).join('')}</ul>` : ''}`;
  } finally {
    botao.disabled = false;
    botao.textContent = 'Avaliar pedido';
  }
}

function atualizarDesatualizada() {
  const aviso = $('#aviso-desatualizada');
  if (!aviso || !pedidoAvaliado) return;
  aviso.classList.toggle('oculto', JSON.stringify(pedidoParaEnviar()) === pedidoAvaliado);
}

function botaoComo(codigo, artigo) {
  return `<button type="button" class="ligacao" data-como="${codigo}" ${artigo ? `data-artigo="${esc(artigo)}"` : ''}>Como?</button>`;
}
function botaoPorqueNao(codigo, artigo) {
  return `<button type="button" class="ligacao" data-pn="${codigo}" ${artigo ? `data-artigo="${esc(artigo)}"` : ''}>Porque não…?</button>`;
}

const moeda = (v) => (v === null || v === undefined) ? '—' : Number(v).toFixed(2);

function renderDecisao() {
  const d = avaliacao;
  const saida = (codigo, valor, extra = '') => `<div class="saida">
      <div class="codigo">${codigo}</div><div class="nome">${NOMES_SAIDA[codigo]}</div>
      <div class="valor ${valor === '—' ? 'nulo' : ''}">${esc(valor)}${extra}</div>
      ${botaoComo(codigo)} ${VALORES_SAIDA[codigo] ? botaoPorqueNao(codigo) : ''}</div>`;
  const doc = Object.entries(d.documentacao || {}).filter(([, v]) => v !== null && v !== false && v !== '');
  const nomesDoc = { assinaturaCliente: 'Assinatura do cliente', assinaturaProcessador: 'Assinatura do processador',
    assinaturaTestemunha: 'Testemunha', idStylistAtribuido: 'Stylist atribuído', reciboAgrafado: 'Recibo agrafado',
    notaRecibo: 'Nota do recibo', retencaoAte: 'Retenção até', registoExcecao: 'Registo da exceção' };

  $('#painel-decisao').innerHTML = `
    <p id="aviso-desatualizada" class="desatualizada oculto">O pedido foi alterado depois desta avaliação. Avalie de novo para atualizar a decisão.</p>
    <div class="decisao-topo">
      <div><div class="rotulo">OUT-001 · Elegibilidade do pedido ${esc(d.pedidoId)}</div>
        <span class="selo grande ${esc(d.elegibilidade)}">${esc(rotulo(d.elegibilidade))}</span></div>
      <div class="rotulo">Verificação: <strong>${esc(rotulo(d.tipoVerificacao))}</strong><br>
        ${d.terminal ? 'Fluxo terminado por uma paragem obrigatória<br>' : ''}${d.excecaoRecusada ? 'Exceção recusada' : ''}</div>
      <div class="acoes-saida">${botaoComo('OUT-001')} ${botaoPorqueNao('OUT-001')}</div>
    </div>
    <div class="saidas">
      ${saida('OUT-002', rotulo(d.tipoTransacao))}
      ${saida('OUT-003', d.valorDevolucao === null ? '—' : moeda(d.valorDevolucao), d.baseValor ? ` <span class="nota">(${esc(rotulo(d.baseValor))})</span>` : '')}
      ${saida('OUT-004', rotulo(d.meioReembolso))}
      ${saida('OUT-005', d.aprovacao === 'NENHUMA' ? 'Nenhuma' : rotulo(d.aprovacao))}
      ${saida('OUT-006', rotulo(d.processo))}
    </div>
    <div class="bloco"><h3>Resultado por artigo</h3>
      <table><thead><tr><th>Artigo</th><th>OUT-001</th><th>OUT-002</th><th>OUT-003</th><th>OUT-007 Destino</th><th></th></tr></thead>
      <tbody>${d.artigos.map((a) => `<tr>
        <td><strong>${esc(a.artigoId)}</strong>${a.terminal ? '<div class="nota" style="margin:0">paragem</div>' : ''}</td>
        <td><span class="selo ${esc(a.elegibilidade || '')}">${esc(rotulo(a.elegibilidade))}</span></td>
        <td>${esc(rotulo(a.tipoTransacao))}</td>
        <td>${moeda(a.valorDevolucao)}${a.baseValor ? `<div class="nota" style="margin:0">${esc(rotulo(a.baseValor))}</div>` : ''}</td>
        <td>${esc(rotulo(a.destino))}${a.descontoSaldo ? ` (−${a.descontoSaldo}%)` : ''}</td>
        <td>${botaoComo('OUT-007', a.artigoId)}<br>${botaoPorqueNao('OUT-007', a.artigoId)}</td></tr>`).join('')}
      </tbody></table></div>
    ${doc.length ? `<div class="bloco"><h3>OUT-008 · Documentação ${botaoComo('OUT-008')}</h3><dl class="documentacao">
      ${doc.map(([k, v]) => `<dt>${esc(nomesDoc[k] || k)}</dt><dd>${esc(v === true ? 'Sim' : v)}</dd>`).join('')}</dl></div>` : ''}
    ${d.regrasAValidar.length ? `<div class="bloco"><h3>Comportamento provisório</h3>
      <p class="nota">Estas regras dispararam com um comportamento ainda a validar pela operação (ADR 0003):</p>
      <div class="lista-codigos">${d.regrasAValidar.map((c) => `<span class="etiqueta-validar">${esc(c)}</span>`).join('')}</div></div>` : ''}
    <p class="nota">Avaliação ${esc(d.avaliacaoId)} · ${esc(d.avaliadaEm)} · ${esc(d.versaoBaseConhecimento)}</p>`;
  $('#painel-explicacoes').classList.remove('oculto');
  renderPorqueNaoFormulario();
  renderESe();
}

// ---------------------------------------------------------------------------------------------
// Explicações
// ---------------------------------------------------------------------------------------------

function abrirExplicacao(nome) {
  $$('.sep-int').forEach((b) => b.classList.toggle('ativo', b.dataset.exp === nome));
  $$('.exp').forEach((e) => e.classList.toggle('oculto', e.id !== `exp-${nome}`));
}

function renderCondicoes(condicoes) {
  if (!condicoes || !condicoes.length) return '';
  return `<ul class="condicoes">${condicoes.map((c) => {
    const marca = c.cumprida === true ? '<span class="sim">✔</span>' : c.cumprida === false ? '<span class="nao">✘</span>' : '<span>?</span>';
    return `<li>${marca}<span>${esc(c.descricao)}${c.artigoId ? ` <span class="chip">${esc(c.artigoId)}</span>` : ''}
      ${c.valor ? `<div class="valor">${esc(c.valor)}</div>` : ''}</span></li>`;
  }).join('')}</ul>`;
}

function renderPassos(passos) {
  return `<ol class="passos">${passos.map((p) => `<li class="passo">
    <span class="n">${p.ordem}</span><span class="modulo">${esc(p.modulo)}</span>
    <div><div class="titulo">${esc(p.codigoRegra)} ${p.artigoId ? `<span class="chip">${esc(p.artigoId)}</span>` : ''}
      ${p.resultado ? `<span class="selo ${esc(p.resultado)}">${esc(rotulo(p.resultado))}</span>` : ''}
      ${p.aValidar ? '<span class="etiqueta-validar">a validar</span>' : ''}</div>
      <div class="mensagem">${esc(p.mensagem)}</div></div></li>`).join('')}</ol>`;
}

async function renderComoCompleto() {
  const alvo = $('#exp-como');
  try {
    const e = await api('GET', `/api/v1/avaliacoes/${avaliacao.avaliacaoId}/explicacoes/como`);
    alvo.innerHTML = `<p class="resumo">${esc(e.resumo)}</p>
      <p class="nota">Módulos percorridos: ${e.modulosPercorridos.map(esc).join(' → ')}</p>${renderPassos(e.passos)}`;
  } catch (err) { alvo.innerHTML = `<p class="erro">${esc(err.message)}</p>`; }
}

async function mostrarComoConclusao(codigo, artigo) {
  abrirExplicacao('como');
  const alvo = $('#exp-como');
  alvo.innerHTML = '<p class="nota">A calcular…</p>';
  try {
    const q = new URLSearchParams({ conclusao: codigo });
    if (artigo) q.set('artigo', artigo);
    const e = await api('GET', `/api/v1/avaliacoes/${avaliacao.avaliacaoId}/explicacoes/como?${q}`);
    alvo.innerHTML = `<button type="button" class="ligacao" id="ver-caminho-completo">← caminho completo</button>
      <h3 style="margin:8px 0">Como se concluiu ${esc(codigo)} · ${esc(NOMES_SAIDA[codigo])}${artigo ? ` do artigo ${esc(artigo)}` : ''}</h3>
      <p class="resumo">${esc(e.resumo)}</p>
      ${e.caminho.length ? `<h4>Alterações, por ordem</h4><ol>${e.caminho.map((c) => `<li><code>${esc(c)}</code></li>`).join('')}</ol>` : ''}
      ${e.condicoes.length ? `<h4>Factos que levaram ${esc(e.regra)} a disparar</h4>${renderCondicoes(e.condicoes)}` : ''}`;
    $('#ver-caminho-completo').addEventListener('click', renderComoCompleto);
  } catch (err) { alvo.innerHTML = `<p class="erro">${esc(err.message)}</p>`; }
}

function renderPorqueNaoFormulario() {
  const alvo = $('#exp-porque-nao');
  const artigos = avaliacao.artigos.map((a) => a.artigoId);
  const opcoesArtigo = `<option value="">(pedido)</option>${artigos.map((a) => `<option>${esc(a)}</option>`).join('')}`;
  const ids = [...new Set(catalogo.map((r) => r.id))];
  alvo.innerHTML = `
    <div class="formulario-linha">
      <label>Conclusão<select id="pn-codigo">${Object.keys(VALORES_SAIDA).map((c) => `<option value="${c}">${c} · ${NOMES_SAIDA[c]}</option>`).join('')}</select></label>
      <label>Valor esperado<select id="pn-valor"></select></label>
      <label>Artigo<select id="pn-artigo">${opcoesArtigo}</select></label>
      <button type="button" class="botao secundario" id="pn-conclusao">Porque não?</button>
    </div>
    <div class="ou">ou, para uma regra</div>
    <div class="formulario-linha">
      <label>Regra<select id="pn-regra">${ids.map((i) => `<option>${esc(i)}</option>`).join('')}</select></label>
      <span></span>
      <label>Artigo<select id="pn-regra-artigo">${opcoesArtigo}</select></label>
      <button type="button" class="botao secundario" id="pn-por-regra">Porque não?</button>
    </div>
    <div id="pn-resultado"></div>`;
  const atualizarValores = () => {
    $('#pn-valor').innerHTML = VALORES_SAIDA[$('#pn-codigo').value].map((v) => `<option value="${v}">${esc(rotulo(v))}</option>`).join('');
  };
  $('#pn-codigo').addEventListener('change', atualizarValores);
  atualizarValores();
  $('#pn-conclusao').addEventListener('click', () =>
    mostrarPorqueNao({ conclusao: `${$('#pn-codigo').value}:${$('#pn-valor').value}`, artigo: $('#pn-artigo').value }));
  $('#pn-por-regra').addEventListener('click', () =>
    mostrarPorqueNao({ regra: $('#pn-regra').value, artigo: $('#pn-regra-artigo').value }));
}

function renderRegraPorqueNao(r) {
  return `<div class="regra-exp"><header><strong>${esc(r.codigoRegra)}</strong>
      ${r.artigoId ? `<span class="chip">${esc(r.artigoId)}</span>` : ''}<span class="causa">${esc(r.causa)}</span>
      ${r.variante ? `<span class="nota" style="margin:0">${esc(r.variante)}</span>` : ''}</header>
    <div>${esc(r.resumo)}</div>${renderCondicoes(r.condicoes)}</div>`;
}

async function mostrarPorqueNao(parametros) {
  abrirExplicacao('porque-nao');
  if (parametros.preencher) {
    $('#pn-codigo').value = parametros.preencher;
    $('#pn-codigo').dispatchEvent(new Event('change'));
    $('#pn-artigo').value = parametros.artigo || '';
    $('#pn-resultado').innerHTML = '<p class="nota">Escolha o valor que esperava e carregue em <strong>Porque não?</strong>.</p>';
    return;
  }
  const alvo = $('#pn-resultado');
  alvo.innerHTML = '<p class="nota">A calcular…</p>';
  const q = new URLSearchParams();
  if (parametros.conclusao) q.set('conclusao', parametros.conclusao);
  if (parametros.regra) q.set('regra', parametros.regra);
  if (parametros.artigo) q.set('artigo', parametros.artigo);
  try {
    const e = await api('GET', `/api/v1/avaliacoes/${avaliacao.avaliacaoId}/explicacoes/porque-nao?${q}`);
    if (e.conclusao) {
      alvo.innerHTML = `<p class="resumo">${esc(e.resumo)}</p>
        ${e.propostaPor.length ? `<p class="nota">Chegou a ser proposta por: ${e.propostaPor.map(esc).join(', ')}</p>` : ''}
        ${e.regras.map(renderRegraPorqueNao).join('')}`;
    } else {
      alvo.innerHTML = renderRegraPorqueNao(e);
    }
  } catch (err) { alvo.innerHTML = `<p class="erro">${esc(err.message)}</p>`; }
}

//  Caminhos sugeridos para o "E se?" (os campos do formulário).
function caminhosSugeridos() {
  const lista = [];
  for (const s of SECOES) {
    if (s.campos) for (const f of s.campos) lista.push(f.c);
    if (s.opcional) lista.push(s.opcional);
  }
  (pedido.artigos || []).forEach((_, i) => CAMPOS_LISTA.artigos.forEach((f) => lista.push(`artigos[${i}].${f.c}`)));
  return [...new Set(lista)];
}

function renderESe() {
  const alvo = $('#exp-e-se');
  alvo.innerHTML = `<p class="nota">Reavalia o mesmo pedido com alterações, sem mudar a avaliação gravada.
      Valores: <code>sim</code>, <code>nao</code>, <code>null</code>, números ou texto (ex.: <code>DEBITO</code>).</p>
    <datalist id="caminhos">${caminhosSugeridos().map((c) => `<option value="${esc(c)}">`).join('')}</datalist>
    <div class="alteracoes" id="alteracoes"></div>
    <div style="display:flex;gap:8px">
      <button type="button" class="botao secundario" id="mais-alteracao">+ Alteração</button>
      <button type="button" class="botao primario" id="simular">Simular</button>
    </div>
    <div id="resultado-e-se" class="bloco"></div>`;
  const mais = (caminho = '', valor = '') => {
    const linha = document.createElement('div');
    linha.className = 'alteracao';
    linha.innerHTML = `<input type="text" list="caminhos" placeholder="caminho (ex.: artigos[0].revendivel)" value="${esc(caminho)}">
      <input type="text" placeholder="valor" value="${esc(valor)}">
      <button type="button" class="botao secundario" title="Remover">×</button>`;
    linha.querySelector('button').addEventListener('click', () => linha.remove());
    $('#alteracoes').append(linha);
  };
  mais(avaliacao.artigos.length ? 'artigos[0].revendivel' : '', 'sim');
  $('#mais-alteracao').addEventListener('click', () => mais());
  $('#simular').addEventListener('click', simular);
}

function valorTexto(t) {
  const s = t.trim();
  if (/^(sim|true)$/i.test(s)) return true;
  if (/^(n[aã]o|false)$/i.test(s)) return false;
  if (/^null$/i.test(s) || s === '') return null;
  if (!Number.isNaN(Number(s))) return Number(s);
  return s;
}

async function simular() {
  const alteracoes = {};
  $$('#alteracoes .alteracao').forEach((l) => {
    const [c, v] = $$('input', l).map((i) => i.value);
    if (c.trim()) alteracoes[c.trim()] = valorTexto(v);
  });
  const alvo = $('#resultado-e-se');
  alvo.innerHTML = '<p class="nota">A simular…</p>';
  try {
    const e = await api('POST', `/api/v1/avaliacoes/${avaliacao.avaliacaoId}/simulacoes`, { alteracoes });
    const s = e.decisaoSimulada;
    alvo.innerHTML = `<p class="resumo">${esc(e.resumo)} Elegibilidade simulada:
        <span class="selo ${esc(s.elegibilidade)}">${esc(rotulo(s.elegibilidade))}</span></p>
      ${e.diferencas.length ? `<table><thead><tr><th>Alvo</th><th>Campo</th><th>Original</th><th>Simulado</th></tr></thead><tbody>
        ${e.diferencas.map((d) => `<tr class="diferenca"><td>${esc(d.alvo)}</td><td><code>${esc(d.campo)}</code></td>
          <td class="original">${esc(rotulo(d.original))}</td><td><strong>${esc(rotulo(d.simulado))}</strong></td></tr>`).join('')}</tbody></table>` : ''}
      <p class="nota">Regras que passam a disparar: ${e.regrasNovas.length ? e.regrasNovas.map(esc).join(', ') : '—'}<br>
        Regras que deixam de disparar: ${e.regrasRemovidas.length ? e.regrasRemovidas.map(esc).join(', ') : '—'}</p>`;
  } catch (err) {
    alvo.innerHTML = `<p class="erro">${esc(err.message)}</p>`;
  }
}

// ---------------------------------------------------------------------------------------------
// Histórico e regras
// ---------------------------------------------------------------------------------------------

async function carregarHistorico() {
  const alvo = $('#historico');
  try {
    const pagina = await api('GET', '/api/v1/avaliacoes?tamanho=100');
    if (!pagina.conteudo.length) {
      alvo.innerHTML = '<p class="vazio">Ainda não há avaliações. As avaliações ficam em memória enquanto o servidor estiver a correr.</p>';
      return;
    }
    alvo.innerHTML = `<table><thead><tr><th>Quando</th><th>Pedido</th><th>Loja</th><th>Elegibilidade</th><th>Transação</th><th>Valor</th></tr></thead>
      <tbody>${pagina.conteudo.map((a) => `<tr class="clicavel" data-avaliacao="${esc(a.avaliacaoId)}">
        <td>${esc(a.avaliadaEm.replace('T', ' '))}</td><td>${esc(a.pedidoId)}</td><td>${esc(a.lojaCodigo ?? '—')}</td>
        <td><span class="selo ${esc(a.elegibilidade || '')}">${esc(rotulo(a.elegibilidade))}</span></td>
        <td>${esc(rotulo(a.tipoTransacao))}</td><td>${moeda(a.valorDevolucao)}</td></tr>`).join('')}</tbody></table>
      <p class="nota">Clique numa avaliação para ver a decisão e as explicações.</p>`;
  } catch (e) { alvo.innerHTML = `<p class="erro">${esc(e.message)}</p>`; }
}

async function abrirAvaliacao(id) {
  avaliacao = await api('GET', `/api/v1/avaliacoes/${id}`);
  pedidoAvaliado = null;
  mudarVista('avaliar');
  renderDecisao();
  abrirExplicacao('como');
  renderComoCompleto();
}

function renderListaRegras() {
  const filtro = $('#filtro-regras').value.trim().toLowerCase();
  $('#lista-regras').innerHTML = catalogo
    .filter((r) => !filtro || r.id.toLowerCase().includes(filtro) || r.descricao.toLowerCase().includes(filtro))
    .map((r) => `<li><button type="button" data-regra="${esc(r.id)}"><span class="id">${esc(r.id)}</span>
      <span class="desc">${esc(r.descricao)}</span></button></li>`).join('');
}

async function mostrarRegra(id) {
  $$('#lista-regras button').forEach((b) => b.classList.toggle('ativo', b.dataset.regra === id));
  const alvo = $('#detalhe-regra');
  try {
    const r = await api('GET', `/api/v1/regras/${encodeURIComponent(id)}`);
    alvo.innerHTML = `<h2>${esc(r.id)} <span class="nota">${r.variantes.length} variante(s)</span></h2>
      ${r.variantes.map((v) => `<div class="variante"><h3>${esc(v.nome)}</h3>
        <div class="meta"><span class="chip">módulo ${esc(v.modulo)}</span><span class="chip">prioridade ${v.prioridade}</span>
          ${v.aValidar ? '<span class="etiqueta-validar">a validar</span>' : ''}</div>
        <p>${esc(v.descricao)}</p>
        <strong>se</strong><ul>${v.condicoes.map((c) => `<li><code>${esc(c)}</code></li>`).join('')}</ul>
        <strong>conclusões</strong> ${v.conclusoes.length ? v.conclusoes.map((c) => `<code>${esc(c)}</code>`).join(' ') : '<span class="nota">só regista uma ação</span>'}
      </div>`).join('')}`;
  } catch (e) { alvo.innerHTML = `<p class="erro">${esc(e.message)}</p>`; }
}

// ---------------------------------------------------------------------------------------------
// Navegação e arranque
// ---------------------------------------------------------------------------------------------

function mudarVista(nome) {
  $$('.separador').forEach((b) => b.classList.toggle('ativo', b.dataset.vista === nome));
  $$('.vista').forEach((v) => v.classList.toggle('oculto', v.id !== `vista-${nome}`));
  if (nome === 'historico') carregarHistorico();
}

function carregarPedido(novo) {
  pedido = novo;
  for (const k of ['artigos', 'artigosTroca', 'indicadoresFraude']) if (!Array.isArray(pedido[k])) pedido[k] = [];
  if (!pedido.cliente) pedido.cliente = {};
  renderFormulario();
  alterado(false);
}

let exemplos = [];

async function iniciar() {
  document.addEventListener('click', (ev) => {
    const b = ev.target.closest('button, tr');
    if (!b) return;
    if (b.dataset.porque) { ev.preventDefault(); mostrarPorque(b.dataset.porque); }
    else if (b.dataset.como) mostrarComoConclusao(b.dataset.como, b.dataset.artigo);
    else if (b.dataset.pn) mostrarPorqueNao({ preencher: b.dataset.pn, artigo: b.dataset.artigo });
    else if (b.dataset.vista) mudarVista(b.dataset.vista);
    else if (b.dataset.exp) abrirExplicacao(b.dataset.exp);
    else if (b.dataset.regra) mostrarRegra(b.dataset.regra);
    else if (b.dataset.avaliacao) abrirAvaliacao(b.dataset.avaliacao);
    else if (b.dataset.ir !== undefined) {
      const campo = document.querySelector(`.campo[data-caminho="${CSS.escape(b.dataset.ir)}"] input, .campo[data-caminho="${CSS.escape(b.dataset.ir)}"] select`);
      if (campo) { campo.scrollIntoView({ block: 'center', behavior: 'smooth' }); campo.focus({ preventScroll: true }); }
    }
  });

  $('#avaliar').addEventListener('click', avaliar);
  $('#novo-pedido').addEventListener('click', () => { $('#exemplos').value = ''; carregarPedido(pedidoNovo()); });
  $('#exemplos').addEventListener('change', (ev) => {
    const e = exemplos.find((x) => String(x.id) === ev.target.value);
    if (e) carregarPedido(JSON.parse(JSON.stringify(e.pedido)));
  });
  $('#ver-json').addEventListener('click', () => {
    $('#texto-json').value = JSON.stringify(pedidoParaEnviar(), null, 2);
    $('#erro-json').textContent = '';
    $('#dialogo-json').showModal();
  });
  $('#aplicar-json').addEventListener('click', () => {
    try {
      carregarPedido(JSON.parse($('#texto-json').value));
      $('#dialogo-json').close();
    } catch (e) { $('#erro-json').textContent = `JSON inválido: ${e.message}`; }
  });
  $('#atualizar-historico').addEventListener('click', carregarHistorico);
  $('#filtro-regras').addEventListener('input', renderListaRegras);

  renderFormulario();
  verificarFalta();

  try {
    const s = await api('GET', '/api/v1/saude');
    const estado = $('#estado-servico');
    estado.textContent = `${s.motor} · ${s.regras} regras`;
    estado.className = 'estado-servico ok';
  } catch {
    const estado = $('#estado-servico');
    estado.textContent = 'servidor indisponível';
    estado.className = 'estado-servico erro';
  }
  try {
    exemplos = await api('GET', '/api/v1/exemplos');
    $('#exemplos').innerHTML += exemplos.map((e) => `<option value="${e.id}">${e.id}. ${esc(e.titulo)}</option>`).join('');
  } catch { /* sem exemplos */ }
  try {
    catalogo = await api('GET', '/api/v1/regras');
    renderListaRegras();
  } catch { /* sem catálogo */ }
}

iniciar();
