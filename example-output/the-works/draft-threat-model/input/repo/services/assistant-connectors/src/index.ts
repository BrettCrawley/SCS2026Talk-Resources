import { createServer } from './mcp/server.js';
import { log } from './logger.js';

const port = Number(process.env.PORT ?? 8090);
createServer().listen(port, () => log.info('assistant-connectors listening', { port }));
