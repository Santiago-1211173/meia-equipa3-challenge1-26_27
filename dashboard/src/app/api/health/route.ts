import { gatewayFetch } from "@/server/gateway";

export async function GET() {
  return gatewayFetch("/health", { method: "GET" });
}
