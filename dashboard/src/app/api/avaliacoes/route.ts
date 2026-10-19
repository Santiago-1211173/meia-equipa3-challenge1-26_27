import { proxyAvaliacoes } from "@/server/gateway";

export async function GET(request: Request) {
  return proxyAvaliacoes(request, []);
}

export async function POST(request: Request) {
  return proxyAvaliacoes(request, []);
}
