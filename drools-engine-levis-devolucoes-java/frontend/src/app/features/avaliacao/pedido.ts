import { PedidoAvaliacaoRequest } from '../../api/models';
import { definir, obter } from '../../shared/caminhos';
import { Campo, GRUPOS, Grupo } from './formulario';

/** Pedido em preenchimento: a mesma forma que o pedido da API, com campos ainda vazios. */
export type PedidoEmCurso = PedidoAvaliacaoRequest;

function valorInicial(campo: Campo): unknown {
  switch (campo.tipo) {
    case 'booleano':
      return false;
    case 'lista':
      return [];
    default:
      return null;
  }
}

/** Novo item de um grupo repetível (ex.: um artigo), com os campos nos valores iniciais. */
export function itemInicial(grupo: Grupo, numero = 1): Record<string, unknown> {
  let item: Record<string, unknown> = {};
  for (const campo of grupo.campos) {
    item = definir(item, campo.caminho, valorInicial(campo));
  }
  if (grupo.repeticao?.caminho === 'artigos') {
    item = definir(item, 'id', `A-${numero}`);
    item = definir(item, 'quantidade', 1);
  }
  return item;
}

export function hojeIso(data = new Date()): string {
  const mes = String(data.getMonth() + 1).padStart(2, '0');
  const dia = String(data.getDate()).padStart(2, '0');
  return `${data.getFullYear()}-${mes}-${dia}`;
}

export function pedidoInicial(hoje = hojeIso()): PedidoEmCurso {
  let pedido: Record<string, unknown> = {};
  for (const grupo of GRUPOS) {
    if (grupo.repeticao) {
      const itens = Array.from({ length: grupo.repeticao.minimo }, (_, i) =>
        itemInicial(grupo, i + 1),
      );
      pedido = definir(pedido, grupo.repeticao.caminho, itens);
    } else {
      for (const campo of grupo.campos) {
        pedido = definir(pedido, campo.caminho, valorInicial(campo));
      }
    }
  }
  pedido = definir(pedido, 'dataPedido', hoje);
  return pedido as unknown as PedidoEmCurso;
}

/** Vazio: nulo, falso, texto vazio, lista vazia, ou objeto só com valores vazios. */
export function vazio(valor: unknown): boolean {
  if (valor === null || valor === undefined || valor === false || valor === '') {
    return true;
  }
  if (Array.isArray(valor)) {
    return valor.length === 0;
  }
  if (typeof valor === 'object') {
    return Object.values(valor as Record<string, unknown>).every(vazio);
  }
  return false;
}

/**
 * Pedido a enviar à API: os objetos opcionais por preencher vão vazios (sem comprovativo é uma
 * devolução às cegas; sem pedido de exceção não há exceção), do mais interior para o exterior.
 */
export function paraEnvio(pedido: PedidoEmCurso): PedidoAvaliacaoRequest {
  pedido = semRespostasVazias(pedido);
  const opcionais = GRUPOS.filter((g) => g.opcional)
    .map((g) => g.opcional as string)
    .sort((a, b) => b.split('.').length - a.split('.').length);
  let resultado: PedidoEmCurso = pedido;
  for (const caminho of opcionais) {
    const valor = obter(resultado, caminho);
    if (valor !== undefined && valor !== null && vazio(valor)) {
      resultado = definir(resultado, caminho, null);
    }
  }
  return resultado;
}

/**
 * Respostas de inspeção do defeito (docs/08): só as respondidas, e só quando o cliente alega
 * defeito; a API não aceita respostas vazias.
 */
function semRespostasVazias(pedido: PedidoEmCurso): PedidoEmCurso {
  const artigos = (pedido.artigos ?? []).map((artigo) => {
    const estado = artigo.estado;
    if (!estado?.inspecaoDefeito) {
      return artigo;
    }
    const respostas = estado.alegaDefeito
      ? Object.fromEntries(
          Object.entries(estado.inspecaoDefeito).filter(([, resposta]) => resposta !== null),
        )
      : {};
    return { ...artigo, estado: { ...estado, inspecaoDefeito: respostas } };
  });
  return { ...pedido, artigos };
}

/** Converte o texto escrito num controlo no valor do campo. */
export function valorDoControlo(campo: Campo, texto: string): unknown {
  const t = texto.trim();
  switch (campo.tipo) {
    case 'inteiro':
    case 'escala':
      return t === '' ? null : Number.parseInt(t, 10);
    case 'decimal':
      return t === '' ? null : Number(t.replace(',', '.'));
    case 'booleano-opcional':
      return t === '' ? null : t === 'true';
    case 'lista':
      return t
        .split(',')
        .map((s) => s.trim())
        .filter((s) => s !== '');
    default:
      return t === '' ? null : t;
  }
}

/** Texto a mostrar num controlo para o valor do campo. */
export function textoDoControlo(campo: Campo, valor: unknown): string {
  if (valor === null || valor === undefined) {
    return '';
  }
  if (campo.tipo === 'lista' && Array.isArray(valor)) {
    return valor.join(', ');
  }
  return String(valor);
}
