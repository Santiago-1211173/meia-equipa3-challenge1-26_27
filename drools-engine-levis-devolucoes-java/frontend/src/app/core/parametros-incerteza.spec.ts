import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { ParametrosIncerteza } from './parametros-incerteza';

describe('ParametrosIncerteza', () => {
  let parametros: ParametrosIncerteza;
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting()],
    });
    parametros = TestBed.inject(ParametrosIncerteza);
    http = TestBed.inject(HttpTestingController);
  });

  const responder = (corpo: object) =>
    http.expectOne((r) => r.url.endsWith('/api/v1/incerteza/parametros')).flush(corpo);

  it('mostra o aviso enquanto os parâmetros forem demonstrativos e lê-os uma vez por sessão', async () => {
    const carregado = parametros.carregar();
    void parametros.carregar();
    responder({ versao: '0.1.0-demo', demonstrativo: true });
    await carregado;

    expect(parametros.demonstrativo()).toBe(true);
    expect(parametros.versao()).toBe('0.1.0-demo');
    http.verify();
  });

  it('esquece os parâmetros ao sair e volta a lê-los na sessão seguinte', async () => {
    const primeira = parametros.carregar();
    responder({ versao: '0.1.0-demo', demonstrativo: true });
    await primeira;

    parametros.esquecer();
    expect(parametros.demonstrativo()).toBe(false);

    const segunda = parametros.carregar();
    responder({ versao: '1.0.0', demonstrativo: false });
    await segunda;
    expect(parametros.demonstrativo()).toBe(false);
    expect(parametros.versao()).toBe('1.0.0');
  });
});
