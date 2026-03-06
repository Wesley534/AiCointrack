"use client";

import { ReactNode, useEffect, useRef, useState } from "react";
import { useAppStore } from "@/store";
import { lightTheme, darkTheme } from "@/lib/constants";

export default function ThemeWrapper({ children }: { children: ReactNode }) {
  const { theme } = useAppStore();
  const [mounted, setMounted] = useState(false);
  const erudaInitialized = useRef(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  // Initialize Eruda once only — never re-run on re-renders
  useEffect(() => {
    if (
      erudaInitialized.current ||
      typeof window === "undefined" ||
      window.location.hostname.includes("localhost")
    ) return

    erudaInitialized.current = true
    import("eruda").then((eruda) => eruda.default.init())
  }, []) // ← empty deps, runs once on mount only

  const resolvedTheme = mounted ? theme : "dark";
  const colors = resolvedTheme === "light" ? lightTheme : darkTheme;
  const bg = resolvedTheme === "light" ? colors.bg : (colors.surface ?? colors.bg);

  useEffect(() => {
    document.documentElement.setAttribute("data-theme", theme);
  }, [theme]);

  return (
    <div
      style={{
        minHeight: "100vh",
        width: "100%",
        background: bg,
        position: "relative",
      }}
    >
      {children}
    </div>
  );
}