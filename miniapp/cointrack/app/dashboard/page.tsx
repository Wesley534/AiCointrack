"use client"
import HomeTab from "@/components/home/HomeTab"
import { useAppStore } from "@/store"
import { lightTheme, darkTheme } from "@/lib/constants"

export default function DashboardPage() {
    const { theme } = useAppStore()
    const colors = theme === "light" ? lightTheme : darkTheme

    return (
        <div style={{
            background: colors.bg || colors.surface,
            minHeight: "100vh",
        }}>
            <HomeTab />
        </div>
    )
}
