import { Page, expect } from '@playwright/test';
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

/** Os cenários de docs/06, nos mesmos JSON que o teste de aceitação das regras. */
export const PASTA_CENARIOS = join(
  __dirname,
  '..',
  '..',
  'backend',
  'pericial-rules',
  'src',
  'test',
  'resources',
  'cenarios',
);

type Json = null | boolean | number | string | Json[] | { [chave: string]: Json };

export interface Colaborador {
  id: string;
  nome?: string;
  funcao: string;
  aprovadoPeloDM?: boolean;
  idCredencialPOS?: string;
}

export interface Cenario {
  numero: number;
  titulo: string;
  colaborador: Colaborador;
  /** Pedido no formato da API (sem o colaborador, que vem do token; com os indícios de fraude) */
  pedido: Record<string, Json>;
  esperado: Record<string, Json>;
}

export function lerCenarios(): Cenario[] {
  return readdirSync(PASTA_CENARIOS)
    .filter((f) => /^cenario-\d+\.json$/.test(f))
    .sort()
    .map((f) => {
      const raiz = JSON.parse(readFileSync(join(PASTA_CENARIOS, f), 'utf8'));
      const { colaborador, ...pedido } = raiz.pedido;
      return {
        numero: Number(/\d+/.exec(f)![0]),
        titulo: raiz.titulo,
        colaborador,
        pedido: { ...pedido, indicadoresFraude: raiz.indicadoresFraude ?? [] },
        esperado: raiz.esperado,
      };
    });
}

/** Folhas do pedido (caminho com índices → valor), só as que existem no pedido da API. */
function folhas(
  valor: Json,
  permitidos: Set<string>,
  prefixo = '',
  resultado = new Map<string, Json>(),
): Map<string, Json> {
  const mapa = permitidos.has(prefixo.replace(/\[\d+\]/g, ''));
  if (mapa && valor !== null && typeof valor === 'object' && !Array.isArray(valor)) {
    // Mapa da API (ex.: respostas de inspeção): uma entrada por chave, como Sim / Não / Não sei
    for (const [chave, v] of Object.entries(valor)) {
      resultado.set(`${prefixo}.${chave}`, v === null ? 'NAO_SEI' : v ? 'SIM' : 'NAO');
    }
  } else if (valor !== null && typeof valor === 'object' && !Array.isArray(valor)) {
    for (const [nome, v] of Object.entries(valor)) {
      folhas(v, permitidos, prefixo ? `${prefixo}.${nome}` : nome, resultado);
    }
  } else if (Array.isArray(valor) && valor.some((v) => v !== null && typeof v === 'object')) {
    valor.forEach((v, i) => folhas(v, permitidos, `${prefixo}[${i}]`, resultado));
  } else if (permitidos.has(prefixo.replace(/\[\d+\]/g, '')) && valor !== null) {
    resultado.set(prefixo, valor);
  }
  return resultado;
}

/** Caminhos (sem índices) do pedido da API, a partir do documento OpenAPI. */
export function caminhosDaApi(): Set<string> {
  const documento = JSON.parse(
    readFileSync(join(__dirname, '..', 'openapi', 'openapi.json'), 'utf8'),
  );
  const esquemas = documento.components.schemas;
  const resolver = (e: any) => (e.$ref ? esquemas[e.$ref.split('/').pop()] : e);
  const caminhos = new Set<string>();
  const percorrer = (e: any, prefixo: string) => {
    for (const [nome, p] of Object.entries<any>(resolver(e).properties ?? {})) {
      const caminho = prefixo ? `${prefixo}.${nome}` : nome;
      const r = resolver(p);
      if (r.properties) {
        percorrer(r, caminho);
      } else if (r.type === 'array' && r.items && resolver(r.items).properties) {
        percorrer(resolver(r.items), caminho);
      } else {
        caminhos.add(caminho);
      }
    }
  };
  percorrer(esquemas.PedidoAvaliacaoRequest, '');
  return caminhos;
}

export async function entrarComo(page: Page, colaborador: Colaborador): Promise<void> {
  await page.goto('entrar');
  await page.getByTestId('entrar-id').fill(colaborador.id);
  await page.getByTestId('entrar-nome').fill(colaborador.nome ?? '');
  await page.getByTestId('entrar-funcao').selectOption(colaborador.funcao);
  await page.getByTestId('entrar-credencial').fill(colaborador.idCredencialPOS ?? '');
  await page.getByTestId('entrar-dm').setChecked(colaborador.aprovadoPeloDM === true);
  await page.getByTestId('entrar-outro').click();
  await expect(page).toHaveURL(/\/avaliacao$/);
}

/**
 * Preenche o assistente com o pedido: passo a passo, acrescenta os itens das listas (artigos,
 * artigos de troca, indícios) e escreve cada valor no controlo com o mesmo caminho.
 */
export async function preencherPedido(page: Page, pedido: Record<string, Json>): Promise<void> {
  const valores = folhas(pedido, caminhosDaApi());
  // Os cenários guardam as respostas do colaborador como no modelo (true/false); no formulário são
  // a escolha Sim / Não (docs/08 §7.1)
  for (const [caminho, valor] of valores) {
    if (caminho.endsWith('explicaOrigemCompra') && typeof valor === 'boolean') {
      valores.set(caminho, valor ? 'SIM' : 'NAO');
    }
  }
  const passos = await page.locator('[data-passo]').all();
  for (const passo of passos) {
    await passo.click();
    await expect(passo).toHaveAttribute('aria-current', 'step');
    for (const botao of await page.locator('[data-adicionar]').all()) {
      const lista = (await botao.getAttribute('data-adicionar'))!;
      const pretendidos = Array.isArray(pedido[lista]) ? (pedido[lista] as Json[]).length : 0;
      const itens = page.locator(`[data-item^="${lista}["]`);
      for (let n = await itens.count(); n < pretendidos; n++) {
        await botao.click();
        await expect(itens).toHaveCount(n + 1);
      }
    }
    // Os grupos dependentes (ex.: quem aprovou a exceção) só aparecem depois de preenchido o grupo de que dependem
    let preenchidos = -1;
    while (preenchidos !== 0) {
      preenchidos = 0;
      const caminhos = await page
        .locator('[data-caminho]')
        .evaluateAll((controlos) => controlos.map((c) => c.getAttribute('data-caminho')!));
      for (const caminho of caminhos) {
        if (!valores.has(caminho)) {
          continue;
        }
        await escrever(page.locator(`[data-caminho="${caminho}"]`), valores.get(caminho)!);
        valores.delete(caminho);
        preenchidos++;
      }
    }
  }
  expect([...valores.keys()], 'campos do cenário sem controlo no assistente').toEqual([]);
}

async function escrever(controlo: ReturnType<Page['locator']>, valor: Json): Promise<void> {
  const etiqueta = await controlo.evaluate((e) => e.tagName.toLowerCase());
  const tipo = await controlo.getAttribute('type');
  if (etiqueta === 'select') {
    await controlo.selectOption(String(valor));
  } else if (tipo === 'checkbox') {
    await controlo.setChecked(valor === true);
  } else {
    await controlo.fill(Array.isArray(valor) ? valor.join(', ') : String(valor));
    await controlo.dispatchEvent('change');
  }
}

/** Avalia e espera pelo cartão de decisão; devolve o identificador da avaliação. */
export async function avaliar(page: Page): Promise<string> {
  await page.getByTestId('avaliar').click();
  await expect(page).toHaveURL(/\/avaliacoes\/[0-9a-f-]{36}$/);
  await expect(page.getByTestId('cartao-decisao')).toBeVisible();
  return page.url().split('/').pop()!;
}

function texto(valor: Json | undefined | null): string {
  return valor === undefined || valor === null ? 'null' : String(valor);
}

/** Compara o cartão de decisão com o "esperado" do cenário (os critérios do VerificadorCenario). */
export async function verificarDecisao(page: Page, esperado: Record<string, Json>): Promise<void> {
  const cartao = page.getByTestId('cartao-decisao');
  const saida = async (campo: string, raiz = cartao) =>
    texto(await raiz.locator(`[data-saida="${campo}"]`).first().getAttribute('data-valor'));

  if ('elegibilidade' in esperado) {
    expect(
      await saida('elegibilidade', cartao.locator('.decisao-cabecalho')),
      'elegibilidade',
    ).toBe(texto(esperado['elegibilidade']));
  }
  for (const campo of [
    'tipoVerificacao',
    'tipoTransacao',
    'meioReembolso',
    'aprovacao',
    'processo',
  ]) {
    if (campo in esperado) {
      expect.soft(await saida(campo), campo).toBe(texto(esperado[campo]));
    }
  }
  for (const campo of ['terminal', 'excecaoRecusada']) {
    if (campo in esperado) {
      const presente = (await cartao.locator(`[data-saida="${campo}"]`).count()) > 0;
      expect.soft(String(presente), campo).toBe(texto(esperado[campo]));
    }
  }
  if ('valorDevolucao' in esperado) {
    expect
      .soft(Number(await saida('valorDevolucao')), 'valor')
      .toBeCloseTo(Number(esperado['valorDevolucao']), 2);
  }
  if (esperado['artigos'] && typeof esperado['artigos'] === 'object') {
    for (const [artigo, e] of Object.entries(
      esperado['artigos'] as Record<string, Record<string, Json>>,
    )) {
      const linha = cartao.locator(`tr[data-artigo="${artigo}"]`);
      for (const campo of ['elegibilidade', 'destino']) {
        if (campo in e) {
          expect.soft(await saida(campo, linha), `${artigo}.${campo}`).toBe(texto(e[campo]));
        }
      }
    }
  }

  await page.locator('[data-painel="rasto"]').click();
  await expect(page.getByTestId('rasto').locator('[data-regra]').first()).toBeVisible();
  const regras = await page
    .getByTestId('rasto')
    .locator('[data-regra]')
    .evaluateAll((linhas) => linhas.map((l) => l.getAttribute('data-regra')));
  for (const regra of (esperado['regrasDisparadas'] as string[]) ?? []) {
    expect.soft(regras, 'regras disparadas').toContain(regra);
  }
  for (const regra of (esperado['regrasNaoDisparadas'] as string[]) ?? []) {
    expect.soft(regras, 'regras não disparadas').not.toContain(regra);
  }
}
