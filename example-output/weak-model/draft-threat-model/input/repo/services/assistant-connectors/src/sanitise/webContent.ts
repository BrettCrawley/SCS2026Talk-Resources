/**
 * Clean content returned by web search before it reaches the model.
 *
 * PLAT-2814 acceptance criterion: web results are untrusted and are cleaned.
 * Internal sources are behind authentication and do not go through this.
 */
const SCRIPT_LIKE = /<script[\s\S]*?<\/script>/gi;
const HTML_TAG = /<[^>]+>/g;
const INSTRUCTION_LIKE = /\b(ignore (all |the )?(previous|above) instructions?|disregard your (instructions|system prompt))\b/gi;

export function sanitiseWebContent(raw: string): string {
  return raw
    .replace(SCRIPT_LIKE, ' ')
    .replace(HTML_TAG, ' ')
    .replace(INSTRUCTION_LIKE, '[removed]')
    .replace(/\s+/g, ' ')
    .trim();
}
