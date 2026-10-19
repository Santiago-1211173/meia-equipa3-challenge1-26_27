export default function RequestEditor({
  value,
  error,
  onChange,
}: {
  value: string;
  error: string | null;
  onChange: (value: string) => void;
}) {
  return (
    <details className="request-editor font-sans">
      <summary>Editar o pedido completo (avançado)</summary>
      <p className="field-hint">
        Altere qualquer campo do pedido em JSON. A avaliação usa exatamente este conteúdo.
      </p>
      <label className="sr-only" htmlFor="request-json">
        Pedido em JSON
      </label>
      <textarea
        id="request-json"
        className="form-textarea font-mono font-medium text-xs tabular-nums"
        rows={14}
        spellCheck={false}
        value={value}
        onChange={(event) => onChange(event.target.value)}
        aria-invalid={error !== null}
        aria-describedby={error ? "request-json-error" : undefined}
      />
      {error && (
        <p id="request-json-error" className="field-hint field-error" role="alert">
          {error}
        </p>
      )}
    </details>
  );
}
