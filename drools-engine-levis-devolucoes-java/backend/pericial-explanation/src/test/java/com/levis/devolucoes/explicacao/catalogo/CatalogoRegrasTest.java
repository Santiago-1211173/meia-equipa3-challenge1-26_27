package com.levis.devolucoes.explicacao.catalogo;

import static com.levis.devolucoes.explicacao.SuporteExplicacoes.CATALOGO;
import static com.levis.devolucoes.explicacao.SuporteExplicacoes.PREDICADOS;
import static org.assertj.core.api.Assertions.assertThat;

import com.levis.devolucoes.regras.OrdemAgenda;
import org.junit.jupiter.api.Test;

class CatalogoRegrasTest {

  @Test
  void leTodasAsRegrasSemAsConsultas() {
    assertThat(CATALOGO.regras())
        .hasSizeGreaterThan(90)
        .noneMatch(r -> r.nome().startsWith("decisao"));
    // 76 IDs da base de conhecimento (docs/01) e 19 regras da camada de incerteza (docs/08)
    assertThat(CATALOGO.ids())
        .contains("HS-006", "PT-003", "BW-004", "OUT-001", "IU-10")
        .hasSize(95);
  }

  @Test
  void variantesDoMesmoId() {
    assertThat(CATALOGO.variantes("PC-002")).hasSize(3).allMatch(r -> r.modulo().equals("M3"));
    assertThat(CATALOGO.variantes("CH-007"))
        .extracting(MetadadosRegra::modulo)
        .containsExactly("M2", "M3");
  }

  @Test
  void aOrdemDosModulosCoincideComAAgenda() {
    assertThat(CatalogoRegras.ORDEM_MODULOS).containsExactlyElementsOf(OrdemAgenda.GRUPOS);
  }

  @Test
  void identificaAsRegrasAValidar() {
    assertThat(CATALOGO.variantes("CH-003")).allMatch(MetadadosRegra::aValidar);
    assertThat(CATALOGO.variantes("HS-001")).noneMatch(MetadadosRegra::aValidar);
  }

  @Test
  void cadaCondicaoDeclaradaTemUmPredicado() {
    assertThat(PREDICADOS.nomes()).containsAll(CATALOGO.condicoesDeclaradas());
  }

  @Test
  void naoHaPredicadosSemUso() {
    assertThat(CATALOGO.condicoesDeclaradas()).containsAll(PREDICADOS.nomes());
  }
}
