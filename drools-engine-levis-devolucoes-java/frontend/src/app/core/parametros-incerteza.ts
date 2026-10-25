import { Injectable, inject, signal } from '@angular/core';
import { Api } from '../api/api';
import { parametrosIncerteza } from '../api/functions';

/**
 * Parâmetros da camada de incerteza em vigor (docs/08): enquanto forem demonstrativos, a aplicação
 * mostra a faixa de aviso em todas as páginas.
 */
@Injectable({ providedIn: 'root' })
export class ParametrosIncerteza {
  private readonly api = inject(Api);
  private pedido: Promise<void> | null = null;

  readonly demonstrativo = signal(false);
  readonly versao = signal<string | null>(null);

  /** Lê os parâmetros uma vez por sessão; sem resposta, não mostra o aviso. */
  carregar(): Promise<void> {
    this.pedido ??= this.api
      .invoke(parametrosIncerteza)
      .then((p) => {
        this.demonstrativo.set(p.demonstrativo === true);
        this.versao.set(p.versao ?? null);
      })
      .catch(() => {
        this.pedido = null;
      });
    return this.pedido;
  }

  /** Volta a ler na próxima sessão. */
  esquecer(): void {
    this.pedido = null;
    this.demonstrativo.set(false);
    this.versao.set(null);
  }
}
