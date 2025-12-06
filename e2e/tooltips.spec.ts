import { test, expect } from '@playwright/test';
import { loadReport } from './test-utils';

test.describe('Tooltips', () => {
    test.beforeEach(async ({ page }) => {
        await loadReport(page);
    });

    test('metric card tooltips appear on hover', async ({ page }) => {
        const metricCard = page.locator('.metric-card').first();
        const tooltip = metricCard.locator('.tooltip');

        // Hidden initially
        await expect(tooltip).toBeHidden();

        // Visible on hover
        await metricCard.hover();
        await expect(tooltip).toBeVisible();

        // Has content
        const text = await tooltip.textContent();
        expect(text?.length).toBeGreaterThan(10);
    });

    test('table header tooltips appear on hover', async ({ page }) => {
        const headerWithTooltip = page.locator('.cycles-table th.has-tooltip').first();
        const tooltip = headerWithTooltip.locator('.th-tooltip');

        // Hidden initially
        await expect(tooltip).toBeHidden();

        // Visible on hover
        await headerWithTooltip.hover();
        await expect(tooltip).toBeVisible();
    });

    test('scope change cell tooltips show breakdown', async ({ page }) => {
        const scopeChangeCell = page.locator('.cycles-table td.has-tooltip').first();

        if (await scopeChangeCell.count() > 0) {
            const tooltip = scopeChangeCell.locator('.cell-tooltip');

            await scopeChangeCell.hover();
            await expect(tooltip).toBeVisible();

            // Should show initial and final values
            await expect(tooltip).toContainText('Initial');
            await expect(tooltip).toContainText('Final');
            await expect(tooltip).toContainText('issues');
        }
    });

    test('tooltips have proper positioning', async ({ page }) => {
        const metricCard = page.locator('.metric-card').first();
        const tooltip = metricCard.locator('.tooltip');

        await metricCard.hover();
        await expect(tooltip).toBeVisible();

        // Tooltip should be positioned below the card
        const cardBox = await metricCard.boundingBox();
        const tooltipBox = await tooltip.boundingBox();

        expect(tooltipBox?.y).toBeGreaterThanOrEqual(cardBox?.y ?? 0);
    });

    test('tooltips have readable text color', async ({ page }) => {
        const metricCard = page.locator('.metric-card').first();
        const tooltip = metricCard.locator('.tooltip');

        await metricCard.hover();

        // Should have light text on dark background
        await expect(tooltip).toHaveCSS('background-color', 'rgb(21, 21, 21)');
        await expect(tooltip).toHaveCSS('color', 'rgb(255, 255, 255)');
    });
});
