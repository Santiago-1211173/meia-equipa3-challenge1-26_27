/**
 * O frontend é agnóstico de marca. Os valores de enum do motor que nomeiam a marca são
 * trocados por aliases neutros à saída e repostos à entrada, para os pedidos continuarem
 * válidos. O texto livre é apenas reescrito (nunca é reenviado como dado).
 */
const ENUM_ALIASES: Record<string, string> = {
  LEVIS: "MARCA_PRINCIPAL",
  DOCKERS: "MARCA_ASSOCIADA_A",
  LS_SIGNATURE: "MARCA_ASSOCIADA_B",
  BEYOND_YOGA: "MARCA_ASSOCIADA_C",
  LEVI_COM: "SITE_PROPRIO",
  LEVI_CA: "SITE_PROPRIO_CA",
};

const REVERSE_ALIASES = Object.fromEntries(
  Object.entries(ENUM_ALIASES).map(([engineValue, alias]) => [alias, engineValue])
);

// Limites de palavra (\b) em todas as regras: "televisão" contém "levi" e não pode ser tocada.
const TEXT_RULES: [RegExp, string][] = [
  [/\blevi\.com\b/gi, "o site da Marca"],
  [/\blevi strauss( & co\.?)?/gi, "a Empresa"],
  [/\blevi['’]?s\b/gi, "Marca"],
  [/\bdockers\b/gi, "uma marca associada"],
  [/\blevi\b/gi, "Marca"],
];

function neutralText(text: string): string {
  return TEXT_RULES.reduce((acc, [pattern, replacement]) => acc.replace(pattern, replacement), text);
}

function walk(value: unknown, mapString: (text: string) => string): unknown {
  if (typeof value === "string") return mapString(value);
  if (Array.isArray(value)) return value.map((item) => walk(item, mapString));
  if (value && typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value).map(([key, item]) => [key, walk(item, mapString)])
    );
  }
  return value;
}

/** Resposta do motor para o browser: aliases nos enums, texto livre reescrito. */
export function toNeutral<T>(payload: T): T {
  return walk(payload, (text) => ENUM_ALIASES[text] ?? neutralText(text)) as T;
}

/** Pedido do browser para o motor: repõe os valores de enum originais. */
export function toEngine<T>(payload: T): T {
  return walk(payload, (text) => REVERSE_ALIASES[text] ?? text) as T;
}
