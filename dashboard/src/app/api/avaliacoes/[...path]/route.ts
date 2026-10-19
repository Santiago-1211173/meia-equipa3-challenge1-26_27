import { proxyAvaliacoes } from "@/server/gateway";

type Context = { params: Promise<{ path: string[] }> };

export async function GET(request: Request, { params }: Context) {
  const { path } = await params;
  return proxyAvaliacoes(request, path);
}

export async function POST(request: Request, { params }: Context) {
  const { path } = await params;
  return proxyAvaliacoes(request, path);
}
