// ===========================================================================
// JagoPro — Vitest Global Setup for Enterprise Tests
// Bootstraps admin auth, validates server health, initializes test data
// ===========================================================================

import { beforeAll, afterAll } from 'vitest';
import { ApiClient, getAdminToken, clearAdminToken, logger } from './helpers';
import config from '../config/test.config';

let serverHealthy = false;

beforeAll(async () => {
  logger.info('═══ Enterprise Test Suite Starting ═══');
  logger.info(`Target: ${config.baseUrl}`);

  // 1. Health check
  const api = new ApiClient();
  try {
    const health = await api.get('/api/health', { timeout: 5000 });
    if (health.status === 200) {
      serverHealthy = true;
      logger.info('Server health check: PASSED');
    } else {
      throw new Error(`Health check returned ${health.status}`);
    }
  } catch (e: any) {
    logger.error(`Server health check FAILED: ${e.message}`);
    logger.error(`Ensure server is running at ${config.baseUrl}`);
    throw new Error(`Server not reachable at ${config.baseUrl}`);
  }

  // 2. Admin login pre-warm
  try {
    const token = await getAdminToken();
    logger.info(`Admin auth: OK (token: ${token.slice(0, 8)}...)`);
  } catch (e: any) {
    logger.warn(`Admin auth failed: ${e.message} — admin tests will be skipped`);
  }
}, 30_000);

afterAll(() => {
  clearAdminToken();
  logger.info('═══ Enterprise Test Suite Finished ═══');
});

export { serverHealthy };
