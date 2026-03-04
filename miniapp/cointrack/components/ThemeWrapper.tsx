"use client";

import { ReactNode, useEffect } from "react";
import { useAppStore } from "@/store";
import { lightTheme, darkTheme } from "@/lib/constants";

export default function ThemeWrapper({ children }: { children: ReactNode }) {
  const { theme } = useAppStore();
  const colors = theme === "light" ? lightTheme : darkTheme;
  const bg = theme === "light" ? colors.bg : (colors.surface ?? colors.bg);

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
