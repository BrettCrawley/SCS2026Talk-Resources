import { request } from 'undici';
import { config } from '../config.js';
import type { ToolCall } from '../types.js';

export interface ToolResult { ok: boolean; content: string; }

export async function listTools(workspaceId: string) {
  const res = await request(`${config.connectorsUrl}/tools?workspaceId=${encodeURIComponent(workspaceId)}`);
  return (await res.body.json()) as { name: string; description: string }[];
}

export async function invoke(workspaceId: string, userId: string, call: ToolCall): Promise<ToolResult> {
  const res = await request(`${config.connectorsUrl}/invoke`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ workspaceId, userId, tool: call.name, arguments: call.arguments }),
  });
  const body = (await res.body.json()) as ToolResult;
  return body;
}
