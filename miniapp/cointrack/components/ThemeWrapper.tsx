"use client";

import { ReactNode, useEffect, useState } from "react";
import { useAppStore } from "@/store";
import { lightTheme, darkTheme } from "@/lib/constants";

export default function ThemeWrapper({ children }: { children: ReactNode }) {
  const { theme } = useAppStore();
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  // Before hydration, render dark theme to prevent flashing
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
