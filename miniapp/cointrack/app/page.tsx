"use client"

import AppHomePage from "@/app/(app)/page"
import { RootProvider } from "@/app/rootProvider"

export default function Page() {
  return (
    <RootProvider>
      <AppHomePage />
    </RootProvider>
  )
}