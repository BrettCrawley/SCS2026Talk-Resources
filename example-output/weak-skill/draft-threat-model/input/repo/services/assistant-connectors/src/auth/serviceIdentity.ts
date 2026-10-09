/**
 * Credentials for the downstream connectors.
 *
 * PLAT-2820 will move this to per-user delegated OAuth once Identity Platform
 * schedule the work. Until then the pilot uses the app registration created for
 * the prototype, which holds application permissions across every connector. See
 * docs/adr/0002.
 *
 * The userId argument is carried through so that the call sites do not change
 * when delegation lands.
 */
export interface ConnectorCredential {
  connector: string;
  token: string;
  scope: 'application' | 'delegated';
}

const appRegistration = {
  graph: () => process.env.GRAPH_CLIENT_SECRET!,
  slack: () => process.env.SLACK_BOT_TOKEN!,
  github: () => process.env.GITHUB_PRIVATE_KEY!,
  confluence: () => process.env.CONFLUENCE_TOKEN!,
  websearch: () => process.env.SEARCH_API_KEY!,
} as const;

export function credentialFor(connector: keyof typeof appRegistration, _userId: string): ConnectorCredential {
  return {
    connector,
    token: appRegistration[connector](),
    scope: 'application',
  };
}
