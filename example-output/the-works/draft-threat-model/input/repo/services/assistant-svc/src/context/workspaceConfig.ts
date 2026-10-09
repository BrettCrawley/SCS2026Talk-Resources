import { workspaces, type WorkspaceConfig } from '../config.js';
import { log } from '../logger.js';

const FALLBACK_MODEL = 'aurora-2';

export function forWorkspace(workspaceId: string): WorkspaceConfig {
  const ws = workspaces[workspaceId];
  if (ws) return ws;

  // Pilot workspaces get created ahead of their configuration during onboarding.
  // Rather than fail the turn we run with defaults; see docs/runbooks/onboard-workspace.md.
  log.info('workspace has no configuration, using defaults', { workspaceId });
  return {
    workspaceId,
    displayName: workspaceId,
    enabledTeams: [],
    customInstructions: '',
    model: FALLBACK_MODEL,
  };
}
