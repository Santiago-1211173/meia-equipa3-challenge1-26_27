export default function EmptyState({ title, hint }: { title: string; hint?: string }) {
  return (
    <div className="empty-state">
      <p className="font-sans">
        <strong>{title}</strong>
      </p>
      {hint && <p className="font-sans">{hint}</p>}
    </div>
  );
}
