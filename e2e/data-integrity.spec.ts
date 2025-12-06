import { test, expect } from '@playwright/test';
import { loadReport } from './test-utils';

test.describe('Data Integrity', () => {
    test.beforeEach(async ({ page }) => {
        await loadReport(page);
    });

    test('all metric values are valid numbers', async ({ page }) => {
        const metricValues = page.locator('.metric-value');
        const count = await metricValues.count();

        for (let i = 0; i < count; i++) {
            const text = await metricValues.nth(i).textContent();
            // Should contain at least one digit
            expect(text).toMatch(/\d/);
        }
    });

    test('percentages are within valid range', async ({ page }) => {
        const percentageValues = page.locator('.metric-value:has-text("%")');
        const count = await percentageValues.count();

        for (let i = 0; i < count; i++) {
            const text = await percentageValues.nth(i).textContent();
            const value = parseFloat(text?.replace('%', '') ?? '0');

            // Percentage should be between 0 and 100 (with some tolerance for edge cases)
            expect(value).toBeGreaterThanOrEqual(0);
            expect(value).toBeLessThanOrEqual(100);
        }
    });

    test('completion rates are within valid range', async ({ page }) => {
        const completionCells = page.locator('td:has-text("%")');
        const count = await completionCells.count();

        for (let i = 0; i < Math.min(count, 10); i++) {
            const text = await completionCells.nth(i).textContent();
            if (text?.includes('%') && !text?.includes('Scope')) {
                const value = parseFloat(text.replace('%', ''));
                expect(value).toBeGreaterThanOrEqual(0);
                expect(value).toBeLessThanOrEqual(100);
            }
        }
    });

    test('cycle progress values are between 0 and 100', async ({ page }) => {
        const progressFills = page.locator('.progress-fill');
        const count = await progressFills.count();

        for (let i = 0; i < count; i++) {
            const style = await progressFills.nth(i).getAttribute('style');
            const widthMatch = style?.match(/width:\s*([\d.]+)%/);

            if (widthMatch) {
                const width = parseFloat(widthMatch[1]);
                expect(width).toBeGreaterThanOrEqual(0);
                expect(width).toBeLessThanOrEqual(100);
            }
        }
    });

    test('dates are in valid format', async ({ page }) => {
        const title = await page.title();
        // Title should contain a date in YYYY-MM-DD format
        expect(title).toMatch(/\d{4}-\d{2}-\d{2}/);
    });

    test('issue counts are non-negative', async ({ page }) => {
        const issueCounts = page.locator('td:has-text("/")');
        const count = await issueCounts.count();

        for (let i = 0; i < Math.min(count, 10); i++) {
            const text = await issueCounts.nth(i).textContent();
            const match = text?.match(/(\d+)\/(\d+)/);

            if (match) {
                const completed = parseInt(match[1]);
                const total = parseInt(match[2]);

                expect(completed).toBeGreaterThanOrEqual(0);
                expect(total).toBeGreaterThanOrEqual(0);
                expect(completed).toBeLessThanOrEqual(total);
            }
        }
    });

    test('velocity values are non-negative', async ({ page }) => {
        const velocityCells = page.locator('td:has-text("pts")');
        const count = await velocityCells.count();

        for (let i = 0; i < Math.min(count, 10); i++) {
            const text = await velocityCells.nth(i).textContent();
            const value = parseFloat(text?.replace(' pts', '') ?? '0');
            expect(value).toBeGreaterThanOrEqual(0);
        }
    });

    test('scope change shows valid percentage format', async ({ page }) => {
        const scopeChangeCells = page.locator('.scope-increased, .scope-decreased, .scope-neutral');
        const count = await scopeChangeCells.count();

        // Should have at least one scope change cell
        expect(count).toBeGreaterThan(0);

        for (let i = 0; i < Math.min(count, 10); i++) {
            const text = await scopeChangeCells.nth(i).textContent();
            // Should contain a percentage sign
            expect(text).toContain('%');
        }
    });
});
