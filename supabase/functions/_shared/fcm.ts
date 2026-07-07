import { JWT } from "npm:google-auth-library@9.15.1";

type ServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
};

export type FcmSendResult = {
  ok: boolean;
  status: number;
  body: string;
};

function parseServiceAccount(): ServiceAccount {
  const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  if (!raw) {
    throw new Error("FIREBASE_SERVICE_ACCOUNT nao configurado.");
  }

  const parsed = JSON.parse(raw) as ServiceAccount;
  if (!parsed.project_id || !parsed.client_email || !parsed.private_key) {
    throw new Error("FIREBASE_SERVICE_ACCOUNT incompleto.");
  }

  return parsed;
}

async function getAccessToken(serviceAccount: ServiceAccount): Promise<string> {
  const client = new JWT({
    email: serviceAccount.client_email,
    key: serviceAccount.private_key,
    scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
  });

  const tokens = await client.authorize();
  if (!tokens.access_token) {
    throw new Error("Falha ao obter access token do Google.");
  }

  return tokens.access_token;
}

function stringifyData(data: Record<string, unknown>): Record<string, string> {
  const result: Record<string, string> = {};
  for (const [key, value] of Object.entries(data)) {
    if (value === undefined || value === null) continue;
    result[key] = typeof value === "string" ? value : JSON.stringify(value);
  }
  return result;
}

export async function sendFcmToToken(options: {
  token: string;
  title: string;
  body: string;
  data?: Record<string, unknown>;
}): Promise<FcmSendResult> {
  const serviceAccount = parseServiceAccount();
  const accessToken = await getAccessToken(serviceAccount);

  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: options.token,
          notification: {
            title: options.title,
            body: options.body,
          },
          data: stringifyData(options.data ?? {}),
          android: {
            priority: "HIGH",
            notification: {
              channel_id: "donna_amparo_alerts",
            },
          },
        },
      }),
    },
  );

  const body = await response.text();
  return { ok: response.ok, status: response.status, body };
}
