import { invoke } from './mcpClient.js';
import { log } from '../logger.js';
import type { ToolCall } from '../types.js';

/**
 * Run a tool call and return its result as a string for the next turn.
 *
 * Arguments and results are logged at debug. In production LOG_LEVEL is info,
 * because at debug the connector payloads are large enough to dominate the log
 * bill. The tool name is always recorded.
 */
export async function dispatch(workspaceId: string, userId: string, call: ToolCall) {
  log.info('tool call', { workspaceId, tool: call.name });
  log.debug('tool call arguments', { tool: call.name, arguments: call.arguments });

  const result = await invoke(workspaceId, userId, call);

  log.debug('tool call result', { tool: call.name, content: result.content });
  return result;
}
