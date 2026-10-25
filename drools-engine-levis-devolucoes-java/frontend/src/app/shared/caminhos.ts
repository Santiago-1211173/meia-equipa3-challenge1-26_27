/**
 * Caminhos de campos do pedido, na mesma notação que o backend usa no "O que falta?" e no "E se?"
 * (ex.: `artigos[0].produto.sku`).
 */

type Segmento = string | number;

// Aceita hífen para as chaves dos mapas (ex.: estado.inspecaoDefeito.ED-01)
const SEGMENTO = /^([A-Za-z][\w-]*)(?:\[(\d+)\])?$/;

export function segmentos(caminho: string): Segmento[] {
  const resultado: Segmento[] = [];
  for (const parte of caminho.split('.')) {
    const m = SEGMENTO.exec(parte);
    if (!m) {
      throw new Error(`Caminho inválido: ${caminho}`);
    }
    resultado.push(m[1]);
    if (m[2] !== undefined) {
      resultado.push(Number(m[2]));
    }
  }
  return resultado;
}

/** Valor no caminho indicado, ou `undefined` se algum troço não existir. */
export function obter(raiz: unknown, caminho: string): unknown {
  let atual: unknown = raiz;
  for (const s of segmentos(caminho)) {
    if (atual === null || atual === undefined || typeof atual !== 'object') {
      return undefined;
    }
    atual = (atual as Record<string | number, unknown>)[s];
  }
  return atual;
}

/** Cópia de `raiz` com o valor definido no caminho; cria os objetos e listas intermédios. */
export function definir<T>(raiz: T, caminho: string, valor: unknown): T {
  return definirEm(raiz, segmentos(caminho), valor) as T;
}

function definirEm(atual: unknown, resto: Segmento[], valor: unknown): unknown {
  if (resto.length === 0) {
    return valor;
  }
  const [cabeca, ...cauda] = resto;
  if (typeof cabeca === 'number') {
    const lista = Array.isArray(atual) ? [...atual] : [];
    lista[cabeca] = definirEm(lista[cabeca], cauda, valor);
    return lista;
  }
  const objeto =
    atual !== null && typeof atual === 'object' && !Array.isArray(atual)
      ? { ...(atual as Record<string, unknown>) }
      : {};
  objeto[cabeca] = definirEm(objeto[cabeca], cauda, valor);
  return objeto;
}

/** Caminho sem índices (`artigos[0].produto.sku` → `artigos.produto.sku`), para identificar o campo. */
export function semIndices(caminho: string): string {
  return caminho.replace(/\[\d+\]/g, '');
}
