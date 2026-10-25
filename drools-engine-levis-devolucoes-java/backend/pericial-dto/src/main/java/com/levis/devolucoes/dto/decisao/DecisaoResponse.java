package com.levis.devolucoes.dto.decisao;

import com.levis.devolucoes.dto.enums.BaseValor;
import com.levis.devolucoes.dto.enums.Elegibilidade;
import com.levis.devolucoes.dto.enums.MeioReembolso;
import com.levis.devolucoes.dto.enums.NivelAprovacao;
import com.levis.devolucoes.dto.enums.ProcessoObrigatorio;
import com.levis.devolucoes.dto.enums.TipoTransacao;
import com.levis.devolucoes.dto.enums.TipoVerificacao;
import com.levis.devolucoes.dto.incerteza.GrauCrencaDto;
import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Decisão do sistema pericial (OUT-001 a OUT-008), com o resultado por artigo e o rasto das regras.
 *
 * @param avaliacaoId identificador da avaliação gravada (nulo numa simulação)
 * @param versaoBaseConhecimento versão do kjar usada (auditoria)
 * @param regrasAValidar regras disparadas com ambiguidades por validar pela operação (ADR 0003)
 * @param incerteza graus da camada de incerteza (docs/08), com valores demonstrativos
 */
@Schema(
    description =
        "Decisão: elegibilidade, transação, valor, meio, aprovação, processo, destino e documentação")
public record DecisaoResponse(
    UUID avaliacaoId,
    String pedidoId,
    LocalDateTime avaliadaEm,
    String versaoBaseConhecimento,
    @Schema(description = "OUT-001") Elegibilidade elegibilidade,
    TipoVerificacao tipoVerificacao,
    @Schema(description = "OUT-002") TipoTransacao tipoTransacao,
    @Schema(description = "OUT-003") BigDecimal valorDevolucao,
    BaseValor baseValor,
    @Schema(description = "OUT-004") MeioReembolso meioReembolso,
    @Schema(description = "OUT-005") NivelAprovacao aprovacao,
    @Schema(description = "OUT-006") ProcessoObrigatorio processo,
    boolean terminal,
    boolean excecaoRecusada,
    @Schema(description = "OUT-008") DocumentacaoResponse documentacao,
    @Schema(description = "Resultado por artigo, com o destino (OUT-007)")
        List<ResultadoArtigoResponse> artigos,
    List<RegistoRegraResponse> regras,
    List<String> regrasAValidar,
    @Schema(description = "Avaliação da incerteza (docs/08); valores demonstrativos")
        List<GrauCrencaDto> incerteza) {}
