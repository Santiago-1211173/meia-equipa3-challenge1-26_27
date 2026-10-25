package com.levis.devolucoes.model.incerteza;

import static org.assertj.core.api.Assertions.assertThat;

import com.levis.devolucoes.model.enums.FonteEvidencia;
import com.levis.devolucoes.model.enums.Hipotese;
import com.levis.devolucoes.model.produto.EstadoProduto;
import org.junit.jupiter.api.Test;

class IncertezaModeloTest {

  @Test
  void soAEvidenciaPresenteEObservada() {
    Evidencia presente =
        new Evidencia(
            "ED-01", Hipotese.DEFEITO_FABRICO, "P", "A-1", true, FonteEvidencia.COLABORADOR);
    Evidencia ausente =
        new Evidencia(
            "ED-01", Hipotese.DEFEITO_FABRICO, "P", "A-1", false, FonteEvidencia.COLABORADOR);
    Evidencia naoSei =
        new Evidencia(
            "ED-01", Hipotese.DEFEITO_FABRICO, "P", "A-1", null, FonteEvidencia.COLABORADOR);

    assertThat(presente.isObservada()).isTrue();
    assertThat(ausente.isObservada()).isFalse();
    assertThat(naoSei.isObservada()).isFalse();
  }

  @Test
  void contribuicaoNaoAplicadaNaoMudaOValorEGuardaOMotivo() {
    Contribuicao aplicada = Contribuicao.aplicada("EF-01", "d", 0.3, 0.0, 0.3);
    Contribuicao grupo = Contribuicao.naoAplicada("ED-06", "d", 0.4, 0.3, "grupo USO");

    assertThat(aplicada.isAplicada()).isTrue();
    assertThat(aplicada.getMotivoNaoAplicada()).isNull();
    assertThat(grupo.isAplicada()).isFalse();
    assertThat(grupo.getValorAntes()).isEqualTo(grupo.getValorDepois());
    assertThat(grupo.getMotivoNaoAplicada()).isEqualTo("grupo USO");
  }

  @Test
  void inspecaoDeDefeitoNuncaFicaNula() {
    EstadoProduto estado = new EstadoProduto();
    estado.setInspecaoDefeito(null);

    assertThat(estado.getInspecaoDefeito()).isEmpty();
    assertThat(estado.getGrauUso()).isNull();
    assertThat(estado.isAlegaDefeito()).isFalse();
  }
}
