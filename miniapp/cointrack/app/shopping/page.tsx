"use client"
import { useState } from "react"
import TopBar from "@/components/layout/TopBar"
import ShoppingListCard from "@/components/shopping/ShoppingListCard"
import CreateListSheet from "@/components/shopping/CreateListSheet"
import { useShoppingLists } from "@/hooks/useShoppingLists"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"

export default function ShoppingPage() {
  const [showCreateSheet, setShowCreateSheet] = useState(false)
  const { data, isLoading, refetch } = useShoppingLists()
  const { theme } = useAppStore()
  const colors = theme === "light" ? lightTheme : darkTheme

  if (isLoading) {
    return (
      <div>
        <TopBar title="Shopping Lists" />
        <div style={{ padding: 20, textAlign: "center", color: colors.muted }}>
          Loading shopping lists...
        </div>
      </div>
    )
  }

  const lists = data?.lists || []

  return (
    <div>
      <TopBar title="Shopping Lists" />
      <div style={{ paddingTop: 20, paddingBottom: 100 }}>
        <div style={{ padding: "0 20px 20px" }}>
          <div
            style={{
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center",
              marginBottom: 16,
            }}
          >
            <div
              style={{
                fontFamily: "Syne, sans-serif",
                fontWeight: 700,
                fontSize: 16,
              }}
            >
              Your Lists
            </div>
            <button
              onClick={() => setShowCreateSheet(true)}
              style={{
                background: colors.accent,
                color: "#fff",
                border: "none",
                borderRadius: 8,
                padding: "8px 16px",
                fontFamily: "Syne, sans-serif",
                fontWeight: 600,
                fontSize: 14,
                cursor: "pointer",
              }}
            >
              + New List
            </button>
          </div>

          {lists.length === 0 ? (
            <div
              style={{
                textAlign: "center",
                padding: 40,
                color: colors.muted,
              }}
            >
              No shopping lists yet. Create one to get started!
            </div>
          ) : (
            <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
              {lists.map((list: { id: number; name: string; budget: number; items: Array<{ name: string; qty: number; price: number }> }) => (
                <ShoppingListCard key={list.id} list={list} />
              ))}
            </div>
          )}
        </div>
      </div>

      <CreateListSheet
        isOpen={showCreateSheet}
        onClose={() => setShowCreateSheet(false)}
        onSuccess={refetch}
      />
    </div>
  )
}
