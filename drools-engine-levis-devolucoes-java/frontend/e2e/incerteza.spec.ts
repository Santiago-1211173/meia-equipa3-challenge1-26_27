import { expect, test } from '@playwright/test';
import { avaliar, entrarComo, lerCenarios, preencherPedido } from './apoio';

/** Camada de incerteza pela interface (docs/08 §7.3); valores demonstrativos. */
const cenarios = lerCenarios();
const cenario = (n: number) => cenarios.find((c) => c.numero === n)!;

test('cenário 6: risco de fraude alto no cartão de incerteza, com o aviso dos valores demonstrativos', async ({
  page,
}) => {
  const c = cenario(6);
  await entrarComo(page, c.colaborador);
  await expect(page.getByTestId('aviso-demonstrativo')).toBeVisible();
  await preencherPedido(page, c.pedido);
  await avaliar(page);

  const cartao = page.getByTestId('cartao-incerteza');
  await expect(cartao).toBeVisible();
  const fraude = cartao.locator('tr[data-hipotese="FRAUDE"]');
  await expect(fraude.locator('[data-campo="classificacao"]')).toHaveAttribute(
    'data-valor',
    'RISCO_ALTO',
  );
  await expect(fraude.locator('[data-campo="valor"]')).toHaveText('0,84');
  await expect(cartao.getByTestId('aviso-incerteza')).toBeVisible();

  await fraude.getByRole('button', { name: 'Como?' }).click();
  await expect(page.getByTestId('como-resumo')).toContainText('não uma probabilidade');
});

test('caso A: defeito de fabrico provável deixa o pedido em revisão e propõe PC-006', async ({
  page,
}) => {
  const c = cenario(1);
  const pedido = structuredClone(c.pedido) as Record<string, any>;
  const artigo = pedido['artigos'][0];
  artigo.estado = {
    condicaoUso: 'USADO',
    etiquetas: 'COLOCADAS',
    alegaDefeito: true,
    inspecaoDefeito: { 'ED-01': true, 'ED-02': true },
  };
  await entrarComo(page, c.colaborador);
  await preencherPedido(page, pedido);
  await avaliar(page);

  const defeito = page
    .getByTestId('cartao-incerteza')
    .locator('tr[data-hipotese="DEFEITO_FABRICO"]');
  await expect(defeito.locator('[data-campo="classificacao"]')).toHaveAttribute(
    'data-valor',
    'PROPOR_PC006',
  );
  await expect(
    page.getByTestId('cartao-decisao').locator('.decisao-cabecalho [data-saida="elegibilidade"]'),
  ).toHaveAttribute('data-valor', 'REVER');
});
