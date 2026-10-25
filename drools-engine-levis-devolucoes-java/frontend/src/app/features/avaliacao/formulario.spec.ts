import openapi from '../../../../openapi/openapi.json';
import { semIndices } from '../../shared/caminhos';
import { Campo, GRUPOS, PASSOS, caminhoCompleto } from './formulario';

interface Esquema {
  type?: string;
  $ref?: string;
  enum?: string[];
  items?: Esquema;
  properties?: Record<string, Esquema>;
  additionalProperties?: Esquema;
}

const esquemas = (openapi as unknown as { components: { schemas: Record<string, Esquema> } })
  .components.schemas;

function resolver(e: Esquema): Esquema {
  return e.$ref ? esquemas[e.$ref.split('/').pop()!] : e;
}

/** Folhas do pedido da API (caminho sem índices → esquema). */
function folhas(
  e: Esquema,
  prefixo = '',
  resultado = new Map<string, Esquema>(),
): Map<string, Esquema> {
  for (const [nome, propriedade] of Object.entries(resolver(e).properties ?? {})) {
    const caminho = prefixo ? `${prefixo}.${nome}` : nome;
    const p = resolver(propriedade);
    if (p.properties) {
      folhas(p, caminho, resultado);
    } else if (p.type === 'array' && p.items && resolver(p.items).properties) {
      folhas(resolver(p.items), caminho, resultado);
    } else {
      resultado.set(caminho, p);
    }
  }
  return resultado;
}

const camposDoFormulario = new Map<string, Campo>(
  GRUPOS.flatMap((g) =>
    g.campos.map((c) => [semIndices(caminhoCompleto(g, c)), c] as [string, Campo]),
  ),
);

describe('formulário do pedido', () => {
  const api = folhas(esquemas['PedidoAvaliacaoRequest']);
  /** Mapas da API (ex.: respostas de inspeção): um campo no formulário por chave. */
  const mapas = [...api].filter(([, e]) => e.type === 'object' && e.additionalProperties);
  const doMapa = (caminho: string) => mapas.find(([m]) => caminho.startsWith(`${m}.`))?.[0];

  it('tem um campo para cada dado do pedido da API, e só esses', () => {
    const doFormulario = new Set([...camposDoFormulario.keys()].map((c) => doMapa(c) ?? c));
    expect([...doFormulario].sort()).toEqual([...api.keys()].sort());
  });

  it('pergunta cada chave dos mapas com os valores do enum da API', () => {
    expect(mapas.length).toBeGreaterThan(0);
    for (const [mapa, esquema] of mapas) {
      const valores = resolver(esquema.additionalProperties!).enum!;
      const campos = [...camposDoFormulario].filter(([c]) => c.startsWith(`${mapa}.`));
      expect(campos.length, mapa).toBeGreaterThan(0);
      for (const [caminho, campo] of campos) {
        expect(Object.keys(campo.opcoes!).sort(), caminho).toEqual([...valores].sort());
      }
    }
  });

  it('oferece exatamente os valores de cada enum da API', () => {
    for (const [caminho, esquema] of api) {
      const campo = camposDoFormulario.get(caminho);
      if (esquema.enum && campo) {
        expect(campo.tipo, caminho).toBe('opcoes');
        expect(Object.keys(campo.opcoes!).sort(), caminho).toEqual([...esquema.enum].sort());
      }
    }
  });

  it('usa o tipo de controlo que corresponde ao tipo da API', () => {
    for (const [caminho, esquema] of api) {
      const tipo = camposDoFormulario.get(caminho)?.tipo;
      if (esquema.type === 'boolean') {
        expect(['booleano', 'booleano-opcional'], caminho).toContain(tipo);
      } else if (esquema.type === 'number') {
        expect(tipo, caminho).toBe('decimal');
      } else if (esquema.type === 'integer') {
        expect(['inteiro', 'escala'], caminho).toContain(tipo);
      } else if (esquema.type === 'array') {
        expect(tipo, caminho).toBe('lista');
      }
    }
  });

  it('identifica cada grupo e cada passo de forma única', () => {
    expect(new Set(GRUPOS.map((g) => g.id)).size).toBe(GRUPOS.length);
    expect(new Set(PASSOS.map((p) => p.id)).size).toBe(PASSOS.length);
  });
});
