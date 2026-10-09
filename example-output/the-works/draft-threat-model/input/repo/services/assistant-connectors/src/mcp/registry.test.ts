import { describe, it, expect } from 'vitest';
import { toolsForWorkspace, ALL_TOOLS } from './registry.js';

describe('toolsForWorkspace', () => {
  it('returns the configured subset for a configured workspace', () => {
    const tools = toolsForWorkspace('ws-support');
    expect(tools.some((t) => t.name === 'commit')).toBe(false);
    expect(tools.some((t) => t.name === 'search_knowledge_base' || t.name === 'search_pages')).toBe(true);
  });

  it('returns everything for the platform workspace', () => {
    const tools = toolsForWorkspace('ws-platform');
    expect(tools.length).toBe(ALL_TOOLS.length);
  });
});
