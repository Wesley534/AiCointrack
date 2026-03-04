export async function POST(request: Request) {
  try {
    const body = await request.json()
    console.log("Webhook received:", JSON.stringify(body, null, 2))
    return Response.json({ success: true })
  } catch (error) {
    console.error("Webhook error:", error)
    return Response.json({ success: false }, { status: 400 })
  }
}

// Some validators do a GET check first
export async function GET() {
  return Response.json({ status: "webhook active" })
}
