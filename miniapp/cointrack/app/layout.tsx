import type { Metadata } from "next";
import { minikitConfig } from "@/minikit.config";
import "./globals.css";

export async function generateMetadata(): Promise<Metadata> {
  return {
    title: minikitConfig.miniapp.name,
    description: minikitConfig.miniapp.description,
    other: {
      "fc:miniapp": JSON.stringify({
        version: minikitConfig.miniapp.version,
        imageUrl: minikitConfig.miniapp.heroImageUrl,
        button: {
          title: `Launch ${minikitConfig.miniapp.name}`,
          action: {
            name: `Launch ${minikitConfig.miniapp.name}`,
            type: "launch_miniapp",
          },
        },
      }),
    },
  };
}

const themeScript = `(function(){var t=localStorage.getItem("cointrack_theme");t==="light"||t==="dark"?document.documentElement.setAttribute("data-theme",t):document.documentElement.setAttribute("data-theme","dark");})();`;

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <script dangerouslySetInnerHTML={{ __html: themeScript }} />
      </head>
      <body style={{ margin: 0, padding: 0, fontFamily: "'Outfit', sans-serif" }}>
        {children}
      </body>
    </html>
  );
}
