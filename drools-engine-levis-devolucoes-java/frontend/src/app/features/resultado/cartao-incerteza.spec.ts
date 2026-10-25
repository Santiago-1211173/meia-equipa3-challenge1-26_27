import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { GrauCrencaDto } from '../../api/models';
import { CartaoIncerteza } from './cartao-incerteza';

const FRAUDE: GrauCrencaDto = {
  hipotese: 'FRAUDE',
  metodo: 'FATOR_CERTEZA',
  valor: 0.8354,
  classificacao: 'RISCO_ALTO',
  versaoParametros: '0.1.0-demo',
  demonstrativo: true,
  contribuicoes: [
    {
      codigo: 'EF-01',
      descricao: 'Sem comprovativo',
      peso: 0.5,
      valorAntes: 0,
      valorDepois: 0.5,
      aplicada: true,
    },
    {
      codigo: 'EF-02',
      descricao: 'Sem etiquetas',
      peso: 0.3,
      aplicada: false,
      motivoNaoAplicada: 'evidência ausente',
    },
  ],
};

describe('CartaoIncerteza', () => {
  async function mostrar(graus: GrauCrencaDto[]): Promise<HTMLElement> {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting()],
    });
    const fixture = TestBed.createComponent(CartaoIncerteza);
    fixture.componentRef.setInput('avaliacaoId', '7b0c1f8e-2a54-4c39-9c51-6a0d3b2f1e10');
    fixture.componentRef.setInput('graus', graus);
    await fixture.whenStable();
    return fixture.nativeElement as HTMLElement;
  }

  it('mostra o grau com o valor, a classificação e o aviso de valores demonstrativos', async () => {
    const cartao = await mostrar([FRAUDE]);

    const linha = cartao.querySelector('tr[data-hipotese="FRAUDE"]')!;
    expect(linha.querySelector('[data-campo="valor"]')!.textContent!.trim()).toBe('0,84');
    expect(linha.querySelector('[data-campo="classificacao"]')!.textContent).toContain(
      'Risco alto',
    );
    expect(cartao.querySelector('[data-teste="aviso-incerteza"]')).not.toBeNull();
    expect(cartao.textContent).toContain('0.1.0-demo');
  });

  it('não chama probabilidade a um fator de certeza e mostra as contribuições não aplicadas', async () => {
    const cartao = await mostrar([FRAUDE]);

    expect(cartao.querySelector('tr[data-hipotese="FRAUDE"]')!.textContent).toContain(
      'não é uma probabilidade',
    );
    const naoAplicada = cartao.querySelector('.contribuicoes li.nao-aplicada')!;
    expect(naoAplicada.textContent).toContain('EF-02');
    expect(naoAplicada.textContent).toContain('evidência ausente');
  });

  it('mostra a recomendação de crédito em pontos e sem aviso quando os parâmetros são reais', async () => {
    const cartao = await mostrar([
      {
        hipotese: 'RECOMENDACAO_CREDITO',
        metodo: 'FUZZY',
        valor: 84.4,
        classificacao: 'CREDITO_RECOMENDADO',
        demonstrativo: false,
        contribuicoes: [],
      },
    ]);

    const linha = cartao.querySelector('tr[data-hipotese="RECOMENDACAO_CREDITO"]')!;
    expect(linha.querySelector('[data-campo="valor"]')!.textContent!.trim()).toBe('84');
    expect(linha.textContent).not.toContain('probabilidade');
    expect(cartao.querySelector('[data-teste="aviso-incerteza"]')).toBeNull();
  });
});
