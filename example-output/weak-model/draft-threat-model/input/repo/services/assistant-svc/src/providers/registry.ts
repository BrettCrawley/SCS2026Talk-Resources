import { forWorkspace } from '../context/workspaceConfig.js';

/**
 * Models a workspace admin may select. Ordered by capability, and by price.
 *
 * Enterprise workspaces choose their own so they can manage consumption; this is
 * the MER-4437 requirement carried over into PLAT-2822. Everything on the list is
 * a supported model, so the choice is a cost decision rather than a technical one.
 */
export const SUPPORTED_MODELS = [
  'aurora-2-pro',
  'aurora-2',
  'aurora-1-mini',
  'lumen-small',
] as const;

export type SupportedModel = (typeof SUPPORTED_MODELS)[number];

export function selectModel(workspaceId: string): string {
  const configured = forWorkspace(workspaceId).model;
  if ((SUPPORTED_MODELS as readonly string[]).includes(configured)) return configured;
  return 'aurora-2';
}
