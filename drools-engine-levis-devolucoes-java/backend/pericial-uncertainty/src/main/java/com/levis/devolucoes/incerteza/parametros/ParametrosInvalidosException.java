package com.levis.devolucoes.incerteza.parametros;

import java.util.List;

/** O ficheiro de parâmetros de incerteza é inválido; a aplicação não arranca (docs/08 §5.2). */
public class ParametrosInvalidosException extends RuntimeException {

  private final List<String> erros;

  public ParametrosInvalidosException(String recurso, List<String> erros) {
    super("Parâmetros de incerteza inválidos em " + recurso + ": " + String.join("; ", erros));
    this.erros = List.copyOf(erros);
  }

  public List<String> erros() {
    return erros;
  }
}
