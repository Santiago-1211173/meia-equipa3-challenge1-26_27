import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Expert System Diagnostic Dashboard | MEIA 2026/2027",
  description: "Retail Returns & Exchanges Diagnostic Expert System - Equipa 3",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="pt-PT">
      <body>{children}</body>
    </html>
  );
}
