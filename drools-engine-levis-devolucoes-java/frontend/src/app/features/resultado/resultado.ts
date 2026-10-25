import { Component, computed, effect, inject, input, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { Api } from '../../api/api';
import { consultarAvaliacao } from '../../api/functions';
import { DecisaoResponse } from '../../api/models';
import { ErroApresentavel, erroApresentavel } from '../../core/erros';
import { ELEGIBILIDADE, rotulo } from '../../shared/rotulos';
import { ComoCompleto } from '../explicacoes/como-completo';
import { ESe } from '../explicacoes/e-se';
import { PorqueNao } from '../explicacoes/porque-nao';
import { CartaoDecisao } from './cartao-decisao';
import { CartaoIncerteza } from './cartao-incerteza';

type Painel = 'como' | 'porque-nao' | 'e-se' | 'rasto';

/** Resultado de uma avaliação gravada, com as explicações Como, Porque não e E se. */
@Component({
  selector: 'lv-resultado',
  imports: [CartaoDecisao, CartaoIncerteza, ComoCompleto, PorqueNao, ESe, RouterLink],
  templateUrl: './resultado.html',
})
export class ResultadoPagina {
  private readonly api = inject(Api);

  /** Identificador da avaliação (parâmetro da rota) */
  readonly id = input.required<string>();

  protected readonly decisao = signal<DecisaoResponse | null>(null);
  protected readonly erro = signal<ErroApresentavel | null>(null);
  protected readonly painel = signal<Painel>('como');
  protected readonly artigos = computed(() =>
    (this.decisao()?.artigos ?? []).map((a) => a.artigoId ?? ''),
  );
  protected readonly elegibilidade = (v?: string) => rotulo(ELEGIBILIDADE, v);
  protected readonly paineis: readonly { id: Painel; titulo: string }[] = [
    { id: 'como', titulo: $localize`:@@resultado.como:Como?` },
    { id: 'porque-nao', titulo: $localize`:@@resultado.porqueNao:Porque não?` },
    { id: 'e-se', titulo: $localize`:@@resultado.eSe:E se?` },
    { id: 'rasto', titulo: $localize`:@@resultado.rasto:Regras disparadas` },
  ];

  constructor() {
    effect(() => {
      const id = this.id();
      this.decisao.set(null);
      this.erro.set(null);
      this.api
        .invoke(consultarAvaliacao, { id })
        .then((d) => this.decisao.set(d))
        .catch((e: unknown) => this.erro.set(erroApresentavel(e)));
    });
  }
}
