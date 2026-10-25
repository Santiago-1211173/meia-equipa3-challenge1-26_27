package com.levis.devolucoes.incerteza;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.regex.Pattern;
import java.util.stream.Stream;
import org.junit.jupiter.api.Test;

/**
 * Os parâmetros de incerteza são demonstrativos e só existem no ficheiro de parâmetros e nos FCL:
 * nenhum literal decimal no código Java do módulo (docs/08 §1.2.5; README, Convenções).
 */
class SemParametrosNoCodigoTest {

  private static final Pattern DECIMAL = Pattern.compile("(?<![\\w.])\\d+\\.\\d+");

  @Test
  void oCodigoJavaNaoTemLiteraisDecimais() throws IOException {
    try (Stream<Path> ficheiros = Files.walk(Path.of("src/main/java"))) {
      List<String> infracoes =
          ficheiros
              .filter(f -> f.toString().endsWith(".java"))
              .flatMap(SemParametrosNoCodigoTest::literais)
              .toList();
      assertThat(infracoes).isEmpty();
    }
  }

  private static boolean comentario(String linha) {
    String t = linha.trim();
    return t.startsWith("*") || t.startsWith("/*") || t.startsWith("//");
  }

  private static Stream<String> literais(Path ficheiro) {
    try {
      List<String> linhas = Files.readAllLines(ficheiro);
      return java.util.stream.IntStream.range(0, linhas.size())
          .filter(i -> !comentario(linhas.get(i)))
          .filter(i -> DECIMAL.matcher(linhas.get(i)).find())
          .mapToObj(i -> ficheiro.getFileName() + ":" + (i + 1) + " " + linhas.get(i).trim());
    } catch (IOException e) {
      throw new java.io.UncheckedIOException(e);
    }
  }
}
