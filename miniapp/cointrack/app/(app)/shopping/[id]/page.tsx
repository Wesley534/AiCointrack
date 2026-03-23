"use client"
import { useState, useEffect, useCallback } from "react"
import { useParams } from "next/navigation"
import TopBar from "@/components/layout/TopBar"
import AddItemSheet from "@/components/shopping/AddItemSheet"
import { getShoppingList } from "@/lib/api"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"
import { formatUSD } from "@/lib/format"

interface ShoppingListDetail {
  title: string
  total: number
  remaining: number
  items: Array<{ name: string; qty: number; price: number }>
}

export default function ShoppingListDetailPage() {
  const params = useParams<{ id: string }>()
  const { theme } = useAppStore()
  const colors = theme === "light" ? lightTheme : darkTheme
  const [list, setList] = useState<ShoppingListDetail | null>(null)
  const [loading, setLoading] = useState(true)
  const [showAddItem, setShowAddItem] = useState(false)

  const fetchList = useCallback(async () => {
    try {
      const { data } = await getShoppingList(parseInt(params?.id ?? "0"))
      setList(data)
    } catch (err) {
      console.error("Failed to fetch list:", err)
    } finally {
      setLoading(false)
    }
  }, [params?.id])

  useEffect(() => {
    fetchList()
  }, [fetchList])

  if (loading) {
    return (
      <div>
        <TopBar title="Loading..." />
        <div style={{ padding: 20, textAlign: "center", color: colors.muted }}>
          Loading list...
        </div>
      </div>
    )
  }

  if (!list) {
    return (
      <div>
        <TopBar title="Not Found" />
        <div style={{ padding: 20, textAlign: "center", color: colors.muted }}>
          Shopping list not found
        </div>
      </div>
    )
  }

  const percentUsed = list.total + list.remaining > 0
    ? (list.total / (list.total + list.remaining)) * 100
    : 0

  return (
    <div>
      <TopBar title={list.title} />
      <div style={{ paddingTop: 20, paddingBottom: 100 }}>
        {/* Budget Summary */}
        <div
          style={{
            margin: "0 20px 20px",
            padding: 20,
            background: colors.card,
            borderRadius: 12,
            border: `1px solid ${colors.border}`,
          }}
        >
          <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 12 }}>
            <div>
              <div style={{ fontSize: 12, color: colors.muted, marginBottom: 4 }}>
                Total Spent
              </div>
              <div
                style={{
                  fontFamily: "Syne, sans-serif",
                  fontWeight: 700,
                  fontSize: 24,
                  color: colors.text,
                }}
              >
                {formatUSD(list.total)}
              </div>
            </div>
            <div style={{ textAlign: "right" }}>
              <div style={{ fontSize: 12, color: colors.muted, marginBottom: 4 }}>
                Remaining
              </div>
              <div
                style={{
                  fontFamily: "Syne, sans-serif",
                  fontWeight: 700,
                  fontSize: 24,
                  color: list.remaining < 0 ? colors.red : colors.positive,
                }}
              >
                {formatUSD(list.remaining)}
              </div>
            </div>
          </div>

          <div
            style={{
              width: "100%",
              height: 8,
              background: colors.border,
              borderRadius: 4,
              overflow: "hidden",
            }}
          >
            <div
              style={{
                height: "100%",
                width: `${Math.min(percentUsed, 100)}%`,
                background: list.remaining < 0 ? colors.red : colors.accent,
                transition: "width 0.3s",
              }}
            />
          </div>
        </div>

        {/* Items List */}
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
              Items ({list.items.length})
            </div>
            <button
              onClick={() => setShowAddItem(true)}
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
              + Add Item
            </button>
          </div>

          {list.items.length === 0 ? (
            <div
              style={{
                textAlign: "center",
                padding: 40,
                color: colors.muted,
              }}
            >
              No items yet. Add your first item!
            </div>
          ) : (
            <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
              {list.items.map((item: { name: string; qty: number; price: number }, index: number) => (
                <div
                  key={index}
                  style={{
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "center",
                    padding: 12,
                    background: colors.card,
                    borderRadius: 8,
                    border: `1px solid ${colors.border}`,
                  }}
                >
                  <div>
                    <div
                      style={{
                        fontWeight: 600,
                        fontSize: 14,
                        color: colors.text,
                        marginBottom: 2,
                      }}
                    >
                      {item.name}
                    </div>
                    <div style={{ fontSize: 12, color: colors.muted }}>
                      Qty: {item.qty}
                    </div>
                  </div>
                  <div
                    style={{
                      fontFamily: "Syne, sans-serif",
                      fontWeight: 700,
                      fontSize: 14,
                      color: colors.text,
                    }}
                  >
                    {formatUSD(item.price * item.qty)}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      <AddItemSheet
        isOpen={showAddItem}
        onClose={() => setShowAddItem(false)}
        listId={parseInt(params?.id ?? "0")}
        onSuccess={fetchList}
      />
    </div>
  )
}
