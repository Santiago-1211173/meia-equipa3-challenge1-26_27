package com.levis.devolucoes.service.mapeamento;

import com.levis.devolucoes.dto.decisao.DocumentacaoResponse;
import com.levis.devolucoes.dto.decisao.ResultadoArtigoResponse;
import com.levis.devolucoes.dto.incerteza.ContribuicaoDto;
import com.levis.devolucoes.dto.incerteza.GrauCrencaDto;
import com.levis.devolucoes.model.decisao.DecisaoArtigo;
import com.levis.devolucoes.model.decisao.Documentacao;
import com.levis.devolucoes.model.enums.Elegibilidade;
import com.levis.devolucoes.model.incerteza.Contribuicao;
import com.levis.devolucoes.model.incerteza.GrauCrenca;
import java.util.List;
import org.mapstruct.Mapper;

/** Partes da decisão do modelo para os DTO de resposta. */
@Mapper
public interface DecisaoMapper {

  DocumentacaoResponse documentacao(Documentacao documentacao);

  ResultadoArtigoResponse artigo(DecisaoArtigo artigo);

  com.levis.devolucoes.dto.enums.Elegibilidade elegibilidade(Elegibilidade elegibilidade);

  GrauCrencaDto grau(GrauCrenca grau);

  List<GrauCrencaDto> graus(List<GrauCrenca> graus);

  ContribuicaoDto contribuicao(Contribuicao contribuicao);
}
