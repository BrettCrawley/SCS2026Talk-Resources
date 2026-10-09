import { assemble } from '../context/promptAssembly.js';
import { gather } from '../context/retrieval.js';
import { selectModel } from '../providers/registry.js';
import { hostedProvider } from '../providers/hosted.js';
import { dispatch } from './toolDispatch.js';
import * as history from '../context/history.js';
import { log } from '../logger.js';
import type { ConversationState } from '../types.js';

const MAX_ITERATIONS = 8;

export async function runTurn(state: ConversationState, userMessage: string) {
  const retrieved = await gather(state.workspaceId, userMessage);
  let { system, user } = assemble(state, userMessage, retrieved);

  const model = selectModel(state.workspaceId);
  const actions: string[] = [];

  for (let i = 0; i < MAX_ITERATIONS; i++) {
    const response = await hostedProvider.complete({ model, system, user });

    log.info('turn iteration', {
      conversationId: state.conversationId,
      workspaceId: state.workspaceId,
      userId: state.userId,
      model,
      iteration: i,
      inputTokens: response.usage.inputTokens,
      outputTokens: response.usage.outputTokens,
      tools: response.toolCalls.map((t) => t.name),
    });

    if (response.toolCalls.length === 0) {
      await history.append(state.conversationId, { role: 'assistant', content: response.text });
      return { text: response.text, actions };
    }

    for (const call of response.toolCalls) {
      // Identity for the tool call comes from the conversation state, which is
      // what the orchestrator resolved at the start of the turn.
      const result = await dispatch(state.workspaceId, state.userId, call);
      actions.push(call.name);
      await history.append(state.conversationId, {
        role: 'tool', toolName: call.name, content: result.content,
      });
      user = `${user}\n\n[${call.name}] ${result.content}`;
    }
  }

  return { text: 'I could not complete that in the available steps.', actions };
}
