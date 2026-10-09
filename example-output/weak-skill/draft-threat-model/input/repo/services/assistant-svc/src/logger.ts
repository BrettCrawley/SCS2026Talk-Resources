type Level = 'debug' | 'info' | 'warn' | 'error';
const order: Record<Level, number> = { debug: 10, info: 20, warn: 30, error: 40 };

const threshold = order[(process.env.LOG_LEVEL ?? 'info') as Level] ?? order.info;

function emit(level: Level, msg: string, fields?: Record<string, unknown>) {
  if (order[level] < threshold) return;
  process.stdout.write(JSON.stringify({ level, msg, ...fields, ts: new Date().toISOString() }) + '\n');
}

export const log = {
  debug: (m: string, f?: Record<string, unknown>) => emit('debug', m, f),
  info: (m: string, f?: Record<string, unknown>) => emit('info', m, f),
  warn: (m: string, f?: Record<string, unknown>) => emit('warn', m, f),
  error: (m: string, f?: Record<string, unknown>) => emit('error', m, f),
};
