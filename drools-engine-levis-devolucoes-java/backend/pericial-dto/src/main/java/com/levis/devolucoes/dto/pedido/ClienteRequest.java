package com.levis.devolucoes.dto.pedido;

import com.levis.devolucoes.dto.enums.Resposta;

/**
 * Cliente e o seu comportamento (PT-006, EX-002, EX-003).
 *
 * @param forneceDados aceita dar dados pessoais; vazio conta como sim
 * @param explicaOrigemCompra explica onde e quando comprou (EF-04, docs/08); "Não sei" ou vazio não
 *     contam
 * @param pedeNumerario pede o reembolso em numerário (EF-05, docs/08)
 */
public record ClienteRequest(
    String id,
    Boolean forneceDados,
    boolean barreiraLinguistica,
    boolean contestaResultado,
    boolean agitado,
    Resposta explicaOrigemCompra,
    boolean pedeNumerario) {}
