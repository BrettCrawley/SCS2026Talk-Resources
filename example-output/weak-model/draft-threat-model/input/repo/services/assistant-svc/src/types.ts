export interface Turn {
  role: 'user' | 'assistant' | 'tool';
  content: string;
  toolName?: string;
}

export interface ConversationState {
  conversationId: string;
  workspaceId: string;
  userId: string;
  userName: string;
  turns: Turn[];
  startedAt: string;
}

export interface RetrievedChunk {
  source: string;
  title: string;
  body: string;
}

export interface ToolCall {
  name: string;
  arguments: Record<string, unknown>;
}
