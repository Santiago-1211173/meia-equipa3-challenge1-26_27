import { proxyEngine } from "@/server/gateway";

type Context = { params: Promise<{ path: string[] }> };

export async function GET(request: Request, { params }: Context) {
  return proxyEngine("returns", request, (await params).path);
}

export async function POST(request: Request, { params }: Context) {
  return proxyEngine("returns", request, (await params).path);
}
