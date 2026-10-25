import { Component, computed, inject, input } from '@angular/core';
import { obter } from '../../shared/caminhos';
import { AvaliacaoStore } from './avaliacao.store';
import { Campo, Grupo, caminhoCompleto } from './formulario';
import { textoDoControlo, valorDoControlo } from './pedido';

/** Um campo do pedido, com o controlo adequado ao tipo; assinala quando o sistema precisa dele. */
@Component({
  selector: 'lv-campo',
  templateUrl: './campo.html',
  host: {
    class: 'campo',
    '[class.em-falta]': 'emFalta() !== undefined',
    '[hidden]': '!visivel()',
    '[class.largo]': "campo().tipo === 'texto-longo' || campo().tipo === 'lista'",
  },
})
export class CampoFormulario {
  protected readonly store = inject(AvaliacaoStore);

  readonly grupo = input.required<Grupo>();
  readonly campo = input.required<Campo>();
  readonly indice = input<number>();

  protected readonly caminho = computed(() =>
    caminhoCompleto(this.grupo(), this.campo(), this.indice()),
  );
  protected readonly valor = computed(() => obter(this.store.pedido(), this.caminho()));
  protected readonly texto = computed(() => textoDoControlo(this.campo(), this.valor()));
  protected readonly emFalta = computed(() => this.store.emFaltaPorCaminho().get(this.caminho()));
  /** Campos condicionais (ex.: perguntas de inspeção só com alegação de defeito) */
  protected readonly visivel = computed(() => {
    const condicao = this.campo().visivelSe;
    if (!condicao) {
      return true;
    }
    const caminho = caminhoCompleto(
      this.grupo(),
      { ...this.campo(), caminho: condicao },
      this.indice(),
    );
    return obter(this.store.pedido(), caminho) === true;
  });
  protected readonly opcoes = computed(() => Object.entries(this.campo().opcoes ?? {}));
  protected readonly id = computed(() => `campo-${this.caminho().replace(/[^\w]/g, '-')}`);

  protected alterarTexto(evento: Event): void {
    const texto = (evento.target as HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement)
      .value;
    this.store.definir(this.caminho(), valorDoControlo(this.campo(), texto));
  }

  protected alterarCaixa(evento: Event): void {
    this.store.definir(this.caminho(), (evento.target as HTMLInputElement).checked);
  }
}
