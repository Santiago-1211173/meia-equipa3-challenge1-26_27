"use client";

import React, { ReactNode } from "react";

export interface SectionCardProps {
  number: number | string;
  title: string;
  description?: string;
  badge?: string;
  children: ReactNode;
  className?: string;
}

export default function SectionCard({
  number,
  title,
  description,
  badge,
  children,
  className = "",
}: SectionCardProps) {
  return (
    <section
      aria-labelledby={`section-title-${number}`}
      className={`card-tactile p-6 md:p-8 bg-surface-container-lowest w-full flex flex-col gap-5 ${className}`}
    >
      {/* Section Header */}
      <div className="flex items-center justify-between border-b border-border-card pb-4">
        <div className="flex items-center gap-3.5">
          <span className="font-mono tabular-nums font-bold w-8 h-8 rounded-full bg-primary-fixed text-on-primary-fixed flex items-center justify-center text-sm shadow-sm select-none">
            {number}
          </span>
          <div className="flex flex-col">
            <h3
              id={`section-title-${number}`}
              className="font-sans font-bold text-on-surface tracking-tight"
            >
              {title}
            </h3>
            {description && (
              <p className="font-sans font-body-md text-on-surface-variant text-xs mt-0.5">
                {description}
              </p>
            )}
          </div>
        </div>

        {badge && (
          <span className="font-sans px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider bg-surface-container text-primary border border-primary-container/20 select-none">
            {badge}
          </span>
        )}
      </div>

      {/* Section Body */}
      <div className="w-full">{children}</div>
    </section>
  );
}
