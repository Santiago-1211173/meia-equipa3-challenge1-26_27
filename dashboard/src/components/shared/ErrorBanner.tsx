export default function ErrorBanner({
  message,
  onRetry,
}: {
  message: string;
  onRetry?: () => void;
}) {
  return (
    <div
      role="alert"
      className="p-4 rounded-2xl bg-rose-50 border border-rose-200 text-rose-800 text-sm flex items-center justify-between gap-3 shadow-xs animate-in fade-in duration-150"
    >
      <div className="flex items-center gap-2">
        <span className="material-symbols-outlined text-rose-600 text-[20px]">
          error
        </span>
        <span className="font-sans font-medium">{message}</span>
      </div>
      {onRetry && (
        <button
          type="button"
          onClick={onRetry}
          className="btn-tactile-secondary px-3 py-1.5 text-xs font-sans font-bold"
        >
          Tentar novamente
        </button>
      )}
    </div>
  );
}

