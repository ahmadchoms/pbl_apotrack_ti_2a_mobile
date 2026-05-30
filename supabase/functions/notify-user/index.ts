import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
// Ganti bagian pengambilan key menjadi seperti ini:
const privateKey = Deno.env.get('FCM_PRIVATE_KEY')!.replace(/\\n/g, '\n');
const clientEmail = Deno.env.get('FCM_CLIENT_EMAIL');
const projectId = Deno.env.get('FCM_PROJECT_ID');
async function getAccessToken(): Promise<string> {
  const jwt = await createJWT({
    aud: "https://oauth2.googleapis.com/token",
    iss: FCM_CLIENT_EMAIL,
    sub: FCM_CLIENT_EMAIL,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    exp: Math.floor(Date.now() / 1000) + 3600,
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
    const { record } = await req.json()
    if (!record || !record.user_id) {
      return new Response(JSON.stringify({ error: "No user_id" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      })
    }
    // Cari FCM token user dari tabel user_devices
    const deviceRes = await fetch(
      `${Deno.env.get("SUPABASE_URL")}/rest/v1/user_devices?user_id=eq.${record.user_id}&select=fcm_token`,
      {
        headers: {
          apikey: Deno.env.get("SUPABASE_ANON_KEY") ?? "",
          Authorization: `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""}`,
        },
      },
    )
    const devices = await deviceRes.json()
    if (!devices || devices.length === 0) {
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
          type: record.type || "",
          reference_type: record.reference_type || "",
          reference_id: record.reference_id || "",
          notification_id: record.id || "",
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