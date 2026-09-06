import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import { resolve, sep, extname } from 'node:path';
import { chromium } from 'playwright';

const root = resolve('build/web_search_tests');
const mime = {
  '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm',
  '.json': 'application/json', '.css': 'text/css', '.ttf': 'font/ttf',
};
let server;
let browser;
let deadline;
const errors = [];

try {
  assert((await stat(resolve(root, 'index.html'))).isFile(), 'Build the test bootstrap first');
  server = createServer(async (request, response) => {
    try {
      const pathname = decodeURIComponent(new URL(request.url, 'http://127.0.0.1').pathname);
      const path = resolve(root, `.${pathname === '/' ? '/index.html' : pathname}`);
      assert(path.startsWith(`${root}${sep}`), 'Path outside test build');
      const body = await readFile(path);
      response.writeHead(200, { 'Content-Type': mime[extname(path)] ?? 'application/octet-stream' });
      response.end(body);
    } catch {
      response.writeHead(404);
      response.end('Not found');
    }
  });
  await new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(0, '127.0.0.1', resolve);
  });
  const base = `http://127.0.0.1:${server.address().port}`;
  browser = await chromium.launch({ headless: true, timeout: 15000 });
  deadline = setTimeout(() => {
    errors.push('Browser widget tests exceeded 240 seconds');
    void browser.close().catch(() => {});
  }, 240000);
  const context = await browser.newContext({ serviceWorkers: 'block' });
  await context.route('**/*', async (route) => {
    const url = new URL(route.request().url());
    if (['http:', 'https:'].includes(url.protocol) && url.origin !== base) {
      errors.push(`Non-local test request blocked: ${url.origin}`);
      await route.abort('blockedbyclient');
    } else {
      await route.continue();
    }
  });
  const page = await context.newPage();
  page.on('pageerror', (error) => errors.push(error.message));
  page.on('console', (message) => {
    console.log(message.text());
    if (message.type() === 'error') errors.push(message.text());
  });
  await page.goto(base, { waitUntil: 'domcontentloaded', timeout: 15000 });
  await page.waitForFunction(() => typeof window.businessSajiloTestResult === 'string', { }, { timeout: 210000 });
  const result = JSON.parse(await page.evaluate(() => window.businessSajiloTestResult));
  console.log(JSON.stringify(result, null, 2));
  assert.equal(result.passed, true, 'Flutter widget tests failed');
  assert.equal(Object.keys(result.results).length, result.expectedTests, 'Not all expected tests ran');
  assert(result.expectedTests > 0, 'No tests registered');
  assert(Object.values(result.results).every((value) => value === 'success'), 'A widget assertion failed');
  assert.equal(errors.length, 0, errors.join('\n'));
} catch (error) {
  console.error(error);
  process.exitCode = 1;
} finally {
  try {
    if (browser) await browser.close();
  } catch (error) {
    console.error(error);
    process.exitCode = 1;
  } finally {
    clearTimeout(deadline);
    if (server) {
      server.closeAllConnections();
      await new Promise((resolve) => server.close(resolve));
    }
  }
}
