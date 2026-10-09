import { readFileSync } from 'node:fs';
import { join } from 'node:path';

export interface WorkspaceConfig {
  workspaceId: string;
  displayName: string;
  enabledTeams: string[];
  customInstructions: string;
  model: string;
}

const workspacesPath = process.env.WORKSPACES_PATH
  ?? join(process.cwd(), '..', '..', 'config', 'workspaces.json');

export const workspaces: Record<string, WorkspaceConfig> =
  JSON.parse(readFileSync(workspacesPath, 'utf8'));

export const config = {
  port: Number(process.env.PORT ?? 8080),
  logLevel: process.env.LOG_LEVEL ?? 'info',
  redisUrl: process.env.REDIS_URL ?? 'redis://localhost:6379',
  connectorsUrl: process.env.CONNECTORS_URL ?? 'http://assistant-connectors:8090',

  provider: {
    enterpriseUrl: process.env.PROVIDER_ENTERPRISE_URL!,
    enterpriseKey: process.env.PROVIDER_ENTERPRISE_KEY!,
    // Added during the June peak-load incident. See docs/adr/0006.
    fallbackUrl: process.env.PROVIDER_FALLBACK_URL,
    fallbackKey: process.env.PROVIDER_FALLBACK_KEY,
    // Provider retains prompts and completions for abuse monitoring.
    retentionDays: 30,
  },

  // History is kept for a day so an agent can pick a conversation back up after
  // a meeting. Nobody has asked for longer.
  conversationTtlSeconds: 86_400,

  // Turned off in production by setting the variable. The chart does not set it.
  exposeDebugRoutes: process.env.EXPOSE_DEBUG_ROUTES !== 'false',
};
