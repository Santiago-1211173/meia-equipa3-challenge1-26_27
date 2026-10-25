import { expect, test } from '@playwright/test';
import { avaliar, entrarComo, lerCenarios, preencherPedido } from './apoio';

const cenarios = lerCenarios();
const cenario = (n: number) => cenarios.find((c) => c.numero === n)!;

test('sem sessão, volta ao ecrã de entrada e depois à página pedida', async ({ page }) => {
  await page.goto('regras');
  await expect(page).toHaveURL(/\/entrar\?destino=%2Fregras$/);
  await page.getByTestId('entrar-DEV-KH').click();
  await expect(page).toHaveURL(/\/regras$/);
  await expect(page.getByRole('link', { name: 'CH-004' })).toBeVisible();
});

test('"O que falta?" e "Porquê?" enquanto se preenche o pedido', async ({ page }) => {
  await entrarComo(page, cenario(5).colaborador);

  // Com o formulário vazio o SKU não está indicado como reconhecido pelo POS: o HS-001 termina a
  // inferência e o "O que falta?" já não pede dados (ADR 0004). Com o SKU reconhecido, o pedido continua.
  await page.locator('[data-passo="artigos"]').click();
  await page.locator('[data-caminho="artigos[0].produto.skuReconhecidoPOS"]').selectOption('true');
  await page.locator('[data-passo="pedido"]').click();

  await expect(page.getByTestId('em-falta-resumo')).toBeVisible();
  await expect(page.locator('lv-em-falta')).toContainText('IN-001');

  await page.getByTestId('porque-IN-001').click();
  await expect(page.getByTestId('porque-resumo')).not.toBeEmpty();

  await page.locator('[data-caminho="loja.mercado"]').selectOption('EUA');
  await expect(page.locator('lv-em-falta')).not.toContainText('IN-001');
});

test('não avalia um pedido incompleto e diz o que falta', async ({ page }) => {
  await entrarComo(page, cenario(5).colaborador);
  await page.getByTestId('avaliar').click();
  await expect(page.getByTestId('erro-avaliacao')).toContainText('loja.codigo');

  await page.locator('[data-caminho="loja.codigo"]').fill('US-ML-100');
  await page.locator('[data-caminho="loja.codigo"]').dispatchEvent('change');
  await page.locator('[data-passo="artigos"]').click();
  await page.locator('[data-caminho="artigos[0].produto.sku"]').fill('501-ORIG-32');
  await page.locator('[data-caminho="artigos[0].produto.sku"]').dispatchEvent('change');
  await page.getByTestId('avaliar').click();
  await expect(page.getByTestId('erro-avaliacao')).toContainText('IN-001');
});

test('"Como?", "Porque não?" e "E se?" de uma decisão gravada', async ({ page }) => {
  const c = cenario(10);
  await entrarComo(page, c.colaborador);
  await preencherPedido(page, c.pedido);
  await avaliar(page);

  await expect(page.getByTestId('como-completo-resumo')).not.toBeEmpty();
  await page.locator('[data-como="OUT-001"]').click();
  await expect(page.getByTestId('como-resumo')).not.toBeEmpty();

  await page.locator('[data-painel="porque-nao"]').click();
  await page.getByTestId('porque-nao-valor').selectOption('PERMITIR');
  await page.getByTestId('porque-nao-perguntar').click();
  await expect(page.getByTestId('porque-nao-resposta')).not.toBeEmpty();

  await page.locator('[data-painel="e-se"]').click();
  await page.getByTestId('e-se-campo').selectOption('portalOnlineDisponivel');
  await page.getByTestId('e-se-valor').selectOption('true');
  await page.getByTestId('e-se-acrescentar').click();
  await page.getByTestId('e-se-simular').click();
  await expect(page.getByTestId('e-se-resposta')).toBeVisible();
  await expect(page.getByTestId('e-se-elegibilidade')).not.toBeEmpty();
});

test('o histórico é só para a gestão da loja', async ({ page }) => {
  await page.goto('entrar');
  await page.getByTestId('entrar-DEV-ST').click();
  await expect(page).toHaveURL(/\/avaliacao$/);
  await expect(page.getByRole('link', { name: 'Histórico' })).toHaveCount(0);
  await page.goto('historico');
  await expect(page.getByRole('alert')).toContainText('Sem permissão');

  await page.getByRole('button', { name: 'Sair' }).click();
  await page.getByTestId('entrar-DEV-GL').click();
  await page.getByRole('link', { name: 'Histórico' }).click();
  await expect(page.getByRole('table')).toBeVisible();
});
