import { test, expect } from '@playwright/test';
import { loadReport } from '../test-utils';

test.describe('Linear Ticket Activity Heatmap', () => {
    test.beforeEach(async ({ page }) => {
        await loadReport(page);
    });

    test('displays the heatmap section', async ({ page }) => {
        const heatmapContainer = page.locator('#heatmap-container');
        await expect(heatmapContainer).toBeVisible();
        await expect(page.locator('.chart-title', { hasText: 'Ticket Completion Heatmap' })).toBeVisible();
    });

    test('renders the heatmap table', async ({ page, isMobile }) => {
        const heatmapTable = page.locator('#heatmap-container table.heatmap-table');
        await expect(heatmapTable).toBeVisible();

        // Check for days and hours
        if (!isMobile) {
            await expect(heatmapTable.locator('thead th')).toHaveCount(25); // Empty corner + 24 hours
            await expect(heatmapTable.locator('tbody tr')).toHaveCount(7); // 7 days
        } else {
            // Mobile view has different structure (hours as rows, days as cols)
            await expect(heatmapTable.locator('tbody tr')).toHaveCount(24); // 24 hours
        }
    });

    test('tooltips are shown on hover', async ({ page }) => {
        const cell = page.locator('.heatmap-table td[data-tooltip]').first();
        if (await cell.count() > 0) {
            await cell.hover();

            const tooltip = page.locator('.heatmap-tooltip');
            await expect(tooltip).toBeVisible();

            // Get the expected text from the attribute
            const tooltipAttr = await cell.getAttribute('data-tooltip') || '';

            const parts = tooltipAttr.split('\n');
            for (const part of parts) {
                await expect(tooltip).toContainText(part);
            }
        }
    });
});
