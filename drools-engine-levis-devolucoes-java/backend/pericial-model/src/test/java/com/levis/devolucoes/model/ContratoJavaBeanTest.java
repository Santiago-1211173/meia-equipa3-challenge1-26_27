package com.levis.devolucoes.model;

import static org.assertj.core.api.Assertions.assertThat;

import com.levis.devolucoes.model.decisao.Decisao;
import com.levis.devolucoes.model.decisao.DecisaoArtigo;
import com.levis.devolucoes.model.decisao.Documentacao;
import com.levis.devolucoes.model.decisao.IndicadorFraude;
import com.levis.devolucoes.model.decisao.RegistoRegra;
import com.levis.devolucoes.model.incerteza.Contribuicao;
import com.levis.devolucoes.model.incerteza.Evidencia;
import com.levis.devolucoes.model.incerteza.GrauCrenca;
import com.levis.devolucoes.model.pedido.Cliente;
import com.levis.devolucoes.model.pedido.Colaborador;
import com.levis.devolucoes.model.pedido.CompraOriginal;
import com.levis.devolucoes.model.pedido.Comprovativo;
import com.levis.devolucoes.model.pedido.Loja;
import com.levis.devolucoes.model.pedido.Pagamento;
import com.levis.devolucoes.model.pedido.PedidoDevolucao;
import com.levis.devolucoes.model.pedido.PedidoExcecao;
import com.levis.devolucoes.model.produto.ArtigoDevolvido;
import com.levis.devolucoes.model.produto.ArtigoTroca;
import com.levis.devolucoes.model.produto.EstadoProduto;
import com.levis.devolucoes.model.produto.Produto;
import java.beans.IntrospectionException;
import java.beans.Introspector;
import java.beans.PropertyDescriptor;
import java.lang.reflect.Field;
import java.lang.reflect.Modifier;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

/**
 * Contrato JavaBean dos factos: o Drools lê as propriedades nas regras e o Jackson clona os factos
 * no "E se" (Fase 5). Cada campo privado tem getter e setter, e o valor escrito é o valor lido.
 */
class ContratoJavaBeanTest {

  /** Campos internos que não são propriedades do facto. */
  private static final Set<String> CAMPOS_INTERNOS = Set.of("relogio");

  private static final Map<Class<?>, Function<Integer, Object>> VALORES =
      Map.ofEntries(
          Map.entry(String.class, n -> "valor-" + n),
          Map.entry(boolean.class, n -> true),
          Map.entry(Boolean.class, n -> Boolean.TRUE),
          Map.entry(int.class, n -> n),
          Map.entry(Integer.class, n -> n),
          Map.entry(double.class, n -> n + 0.25),
          Map.entry(Map.class, n -> new LinkedHashMap<>(Map.of("ED-0" + n, Boolean.TRUE))),
          Map.entry(BigDecimal.class, n -> new BigDecimal(n + ".50")),
          Map.entry(LocalDate.class, n -> LocalDate.of(2026, 1, 1).plusDays(n)),
          Map.entry(LocalDateTime.class, n -> LocalDateTime.of(2026, 1, 1, 10, 0).plusMinutes(n)),
          Map.entry(List.class, n -> new ArrayList<>(List.of())),
          Map.entry(Set.class, n -> new HashSet<>(Set.of("sku-" + n))));

  @ParameterizedTest
  @ValueSource(
      classes = {
        PedidoDevolucao.class,
        Loja.class,
        Colaborador.class,
        Cliente.class,
        CompraOriginal.class,
        Comprovativo.class,
        Pagamento.class,
        PedidoExcecao.class,
        Produto.class,
        ArtigoDevolvido.class,
        ArtigoTroca.class,
        EstadoProduto.class,
        Decisao.class,
        DecisaoArtigo.class,
        Documentacao.class,
        RegistoRegra.class,
        IndicadorFraude.class,
        Evidencia.class,
        GrauCrenca.class,
        Contribuicao.class
      })
  void cadaCampoEUmaPropriedadeLegivelEEscrevivel(Class<?> classe) throws Exception {
    Map<String, PropertyDescriptor> propriedades = propriedades(classe);

    for (String campo : campos(classe)) {
      assertThat(propriedades)
          .as("%s.%s tem getter e setter", classe.getSimpleName(), campo)
          .containsKey(campo);
      PropertyDescriptor descritor = propriedades.get(campo);
      assertThat(descritor.getReadMethod()).as("getter de %s", campo).isNotNull();
      assertThat(descritor.getWriteMethod()).as("setter de %s", campo).isNotNull();
    }

    Object instancia = classe.getDeclaredConstructor().newInstance();
    int n = 1;
    for (PropertyDescriptor descritor : propriedades.values()) {
      if (descritor.getWriteMethod() == null || descritor.getReadMethod() == null) {
        continue;
      }
      Object valor = valorPara(descritor.getPropertyType(), n++);
      descritor.getWriteMethod().invoke(instancia, valor);
      assertThat(descritor.getReadMethod().invoke(instancia))
          .as("%s.%s", classe.getSimpleName(), descritor.getName())
          .isEqualTo(valor);
    }
  }

  private static Map<String, PropertyDescriptor> propriedades(Class<?> classe)
      throws IntrospectionException {
    return Arrays.stream(Introspector.getBeanInfo(classe, Object.class).getPropertyDescriptors())
        .collect(Collectors.toMap(PropertyDescriptor::getName, Function.identity()));
  }

  private static List<String> campos(Class<?> classe) {
    List<String> nomes = new ArrayList<>();
    for (Class<?> c = classe; c != Object.class; c = c.getSuperclass()) {
      for (Field campo : c.getDeclaredFields()) {
        if (!Modifier.isStatic(campo.getModifiers())
            && !CAMPOS_INTERNOS.contains(campo.getName())) {
          nomes.add(campo.getName());
        }
      }
    }
    return nomes;
  }

  private static Object valorPara(Class<?> tipo, int n) throws Exception {
    if (VALORES.containsKey(tipo)) {
      return VALORES.get(tipo).apply(n);
    }
    if (tipo.isEnum()) {
      Object[] constantes = tipo.getEnumConstants();
      return constantes[n % constantes.length];
    }
    if (tipo == Clock.class) {
      return Clock.systemUTC();
    }
    // Outras classes do modelo
    return tipo.getDeclaredConstructor().newInstance();
  }
}
