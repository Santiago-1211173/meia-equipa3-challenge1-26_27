package com.levis.devolucoes.incerteza.fuzzy;

/**
 * Regra fuzzy ativada numa inferência.
 *
 * @param id identificador da regra no FCL (RV1…RV7, CR1…CR8)
 * @param forca grau de ativação, em ]0, 1]
 * @param consequente o consequente legível (ex.: "revendibilidade é alta")
 */
public record RegraAtivada(String id, double forca, String consequente) {}
