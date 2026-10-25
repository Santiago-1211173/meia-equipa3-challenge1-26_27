import { DecimalPipe } from '@angular/common';
import { Component, computed, input, signal } from '@angular/core';
import { GrauCrencaDto } from '../../api/models';
import { CLASSIFICACAO_INCERTEZA, HIPOTESE, METODO_INCERTEZA, rotulo } from '../../shared/rotulos';
import { ComoConclusao } from '../explicacoes/como-conclusao';

/**
 * "Avaliação da incerteza" (docs/08 §7.3): uma linha por grau, com o valor, a classificação, as
 * contribuições e o "Como?" de cada um. Um fator de certeza nunca é apresentado como probabilidade.
 */
@Component({
  selector: 'lv-cartao-incerteza',
  imports: [ComoConclusao, DecimalPipe],
  templateUrl: './cartao-incerteza.html',
})
export class CartaoIncerteza {
  readonly avaliacaoId = input.required<string>();
  readonly graus = input.required<readonly GrauCrencaDto[]>();

  protected readonly demonstrativo = computed(() => this.graus().some((g) => g.demonstrativo));
  protected readonly comoAberto = signal<string | null>(null);
  protected readonly r = {
    hipotese: (v?: string) => rotulo(HIPOTESE, v),
    classe: (v?: string) => rotulo(CLASSIFICACAO_INCERTEZA, v),
    metodo: (v?: string) => rotulo(METODO_INCERTEZA, v),
  };

  protected chave(g: GrauCrencaDto): string {
    return `${g.hipotese}|${g.artigoId ?? ''}`;
  }

  protected alternarComo(g: GrauCrencaDto): void {
    this.comoAberto.set(this.comoAberto() === this.chave(g) ? null : this.chave(g));
  }

  /** Recomendação em pontos (0 a 100); os restantes graus com duas casas decimais. */
  protected formato(g: GrauCrencaDto): string {
    return g.hipotese === 'RECOMENDACAO_CREDITO' ? '1.0-0' : '1.2-2';
  }
}
