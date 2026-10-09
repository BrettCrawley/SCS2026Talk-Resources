export interface SearchResult { source: string; title: string; body: string; }
export interface Connector {
  id: string;
  search?(workspaceId: string, userId: string, query: string): Promise<SearchResult[]>;
  tools: { name: string; description: string; write: boolean }[];
  invoke(name: string, workspaceId: string, userId: string, args: Record<string, unknown>): Promise<string>;
}
