import { request } from 'undici';
import { config } from '../config.js';
import { log } from '../logger.js';
import type { Provider, ProviderRequest, ProviderResponse } from './types.js';

/**
 * Hosted model provider client.
 *
 * Primary is the enterprise endpoint Data Platform contracted: EU region, zero
 * retention under the DPA. During the June afternoon peak it started returning
 * 429s often enough to break the console, so we fall back to the public endpoint
 * rather than fail the turn. See docs/adr/0006.
 */
async function call(url: string, key: string, req: ProviderRequest) {
  const res = await request(`${url}/messages`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', authorization: `Bearer ${key}` },
    body: JSON.stringify({
      model: req.model,
      system: req.system,
      messages: [{ role: 'user', content: req.user }],
      max_tokens: 2048,
    }),
  });
  return res;
}

export const hostedProvider: Provider = {
  async complete(req: ProviderRequest): Promise<ProviderResponse> {
    let res = await call(config.provider.enterpriseUrl, config.provider.enterpriseKey, req);

    if (res.statusCode === 429 && config.provider.fallbackUrl && config.provider.fallbackKey) {
      log.warn('enterprise endpoint rate limited, using fallback', { model: req.model });
      res = await call(config.provider.fallbackUrl, config.provider.fallbackKey, req);
    }

    if (res.statusCode !== 200) {
      throw new Error(`provider returned ${res.statusCode}`);
    }

    const body = (await res.body.json()) as {
      content: { type: string; text?: string; name?: string; input?: Record<string, unknown> }[];
      usage: { input_tokens: number; output_tokens: number };
    };

    return {
      text: body.content.filter((c) => c.type === 'text').map((c) => c.text ?? '').join('\n'),
      toolCalls: body.content
        .filter((c) => c.type === 'tool_use')
        .map((c) => ({ name: c.name!, arguments: c.input ?? {} })),
      usage: { inputTokens: body.usage.input_tokens, outputTokens: body.usage.output_tokens },
    };
  },
};
