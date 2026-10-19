import { gatewayFetch } from "@/server/gateway";

export async function POST(request: Request) {
  const body = await request.text();
  return gatewayFetch("/api/v1/avaliar-ambos", {
    method: "POST",
    body: body || undefined,
    search: new URL(request.url).search,
  });
}
