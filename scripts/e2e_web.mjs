import assert from 'node:assert/strict';
import { chromium } from 'playwright';
import { writeFileSync, statSync } from 'node:fs';

const BASE = process.env.BASE_URL || 'http://localhost:52200';
const SUPABASE_URL = process.env.SUPABASE_URL || 'http://127.0.0.1:55021';
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY;
const EMAIL = process.env.E2E_EMAIL || 'e2e-owner@test.com';
// Seed credentials are local-only. Both target URLs and browser requests are
// checked for loopback hosts before credentials or test traffic are sent.
const PASSWORD = process.env.E2E_PASSWORD;
const password = PASSWORD ?? 'password123';
const TIMEOUT = 15000;
const results = [];

function localUrl(value) {
  const url = new URL(value);
  assert(['http:', 'https:'].includes(url.protocol), 'Only HTTP local URLs are allowed');
  assert(['localhost', '127.0.0.1', '[::1]'].includes(url.hostname), 'Only loopback hosts are allowed');
  assert(!url.username && !url.password, 'URL credentials are not allowed');
  return url;
}

function record(step, ok, detail = '', durationMs) {
  results.push({ step, ok, detail, durationMs });
  console.log(`${ok ? 'PASS' : 'FAIL'} ${step}${detail ? `: ${detail}` : ''}`);
}

async function clickByAccessibleName(page, name) {
  // CanvasKit controls become accessible after activating Flutter semantics.
  // Missing controls fail the scenario; never substitute direct navigation.
  await page.getByRole('button', { name, exact: true }).click();
}

async function fetchSession() {
  const res = await fetch(`${SUPABASE_URL}/auth/v1/token?grant_type=password`, {
    method: 'POST',
    signal: AbortSignal.timeout(TIMEOUT),
    redirect: 'error',
    headers: {
      apikey: SUPABASE_ANON_KEY,
      Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ email: EMAIL, password }),
  });
  assert(res.ok, `Local fixture authentication failed: HTTP ${res.status}`);
  return res.json();
}

async function primeBrowserState(page, session) {
  const hostFirst = new URL(SUPABASE_URL).hostname.split('.')[0];
  const storageKey = `sb-${hostFirst}-auth-token`;
  await page.evaluate(
    ({ key, value }) => {
      localStorage.setItem(key, JSON.stringify(value));
    },
    { key: storageKey, value: session },
  );
  await page.reload({ waitUntil: 'domcontentloaded' });
  await waitForFlutter(page);
  await expectRoute(page, '/owner/dashboard');
  await page.getByRole('alertdialog').getByRole('button', { name: 'Skip', exact: true }).click();
  await page.getByRole('alertdialog').waitFor({ state: 'detached' });
  record('onboarding_skipped', true, 'Skip control dismissed the first-run tour');
  await dashboardAction(page, 'dashboard_new_bill').waitFor({ state: 'visible' });
}

function dashboardAction(page, identifier) {
  return page.locator(`[flt-semantics-identifier="${identifier}"]`).getByRole('button');
}

async function expectRoute(page, route) {
  await page.waitForURL((url) => url.hash === `#${route}`);
  assert.equal(new URL(page.url()).hash, `#${route}`);
}

async function waitForFlutter(page) {
  // Flutter's accessibility activator is deliberately outside the viewport.
  // Dispatch only this bootstrap action; all application actions use real clicks.
  await page.locator('flutter-view').waitFor({ state: 'attached' });
  const placeholder = page.locator('flt-semantics-placeholder');
  await page.locator('flt-semantics-placeholder, flt-semantics[role]').first().waitFor({ state: 'attached' });
  if (await placeholder.count()) {
    await placeholder.dispatchEvent('click');
  }
  await page.locator('flt-semantics[role]').first().waitFor({ state: 'attached' });
}

async function screenshot(page, name) {
  const path = `e2e-${name}.png`;
  await page.screenshot({ path, fullPage: true, timeout: TIMEOUT });
  assert(statSync(path).size > 3000, `Empty screenshot: ${path}`);
  return path;
}

async function main() {
  let browser;
  let context;
  let page;
  let deadline;
  let timedOut = false;
  const runtimeErrors = new Set();
  const blockedRequests = new Set();
  const runStep = async (name, action) => {
    const started = performance.now();
    try {
      assert(!timedOut, 'E2E overall deadline exceeded');
      await action();
      record(name, true, page?.url() ?? '', Math.round(performance.now() - started));
    } catch (error) {
      record(name, false, error.message, Math.round(performance.now() - started));
      throw error;
    }
  };

  try {
    const base = localUrl(BASE);
    const api = localUrl(SUPABASE_URL);
    assert(base.pathname === '/' && !base.search && !base.hash, 'BASE_URL must be an origin');
    assert(api.pathname === '/' && !api.search && !api.hash, 'SUPABASE_URL must be an origin');
    assert(SUPABASE_ANON_KEY, 'SUPABASE_ANON_KEY is required (from local supabase status)');
    // A fresh context makes onboarding, locale and credentials deterministic.
    browser = await chromium.launch({ headless: true, timeout: TIMEOUT });
    deadline = setTimeout(() => {
      timedOut = true;
      record('overall_timeout', false, 'E2E exceeded 180 seconds');
      void browser.close().catch(() => {});
    }, 180000);
    context = await browser.newContext({ viewport: { width: 1280, height: 800 }, serviceWorkers: 'block' });
    context.setDefaultTimeout(TIMEOUT);
    context.setDefaultNavigationTimeout(TIMEOUT);
    await context.route('**/*', async (route) => {
      const requestUrl = new URL(route.request().url());
      if (!['http:', 'https:'].includes(requestUrl.protocol)) return route.continue();
      try {
        localUrl(requestUrl.href);
        await route.continue();
      } catch {
        blockedRequests.add(requestUrl.origin + (requestUrl.hostname === 'fonts.gstatic.com' ? requestUrl.pathname : ''));
        await route.abort('blockedbyclient');
      }
    });
    page = await context.newPage();
    page.on('pageerror', (error) => runtimeErrors.add(error.message));
    page.on('console', (message) => {
      if (message.type() === 'error' || /Assertion failed|RenderFlex|EXCEPTION CAUGHT/.test(message.text())) {
        runtimeErrors.add(message.text());
      }
    });

    await runStep('login_page', async () => {
      await page.goto(`${BASE}/#/login`, { waitUntil: 'domcontentloaded' });
      await waitForFlutter(page);
      await expectRoute(page, '/login');
      await page.getByRole('button', { name: 'Sign in', exact: true }).waitFor({ state: 'visible' });
      await screenshot(page, 'login');
    });
    await runStep('auth_api', async () => {
      const session = await fetchSession();
      await primeBrowserState(page, session);
      await screenshot(page, 'after-login');
    });

    // go_router's context.push does not reflect imperative routes in the URL.
    // Prove the destination form and its controls; Cancel's context.go must then
    // update the URL. Subsequent scenarios return through the real sidebar.
    await runStep('dashboard_new_bill_nav', async () => {
      await dashboardAction(page, 'dashboard_new_bill').click();
      const form = page.getByRole('group', { name: /^BILLING CREATE BILL/ });
      await form.getByRole('button', { name: 'Save bill', exact: true }).waitFor({ state: 'visible' });
      await form.getByRole('textbox', { name: 'Search products', exact: true }).waitFor({ state: 'visible' });
      await dashboardAction(page, 'dashboard_new_bill').waitFor({ state: 'detached' });
      await expectRoute(page, '/owner/dashboard');
      await form.getByRole('button', { name: 'Cancel', exact: true }).waitFor({ state: 'visible' });
      await screenshot(page, 'bill-form');
    });
    await runStep('bill_form_cancel', async () => {
      await clickByAccessibleName(page, 'Cancel');
      await expectRoute(page, '/owner/billing');
    });
    await runStep('dashboard_add_product_nav', async () => {
      await clickByAccessibleName(page.locator('[flt-semantics-identifier="web_sidebar"]'), 'Dashboard');
      await expectRoute(page, '/owner/dashboard');
      await dashboardAction(page, 'dashboard_add_product').click();
      await page.getByRole('textbox', { name: 'Product Name', exact: true }).waitFor({ state: 'visible' });
      await page.getByRole('textbox', { name: 'Reference price', exact: true }).waitFor({ state: 'visible' });
      await page.getByRole('button', { name: 'Save', exact: true }).waitFor({ state: 'visible' });
      await page.getByRole('button', { name: 'Cancel', exact: true }).waitFor({ state: 'visible' });
      await dashboardAction(page, 'dashboard_add_product').waitFor({ state: 'detached' });
      await expectRoute(page, '/owner/dashboard');
      await screenshot(page, 'product-form');
    });
    await runStep('product_form_cancel', async () => {
      await clickByAccessibleName(page, 'Cancel');
      await expectRoute(page, '/owner/inventory');
    });
    await clickByAccessibleName(page.locator('[flt-semantics-identifier="web_sidebar"]'), 'Dashboard');
    await expectRoute(page, '/owner/dashboard');
    const routes = [
      ['Inventory', '/owner/inventory'],
      ['Customers', '/owner/customers'],
      ['Billing', '/owner/billing'],
      ['Orders', '/owner/orders'],
      ['Staff management', '/owner/staff'],
      ['Reports', '/owner/reports'],
      ['Settings', '/owner/settings'],
      ['Dashboard', '/owner/dashboard'],
    ];
    for (const [label, route] of routes) {
      await runStep(`sidebar_${label.toLowerCase().replaceAll(' ', '_')}`, async () => {
        await clickByAccessibleName(page.locator('[flt-semantics-identifier="web_sidebar"]'), label);
        await expectRoute(page, route);
        await screenshot(page, route.slice(1).replaceAll('/', '-'));
      });
    }

    await runStep('topbar_notifications', async () => {
      const topBar = page.locator('[flt-semantics-identifier="web_top_bar"]');
      await topBar.getByRole('button', { name: /^Notifications(?:, \d+ unread)?$/ }).click();
      await page.getByRole('button', { name: 'Mark all read', exact: true }).waitFor({ state: 'visible' });
      await page.keyboard.press('Escape');
      await page.getByRole('button', { name: 'Mark all read', exact: true }).waitFor({ state: 'detached' });
      await topBar.getByRole('button', { name: /^Notifications(?:, \d+ unread)?$/ }).click();
      await page.getByRole('button', { name: 'Mark all read', exact: true }).waitFor({ state: 'visible' });
      await clickByAccessibleName(page, 'View all');
      await expectRoute(page, '/owner/notifications');
      await page.getByRole('button', { name: 'View all', exact: true }).waitFor({ state: 'detached' });
      await clickByAccessibleName(page.locator('[flt-semantics-identifier="web_sidebar"]'), 'Dashboard');
      await expectRoute(page, '/owner/dashboard');
    });

    await runStep('locale_toggle', async () => {
      await expectRoute(page, '/owner/dashboard');
      const topBar = page.locator('[flt-semantics-identifier="web_top_bar"]');
      const sidebar = page.locator('[flt-semantics-identifier="web_sidebar"]');
      await clickByAccessibleName(topBar, 'NE');
      await sidebar.getByRole('button', { name: 'बिलिङ', exact: true }).waitFor({ state: 'visible' });
      await sidebar.getByRole('button', { name: 'Billing', exact: true }).waitFor({ state: 'detached' });
      await page.waitForFunction(() => JSON.parse(localStorage.getItem('flutter.app_locale')) === 'ne');
      await screenshot(page, 'nepali-dashboard');
      await clickByAccessibleName(topBar, 'EN');
      await sidebar.getByRole('button', { name: 'Billing', exact: true }).waitFor({ state: 'visible' });
      await page.waitForFunction(() => JSON.parse(localStorage.getItem('flutter.app_locale')) === 'en');
    });
    assert.equal(blockedRequests.size, 0, `Non-local requests blocked: ${[...blockedRequests].join(', ')}`);
  } catch (error) {
    if (!results.some((result) => !result.ok)) record('harness_error', false, error.message);
    if (page && !page.isClosed()) {
      await screenshot(page, 'error').catch(() => {});
      await page.locator('body').ariaSnapshot({ timeout: 3000 }).then(
        (snapshot) => console.error('Failure semantics:\n' + snapshot),
        () => {},
      );
    }
  } finally {
    try {
      if (context) await context.close();
    } catch (error) {
      record('context_cleanup', false, error.message);
    } finally {
      try {
        if (browser) await browser.close();
      } catch (error) {
        record('browser_cleanup', false, error.message);
      }
      clearTimeout(deadline);
    }
    if (runtimeErrors.size) record('runtime_errors', false, [...runtimeErrors].join('\n'));
    if (blockedRequests.size) record('local_requests_only', false, [...blockedRequests].join(', '));
    writeFileSync('e2e-results.json', JSON.stringify(results, null, 2));
    const failed = results.filter((result) => !result.ok);
    console.log(`\n${results.length - failed.length}/${results.length} checks passed`);
    console.log('Step timings (ms):', Object.fromEntries(results.filter((result) => result.durationMs !== undefined).map((result) => [result.step, result.durationMs])));
    process.exitCode = failed.length ? 1 : 0;
  }
}

await main();
