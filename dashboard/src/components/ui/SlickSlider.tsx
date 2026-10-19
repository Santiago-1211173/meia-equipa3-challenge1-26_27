"use client";

import React, { useRef, useState, useCallback, useEffect } from "react";

export interface SliderOption<T = boolean> {
  label: string;
  value: T;
  tone?: "success" | "danger" | "warning" | "info";
  icon?: string;
}

export interface SlickSliderProps<T = boolean> {
  options: [SliderOption<T>, SliderOption<T>];
  value: T | null | undefined;
  onChange: (val: T) => void;
  ariaLabel: string;
  disabled?: boolean;
  className?: string;
  width?: string;
}

/**
 * SlickSlider: Um slider táctil, minimalista e fluido, com suporte para
 * clique direto nas extremidades, clique no track para alternar,
 * arrasto físico (drag/swipe) com pointer events e navegação completa por teclado.
 */
export default function SlickSlider<T = boolean>({
  options,
  value,
  onChange,
  ariaLabel,
  disabled = false,
  className = "",
  width = "w-full sm:w-[196px]",
}: SlickSliderProps<T>) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [isDragging, setIsDragging] = useState(false);
  const [dragProgress, setDragProgress] = useState<number | null>(null);

  const selectedIndex =
    value === options[0].value ? 0 :
    value === options[1].value ? 1 :
    -1;

  const hasSelection = selectedIndex >= 0;
  const activeOption = selectedIndex === 0 ? options[0] : selectedIndex === 1 ? options[1] : null;
  const activeTone = activeOption?.tone || "success";

  // Determinar estilos cromáticos com base no tom da opção ativa
  // Sem efeito de glow nem rings adicionais, mantendo design minimalista e consistente
  let thumbToneClasses = "bg-white text-emerald-800 border-slate-200/90 shadow-2xs";
  let activeIconColor = "text-emerald-600";
  let defaultIcon = "check";

  if (activeTone === "danger") {
    thumbToneClasses = "bg-white text-rose-700 border-rose-300 shadow-2xs";
    activeIconColor = "text-rose-600";
    defaultIcon = "close";
  } else if (activeTone === "warning") {
    thumbToneClasses = "bg-white text-amber-800 border-amber-300 shadow-2xs";
    activeIconColor = "text-amber-600";
    defaultIcon = "warning";
  } else if (activeTone === "info") {
    thumbToneClasses = "bg-white text-indigo-700 border-indigo-300 shadow-2xs";
    activeIconColor = "text-indigo-600";
    defaultIcon = "check";
  }

  // Lógica de arrasto físico (Pointer Events)
  const dragStartRef = useRef<{ startX: number; startIndex: number; trackWidth: number } | null>(null);

  const handlePointerDown = useCallback(
    (e: React.PointerEvent<HTMLDivElement>) => {
      if (disabled) return;
      if (e.button !== 0) return; // Apenas botão principal

      const container = containerRef.current;
      if (!container) return;

      container.setPointerCapture(e.pointerId);
      const rect = container.getBoundingClientRect();
      const clickIdx = e.clientX < rect.left + rect.width / 2 ? 0 : 1;

      dragStartRef.current = {
        startX: e.clientX,
        startIndex: selectedIndex >= 0 ? selectedIndex : clickIdx,
        trackWidth: rect.width,
      };

      setIsDragging(true);
      setDragProgress(selectedIndex === 1 ? 1 : 0);
    },
    [disabled, selectedIndex]
  );

  const handlePointerMove = useCallback(
    (e: React.PointerEvent<HTMLDivElement>) => {
      if (!isDragging || !dragStartRef.current) return;

      const { startX, startIndex, trackWidth } = dragStartRef.current;
      const deltaX = e.clientX - startX;
      const deltaProgress = deltaX / (trackWidth / 2); // deslocamento normalizado entre 0 e 1

      const initialProgress = startIndex === 0 ? 0 : 1;
      const newProgress = Math.min(1, Math.max(0, initialProgress + deltaProgress));

      setDragProgress(newProgress);
    },
    [isDragging]
  );

  const handlePointerUp = useCallback(
    (e: React.PointerEvent<HTMLDivElement>) => {
      if (!isDragging || !dragStartRef.current) return;

      const container = containerRef.current;
      if (container && container.hasPointerCapture(e.pointerId)) {
        container.releasePointerCapture(e.pointerId);
      }

      const { startX } = dragStartRef.current;
      const totalDelta = Math.abs(e.clientX - startX);

      // Se foi um clique quase estático (< 6px), alternar ou escolher baseado na posição do clique
      if (totalDelta < 6) {
        if (container) {
          const rect = container.getBoundingClientRect();
          const clickX = e.clientX - rect.left;
          const targetIndex = clickX < rect.width / 2 ? 0 : 1;
          onChange(options[targetIndex].value);
        }
      } else {
        // Se houve arrasto, verificar onde parou o indicador (threshold 0.5)
        const currentProg = dragProgress ?? (selectedIndex === 1 ? 1 : 0);
        const finalIndex = currentProg >= 0.5 ? 1 : 0;
        onChange(options[finalIndex].value);
      }

      setIsDragging(false);
      setDragProgress(null);
      dragStartRef.current = null;
    },
    [isDragging, dragProgress, selectedIndex, options, onChange]
  );

  const handlePointerCancel = useCallback(() => {
    setIsDragging(false);
    setDragProgress(null);
    dragStartRef.current = null;
  }, []);

  // Teclado (Acessibilidade)
  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (disabled) return;
    if (e.key === "ArrowLeft") {
      e.preventDefault();
      onChange(options[0].value);
    } else if (e.key === "ArrowRight") {
      e.preventDefault();
      onChange(options[1].value);
    } else if (e.key === " " || e.key === "Enter") {
      e.preventDefault();
      const nextIndex = selectedIndex === 0 ? 1 : 0;
      onChange(options[nextIndex].value);
    }
  };

  // Posição de translação do Thumb deslizante
  // 0% quando à esquerda, 100% quando à direita
  const currentTranslate = isDragging && dragProgress !== null
    ? `${dragProgress * 100}%`
    : selectedIndex === 1
    ? "100%"
    : "0%";

  return (
    <div
      ref={containerRef}
      role="radiogroup"
      aria-label={ariaLabel}
      tabIndex={disabled ? -1 : 0}
      onKeyDown={handleKeyDown}
      onPointerDown={handlePointerDown}
      onPointerMove={handlePointerMove}
      onPointerUp={handlePointerUp}
      onPointerCancel={handlePointerCancel}
      className={`relative h-[38px] sm:h-10 p-1 bg-slate-100 hover:bg-slate-200/60 border border-slate-200/90 rounded-xl select-none cursor-pointer touch-none transition-colors duration-150 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-600 focus-visible:ring-offset-2 shrink-0 ${width} ${
        disabled ? "opacity-50 cursor-not-allowed pointer-events-none" : "active:scale-[0.985]"
      } ${className}`}
    >
      {/* Sliding Thumb (só é renderizado quando há uma opção selecionada) */}
      {hasSelection && (
        <div
          aria-hidden="true"
          style={{
            transform: `translateX(${currentTranslate})`,
            transition: isDragging
              ? "none"
              : "transform 220ms cubic-bezier(0.16, 1, 0.3, 1), background-color 160ms ease, border-color 160ms ease, box-shadow 160ms ease",
          }}
          className={`absolute top-1 bottom-1 left-1 w-[calc(50%-4px)] rounded-lg pointer-events-none z-0 border shadow-[0_1px_3px_rgba(15,23,42,0.08),0_1px_2px_rgba(15,23,42,0.06)] flex items-center justify-center ${thumbToneClasses}`}
        />
      )}

      {/* Grid de 2 opções por cima do thumb */}
      <div className="relative z-10 grid grid-cols-2 w-full h-full">
        {options.map((opt, idx) => {
          const isSelected = selectedIndex === idx;
          const icon = opt.icon || (isSelected ? defaultIcon : undefined);

          return (
            <button
              key={String(opt.value)}
              type="button"
              role="radio"
              aria-checked={isSelected}
              disabled={disabled}
              onClick={(e) => {
                e.stopPropagation();
                onChange(opt.value);
              }}
              className={`font-sans h-full w-full rounded-md text-xs font-bold transition-colors duration-150 flex items-center justify-center gap-1.5 cursor-pointer focus:outline-none ${
                isSelected
                  ? "text-slate-900"
                  : "text-slate-500 hover:text-slate-700"
              }`}
            >
              {isSelected && (
                <span
                  className={`material-symbols-outlined text-[13px] font-bold animate-in fade-in zoom-in-75 duration-150 ${activeIconColor}`}
                >
                  {icon}
                </span>
              )}
              <span className="truncate">{opt.label}</span>
            </button>
          );
        })}
      </div>
    </div>
  );
}
