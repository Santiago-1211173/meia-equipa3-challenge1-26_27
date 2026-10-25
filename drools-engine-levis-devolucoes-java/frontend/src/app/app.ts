import { Component, LOCALE_ID, effect, inject } from '@angular/core';
import { Router, RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { Autenticacao } from './core/autenticacao/autenticacao';
import { ParametrosIncerteza } from './core/parametros-incerteza';
import { FUNCAO, rotulo } from './shared/rotulos';

/** Estrutura da aplicação: navegação, colaborador autenticado e idioma. */
@Component({
  selector: 'lv-root',
  imports: [RouterOutlet, RouterLink, RouterLinkActive],
  templateUrl: './app.html',
})
export class App {
  protected readonly autenticacao = inject(Autenticacao);
  private readonly router = inject(Router);
  protected readonly idioma = inject(LOCALE_ID);
  protected readonly funcao = (f?: string) => rotulo(FUNCAO, f);
  protected readonly incerteza = inject(ParametrosIncerteza);

  /** O outro idioma: cada um é publicado no seu caminho (/pt-PT/, /en/). */
  protected readonly outroIdioma = this.idioma.startsWith('en')
    ? { codigo: 'pt-PT', nome: 'Português' }
    : { codigo: 'en', nome: 'English' };

  constructor() {
    // A faixa de valores demonstrativos depende dos parâmetros em vigor (docs/08 §7.3)
    effect(() => {
      if (this.autenticacao.autenticado()) {
        void this.incerteza.carregar();
      }
    });
  }

  protected sair(): void {
    this.incerteza.esquecer();
    this.autenticacao.sair();
    void this.router.navigate(['/entrar']);
  }
}
