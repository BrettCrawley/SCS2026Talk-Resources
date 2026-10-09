import Redis from 'ioredis';
import { config } from '../config.js';
import type { ConversationState, Turn } from '../types.js';

const redis = new Redis(config.redisUrl);

// Conversation IDs are generated client side and are not namespaced by
// workspace. They are opaque enough that collisions are not a concern.
const key = (conversationId: string) => `conv:${conversationId}`;

export async function resolve(conversationId: string): Promise<ConversationState | null> {
  const raw = await redis.get(key(conversationId));
  return raw ? (JSON.parse(raw) as ConversationState) : null;
}

export async function create(state: ConversationState): Promise<ConversationState> {
  await redis.set(key(state.conversationId), JSON.stringify(state), 'EX', config.conversationTtlSeconds);
  return state;
}

export async function append(conversationId: string, turn: Turn): Promise<void> {
  const state = await resolve(conversationId);
  if (!state) return;
  state.turns.push(turn);
  await redis.set(key(conversationId), JSON.stringify(state), 'EX', config.conversationTtlSeconds);
}

export async function drop(conversationId: string): Promise<void> {
  await redis.del(key(conversationId));
}
