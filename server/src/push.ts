import jwt from 'jsonwebtoken';
import fs from 'fs';

/**
 * Firebase Cloud Messaging via the HTTP v1 API.
 * Configure with ONE of:
 *   FIREBASE_SERVICE_ACCOUNT       – the service-account JSON as a string
 *   FIREBASE_SERVICE_ACCOUNT_FILE  – path to the service-account JSON file
 * If neither is set, push is disabled and every send is a silent no-op, so the
 * server runs fine before Firebase is wired up.
 */
interface ServiceAccount {
  client_email: string;
  private_key: string;
  project_id: string;
}

function loadServiceAccount(): ServiceAccount | null {
  try {
    const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
    if (raw && raw.trim().startsWith('{')) return JSON.parse(raw) as ServiceAccount;
    const file = process.env.FIREBASE_SERVICE_ACCOUNT_FILE;
    if (file && fs.existsSync(file)) return JSON.parse(fs.readFileSync(file, 'utf8')) as ServiceAccount;
  } catch (e) {
    console.warn('[push] failed to load service account:', (e as Error).message);
  }
  return null;
}

const sa = loadServiceAccount();
export const pushEnabled = !!sa;
if (pushEnabled) console.log('[push] FCM enabled for project', sa!.project_id);
else console.log('[push] FCM disabled (no service account) — notifications are no-ops');

let cachedToken: { value: string; exp: number } | null = null;

async function accessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.exp - 60 > now) return cachedToken.value;
  const assertion = jwt.sign(
    {
      iss: sa!.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
    },
    sa!.private_key,
    { algorithm: 'RS256' },
  );
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });
  if (!res.ok) throw new Error(`oauth token ${res.status}: ${await res.text()}`);
  const j = (await res.json()) as { access_token: string; expires_in: number };
  cachedToken = { value: j.access_token, exp: now + j.expires_in };
  return j.access_token;
}

export interface PushMessage {
  title: string;
  body: string;
  data?: Record<string, string>;
}

/**
 * Sends [msg] to each FCM token. Returns the tokens FCM reported as
 * unregistered/invalid so the caller can prune them.
 */
export async function sendToTokens(tokens: string[], msg: PushMessage): Promise<string[]> {
  if (!pushEnabled || tokens.length === 0) return [];
  let token: string;
  try {
    token = await accessToken();
  } catch (e) {
    console.warn('[push] could not get access token:', (e as Error).message);
    return [];
  }
  const url = `https://fcm.googleapis.com/v1/projects/${sa!.project_id}/messages:send`;
  const dead: string[] = [];
  await Promise.allSettled(
    tokens.map(async (t) => {
      const res = await fetch(url, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          message: {
            token: t,
            notification: { title: msg.title, body: msg.body },
            data: msg.data ?? {},
            android: { priority: 'high' },
            apns: { payload: { aps: { sound: 'default' } } },
          },
        }),
      });
      if (res.status === 404 || res.status === 400) {
        // UNREGISTERED / invalid token — mark for pruning.
        dead.push(t);
      } else if (!res.ok) {
        console.warn('[push] send failed', res.status, (await res.text()).slice(0, 200));
      }
    }),
  );
  return dead;
}
