package com.levis.devolucoes.service.incerteza;

import com.levis.devolucoes.dto.incerteza.ParametrosIncertezaResponse;
import com.levis.devolucoes.incerteza.ServicoIncerteza;
import com.levis.devolucoes.incerteza.parametros.ParametrosIncerteza;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.TreeMap;
import org.springframework.stereotype.Service;

/** Parâmetros da camada de incerteza em vigor, para consulta (docs/08 §7.1). */
@Service
public class ParametrosIncertezaService {

  private final ServicoIncerteza incerteza;

  public ParametrosIncertezaService(ServicoIncerteza incerteza) {
    this.incerteza = incerteza;
  }

  public ParametrosIncertezaResponse parametros() {
    ParametrosIncerteza p = incerteza.parametros();
    var fraude = p.fatoresCerteza().fraude();
    var defeito = p.bayes().defeitoFabrico();
    var revendibilidade = p.fuzzy().revendibilidade();
    var credito = p.fuzzy().creditoPt004();

    Map<String, Double> cf = new TreeMap<>();
    fraude.evidencias().forEach((codigo, e) -> cf.put(codigo, e.cf()));
    Map<String, Double> lr = new TreeMap<>();
    defeito.evidencias().forEach((codigo, e) -> lr.put(codigo, e.lr()));

    Map<String, Double> limiares = new LinkedHashMap<>();
    limiares.put("fraude.medio", fraude.limiares().medio());
    limiares.put("fraude.alto", fraude.limiares().alto());
    limiares.put("defeito.rever", defeito.limiares().rever());
    limiares.put("defeito.proporPc006", defeito.limiares().proporPc006());
    limiares.put("revendibilidade.indeterminada", revendibilidade.limiares().indeterminada());
    limiares.put("revendibilidade.revendivel", revendibilidade.limiares().revendivel());
    limiares.put("credito.aCriterio", credito.limiares().aCriterio());
    limiares.put("credito.recomendado", credito.limiares().recomendado());

    Map<String, String> fcl = new LinkedHashMap<>();
    fcl.put("revendibilidade", revendibilidade.fcl());
    fcl.put("creditoPt004", credito.fcl());

    return new ParametrosIncertezaResponse(
        p.versao(), p.demonstrativo(), cf, lr, defeito.prior(), limiares, fcl);
  }
}
