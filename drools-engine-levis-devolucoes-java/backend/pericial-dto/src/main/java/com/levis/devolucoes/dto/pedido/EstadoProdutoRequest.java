package com.levis.devolucoes.dto.pedido;

import com.levis.devolucoes.dto.enums.CondicaoUso;
import com.levis.devolucoes.dto.enums.EstadoEtiquetas;
import com.levis.devolucoes.dto.enums.Resposta;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import java.util.Map;

/**
 * Resultado da inspeção do artigo (IN-008). Etiqueta de preço, RFID e conjunto vazios contam como
 * corretos/completos.
 *
 * @param grauUso grau de uso de 0 (nenhum) a 4 (intenso), para a revendibilidade (docs/08 §4.1)
 * @param alegaDefeito o cliente alega um defeito (docs/08 §3.2)
 * @param inspecaoDefeito respostas da inspeção do defeito: ED-01, ED-02, ED-05, ED-06 ou ED-07
 */
public record EstadoProdutoRequest(
    CondicaoUso condicaoUso,
    EstadoEtiquetas etiquetas,
    boolean personalizado,
    boolean alterado,
    boolean embainhado,
    boolean defeitoFabricoConfirmado,
    boolean sujoOuInseguro,
    boolean danificado,
    Boolean etiquetaPrecoCorreta,
    Boolean rfidCorreto,
    boolean embalagemIntacta,
    Boolean conjuntoCompleto,
    @Min(0) @Max(4) Integer grauUso,
    boolean alegaDefeito,
    Map<@Pattern(regexp = "ED-0[12567]") String, @NotNull Resposta> inspecaoDefeito) {}
