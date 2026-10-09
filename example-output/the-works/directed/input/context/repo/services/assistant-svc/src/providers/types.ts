export interface ProviderRequest { model: string; system: string; user: string; }
export interface ProviderResponse {
  text: string;
  toolCalls: { name: string; arguments: Record<string, unknown> }[];
  usage: { inputTokens: number; outputTokens: number };
}
export interface Provider { complete(req: ProviderRequest): Promise<ProviderResponse>; }
