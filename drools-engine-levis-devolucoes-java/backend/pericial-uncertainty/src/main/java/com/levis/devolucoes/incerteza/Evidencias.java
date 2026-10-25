package com.levis.devolucoes.incerteza;

import com.levis.devolucoes.model.incerteza.Evidencia;
import java.util.Collection;
import java.util.Comparator;
import java.util.List;

/** Utilitários comuns aos cálculos sobre evidências. */
public final class Evidencias {

  /** Ordem estável dos passos do cálculo: pelo código e depois pelo artigo. */
  public static final Comparator<Evidencia> ORDEM =
      Comparator.comparing(Evidencia::getCodigo)
          .thenComparing(Evidencia::getArtigoId, Comparator.nullsFirst(Comparator.naturalOrder()));

  private Evidencias() {}

  /** As evidências pela ordem estável. */
  public static List<Evidencia> ordenadas(Collection<Evidencia> evidencias) {
    return evidencias.stream().sorted(ORDEM).toList();
  }

  /** Motivo pelo qual uma evidência não observada não foi aplicada. */
  public static String motivoNaoObservada(Evidencia evidencia) {
    return evidencia.getPresente() == null ? "desconhecida" : "ausente";
  }
}
