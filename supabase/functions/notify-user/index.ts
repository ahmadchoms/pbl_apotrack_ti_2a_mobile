import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const FCM_PROJECT_ID = Deno.env.get("FCM_PROJECT_ID") ?? ""
const FCM_CLIENT_EMAIL = Deno.env.get("FCM_CLIENT_EMAIL") ?? ""
const rawPrivateKey = Deno.env.get("FCM_PRIVATE_KEY") ?? ""
const cleanPrivateKey = rawPrivateKey.trim().replace(/^"/, "").replace(/"$/, "")
const FCM_PRIVATE_KEY = cleanPrivateKey.replace(/\\n/g, "\n")

async function getAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000)
  const jwt = await createJWT({
    aud: "https://oauth2.googleapis.com/token",
    iss: FCM_CLIENT_EMAIL,
    sub: FCM_CLIENT_EMAIL,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    iat: now,
    exp: now + 3600,
  })

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  })

  const data = await res.json()
  if (!data.access_token) {
    throw new Error("Failed to get Google OAuth token: " + JSON.stringify(data))
  }
  return data.access_token
}

async function createJWT(payload: Record<string, unknown>): Promise<string> {
  const header = { alg: "RS256", typ: "JWT" }
  const encoder = new TextEncoder()

  const headerB64 = btoa(
    String.fromCharCode(...new Uint8Array(encoder.encode(JSON.stringify(header)))),
  )
  const payloadB64 = btoa(
    String.fromCharCode(...new Uint8Array(encoder.encode(JSON.stringify(payload)))),
  )

  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToBinary(FCM_PRIVATE_KEY),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  )

  const signature = await crypto.subtle.sign(
    { name: "RSASSA-PKCS1-v1_5" },
    key,
    encoder.encode(`${headerB64}.${payloadB64}`),
  )

  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
  return `${headerB64}.${payloadB64}.${sigB64}`
}

function pemToBinary(pem: string): ArrayBuffer {
  const b64 = pem
    .replace(/-----BEGIN.*?-----/g, "")
    .replace(/-----END.*?-----/g, "")
    .replace(/\s/g, "")
  const binary = atob(b64)
  const bytes = new Uint8Array(binary.length)
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i)
  }
  return bytes.buffer
}

serve(async (req) => {
  try {
    const APOTRACK_INTERNAL_SECRET = Deno.env.get("APOTRACK_INTERNAL_SECRET") ?? ""
    const incomingSecret = req.headers.get("x-apotrack-secret")

    if (APOTRACK_INTERNAL_SECRET && incomingSecret !== APOTRACK_INTERNAL_SECRET) {
      console.warn("Unauthorized attempt to access notify-user function")
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      })
    }

    const { record } = await req.json()

    if (!record || !record.user_id) {
      return new Response(JSON.stringify({ error: "No user_id" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      })
    }

    // Cari FCM token user dari tabel device_tokens
    const deviceRes = await fetch(
      `${Deno.env.get("SUPABASE_URL")}/rest/v1/device_tokens?user_id=eq.${record.user_id}&select=fcm_token`,
      {
        headers: {
          apikey: Deno.env.get("SUPABASE_ANON_KEY") ?? "",
          Authorization: `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""}`,
        },
      },
    )

    const devices = await deviceRes.json()
    if (!deviceRes.ok || !Array.isArray(devices)) {
      console.error("Database query failed:", devices)
      return new Response(JSON.stringify({ error: "Database query failed", details: devices }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      })
    }

    if (devices.length === 0) {
      console.log("No FCM token found for user:", record.user_id)
      return new Response(JSON.stringify({ sent: false, reason: "no_token" }), {
        headers: { "Content-Type": "application/json" },
      })
    }

    const token = devices[0].fcm_token
    const accessToken = await getAccessToken()

    const fcmMessage = {
      message: {
        token,
        notification: {
          title: record.title || "Notifikasi ApoTrack",
          body: record.message || "Ada update buat kamu!",
        },
        data: {
          title: record.title || "Notifikasi ApoTrack",
          body: record.message || "Ada update buat kamu!",
          type: record.type || "",
          reference_type: record.reference_type || "",
          reference_id: record.reference_id || "",
          notification_id: record.id || "",
        },
        android: {
          priority: "HIGH",
          notification: {
            channel_id: "apotrack_notifications_v3",
            notification_priority: "PRIORITY_HIGH",
          },
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: record.title || "Notifikasi ApoTrack",
                body: record.message || "Ada update buat kamu!",
              },
              sound: "default",
            },
          },
        },
      },
    }

    const fcmRes = await fetch(
      `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify(fcmMessage),
      },
    )

    const result = await fcmRes.json()
    console.log("FCM result:", result)

    return new Response(JSON.stringify({ sent: fcmRes.ok, result }), {
      headers: { "Content-Type": "application/json" },
    })
  } catch (err) {
    console.error("Error:", err)
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    })
  }
})
