import { test, expect } from '@playwright/test';
import { loadReport } from '../test-utils';

test.describe('Accessibility', () => {
    test.beforeEach(async ({ page }) => {
        await loadReport(page);
    });

    test('page has proper document structure', async ({ page }) => {
        // Has exactly one h1
        const h1Count = await page.locator('h1').count();
        expect(h1Count).toBe(1);

        // Has sections
        const sections = await page.locator('section').count();
        expect(sections).toBeGreaterThan(0);

        // Has footer
        await expect(page.locator('footer')).toBeVisible();
    });

    test('page has proper language attribute', async ({ page }) => {
        const lang = await page.locator('html').getAttribute('lang');
        expect(lang).toBe('en');
    });

    test('page has viewport meta tag', async ({ page }) => {
        const viewport = await page.locator('meta[name="viewport"]').getAttribute('content');
        expect(viewport).toContain('width=device-width');
    });

    test('images have alt text or are decorative', async ({ page }) => {
        const images = page.locator('img');
        const count = await images.count();

        for (let i = 0; i < count; i++) {
            const img = images.nth(i);
            const alt = await img.getAttribute('alt');
            const role = await img.getAttribute('role');

            // Either has alt text or is marked as decorative
            expect(alt !== null || role === 'presentation').toBeTruthy();
        }
    });

    test('interactive elements are focusable', async ({ page }) => {
        const toggleInputs = page.locator('.toggle-switch input');
        const count = await toggleInputs.count();

        for (let i = 0; i < count; i++) {
            const input = toggleInputs.nth(i);
            await expect(input).not.toBeDisabled();
        }
    });

    test('color contrast is sufficient for text', async ({ page }) => {
        const metricValue = page.locator('.metric-value').first();
        const color = await metricValue.evaluate((el) =>
            window.getComputedStyle(el).color
        );

        // Should be dark text (#151515 = rgb(21, 21, 21))
        expect(color).toBe('rgb(21, 21, 21)');
    });

    test('tables have proper header structure', async ({ page }) => {
        const tables = page.locator('.data-table');
        const count = await tables.count();

        for (let i = 0; i < count; i++) {
            const table = tables.nth(i);
            const thead = table.locator('thead');
            const th = table.locator('th');

            // Each table should have a thead and th elements
            await expect(thead).toBeVisible();
            expect(await th.count()).toBeGreaterThan(0);
        }
    });

    test('page can be navigated with keyboard', async ({ page, browserName }) => {
        // Skip for webkit and mobile as they handle focus differently
        test.skip(browserName === 'webkit', 'Webkit handles initial focus differently');

        // Tab to first interactive element
        await page.keyboard.press('Tab');

        // Something should be focused
        const focused = await page.evaluate(() => document.activeElement?.tagName);
        expect(focused).not.toBe('BODY');
    });

    test('status indicators use more than just color', async ({ page }) => {
        const statusBadges = page.locator('.status-badge');
        const count = await statusBadges.count();

        if (count > 0) {
            // Status badges should have text content, not just color
            const text = await statusBadges.first().textContent();
            expect(text?.trim().length).toBeGreaterThan(0);
        }
    });
});
