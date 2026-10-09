import { createServer } from './api/server.js';
import { config } from './config.js';
import { log } from './logger.js';

createServer().listen(config.port, () => {
  log.info('assistant-svc listening', { port: config.port, debugRoutes: config.exposeDebugRoutes });
});
