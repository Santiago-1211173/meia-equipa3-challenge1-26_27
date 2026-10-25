package com.levis.devolucoes.dto.enums;

/** Classe de um grau de crença, segundo os limiares dos parâmetros (docs/08). */
public enum ClassificacaoIncerteza {
  RISCO_ALTO,
  RISCO_MEDIO,
  RISCO_BAIXO,
  PROPOR_PC006,
  REVER_DEFEITO,
  DESGASTE,
  REVENDIVEL,
  REVENDIBILIDADE_INDETERMINADA,
  NAO_REVENDIVEL,
  CREDITO_RECOMENDADO,
  CREDITO_A_CRITERIO,
  CREDITO_NAO_RECOMENDADO
}
