import { ReactNode } from "react";
import { FlutterLoginProvider } from "./flutterLoginProvider";

export default function Layout({ children }: { children: ReactNode }) {
  return (
    <FlutterLoginProvider>
      {children}
    </FlutterLoginProvider>
  );
}
