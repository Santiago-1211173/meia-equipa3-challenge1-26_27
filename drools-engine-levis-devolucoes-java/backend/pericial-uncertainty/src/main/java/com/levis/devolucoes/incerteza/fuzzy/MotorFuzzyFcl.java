package com.levis.devolucoes.incerteza.fuzzy;

import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.concurrent.ConcurrentHashMap;
import net.sourceforge.jFuzzyLogic.FIS;
import net.sourceforge.jFuzzyLogic.FunctionBlock;
import net.sourceforge.jFuzzyLogic.rule.Rule;
import net.sourceforge.jFuzzyLogic.rule.RuleBlock;
import net.sourceforge.jFuzzyLogic.rule.RuleTerm;
import net.sourceforge.jFuzzyLogic.rule.Variable;

/**
 * Motor fuzzy sobre o jFuzzyLogic (FCL, norma IEC 61131-7). Cada ficheiro é lido uma vez; como o
 * bloco de funções do jFuzzyLogic guarda estado, cada avaliação é exclusiva sobre esse bloco.
 */
public class MotorFuzzyFcl implements MotorFuzzy {

  private final Map<String, FunctionBlock> blocos = new ConcurrentHashMap<>();

  @Override
  public ResultadoFuzzy avaliar(String fcl, Map<String, Double> entradas) {
    FunctionBlock bloco = blocos.computeIfAbsent(fcl, MotorFuzzyFcl::carregar);
    synchronized (bloco) {
      for (Variable variavel : bloco.getVariables().values()) {
        if (variavel.isInput()) {
          Double valor = entradas.get(variavel.getName());
          if (valor == null) {
            throw new IllegalArgumentException(
                "Falta a entrada " + variavel.getName() + " para " + fcl);
          }
          bloco.setVariable(variavel.getName(), valor);
        }
      }
      bloco.evaluate();
      return resultado(bloco);
    }
  }

  private static ResultadoFuzzy resultado(FunctionBlock bloco) {
    double valor = Double.NaN;
    Map<String, Map<String, Double>> pertencas = new LinkedHashMap<>();
    for (Variable variavel : bloco.getVariables().values()) {
      if (variavel.isOutput()) {
        valor = variavel.getValue();
      } else if (variavel.isInput()) {
        Map<String, Double> termos = new TreeMap<>();
        for (String termo : variavel.getLinguisticTerms().keySet()) {
          double pertenca = variavel.getMembership(termo);
          if (pertenca > 0) {
            termos.put(termo, pertenca);
          }
        }
        pertencas.put(variavel.getName(), termos);
      }
    }
    List<RegraAtivada> regras = new ArrayList<>();
    for (RuleBlock blocoRegras : bloco.getRuleBlocks().values()) {
      for (Rule regra : blocoRegras.getRules()) {
        if (regra.getDegreeOfSupport() > 0) {
          RuleTerm consequente = regra.getConsequents().getFirst();
          regras.add(
              new RegraAtivada(
                  regra.getName(),
                  regra.getDegreeOfSupport(),
                  consequente.getVariable().getName() + " é " + consequente.getTermName()));
        }
      }
    }
    return new ResultadoFuzzy(valor, pertencas, regras);
  }

  private static FunctionBlock carregar(String fcl) {
    try (InputStream entrada = MotorFuzzyFcl.class.getClassLoader().getResourceAsStream(fcl)) {
      if (entrada == null) {
        throw new IllegalArgumentException("Ficheiro FCL inexistente: " + fcl);
      }
      FIS fis = FIS.load(entrada, false);
      if (fis == null || !fis.iterator().hasNext()) {
        throw new IllegalArgumentException("Ficheiro FCL inválido: " + fcl);
      }
      return fis.iterator().next();
    } catch (IOException e) {
      throw new UncheckedIOException(e);
    }
  }
}
