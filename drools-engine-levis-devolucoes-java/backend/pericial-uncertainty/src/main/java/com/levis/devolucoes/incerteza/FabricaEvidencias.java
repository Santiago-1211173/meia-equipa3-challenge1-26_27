package com.levis.devolucoes.incerteza;

import com.levis.devolucoes.model.enums.FonteEvidencia;
import com.levis.devolucoes.model.incerteza.Evidencia;
import com.levis.devolucoes.model.pedido.Cliente;
import com.levis.devolucoes.model.pedido.PedidoDevolucao;
import com.levis.devolucoes.model.produto.ArtigoDevolvido;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

/**
 * Evidências que vêm das respostas do colaborador e do catálogo (docs/08 §5.4), criadas a partir do
 * pedido para que a avaliação, a simulação e o "Porque não?" vejam as mesmas (ADR 0012). As
 * evidências derivadas dos factos são inseridas pelas regras IU-01 a IU-07.
 *
 * <p>O comportamento do cliente (agitado, contesta, barreira linguística, fornece dados) nunca é
 * evidência (docs/08 §1.2.3).
 */
public class FabricaEvidencias {

  /** Perguntas de inspeção respondidas pelo colaborador (Sim / Não / Não sei). */
  public static final Set<String> INSPECAO_COLABORADOR =
      Set.of("ED-01", "ED-02", "ED-05", "ED-06", "ED-07");

  private final ServicoIncerteza incerteza;

  public FabricaEvidencias(ServicoIncerteza incerteza) {
    this.incerteza = incerteza;
  }

  public List<Evidencia> evidencias(PedidoDevolucao pedido) {
    List<Evidencia> evidencias = new ArrayList<>();
    Cliente cliente = pedido.getCliente();
    if (cliente != null && cliente.getExplicaOrigemCompra() != null) {
      // EF-04 está presente quando o cliente NÃO explica onde e quando comprou
      evidencias.add(
          incerteza.evidenciaFraude(
              "EF-04",
              pedido.getId(),
              !cliente.getExplicaOrigemCompra(),
              FonteEvidencia.COLABORADOR));
    }
    if (pedido.getArtigos() != null) {
      for (ArtigoDevolvido artigo : pedido.getArtigos()) {
        evidenciasDefeito(pedido.getId(), artigo, evidencias);
      }
    }
    return evidencias;
  }

  private void evidenciasDefeito(String pedidoId, ArtigoDevolvido artigo, List<Evidencia> lista) {
    if (artigo.getEstado() == null || !artigo.getEstado().isAlegaDefeito()) {
      return;
    }
    artigo
        .getEstado()
        .getInspecaoDefeito()
        .forEach(
            (codigo, presente) -> {
              if (INSPECAO_COLABORADOR.contains(codigo)) {
                lista.add(
                    incerteza.evidenciaDefeito(
                        codigo, pedidoId, artigo.getId(), presente, FonteEvidencia.COLABORADOR));
              }
            });
    if (artigo.getProduto() != null) {
      lista.add(
          incerteza.evidenciaDefeito(
              "ED-04",
              pedidoId,
              artigo.getId(),
              artigo.getProduto().isDefeitoConhecido(),
              FonteEvidencia.CATALOGO));
    }
  }
}
