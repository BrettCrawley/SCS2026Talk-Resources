import { describe, it, expect } from 'vitest';
import { renderRetrieved } from './promptAssembly.js';

describe('renderRetrieved', () => {
  it('returns an empty string when nothing was retrieved', () => {
    expect(renderRetrieved([])).toBe('');
  });

  it('renders each chunk with its title and source', () => {
    const out = renderRetrieved([
      { source: 'confluence', title: 'Release process', body: 'Deploy on Thursdays.' },
    ]);
    expect(out).toContain('Release process');
    expect(out).toContain('Deploy on Thursdays.');
  });

  it('preserves chunk bodies exactly as retrieved', () => {
    const body = 'Step one.\n\nStep two.';
    const out = renderRetrieved([{ source: 'github', title: 'Issue 42', body }]);
    expect(out).toContain(body);
  });
});
