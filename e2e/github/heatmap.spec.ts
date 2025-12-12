import { test, expect } from '@playwright/test';
import { loadReport } from '../test-utils';

test.describe('GitHub Commit Activity Heatmap', () => {
    test.beforeEach(async ({ page }) => {
        await loadReport(page, 'github');
    });

    test('displays the heatmap section', async ({ page }) => {
        const heatmapContainer = page.locator('#heatmap-container');
        await expect(heatmapContainer).toBeVisible();
        await expect(page.locator('.chart-title', { hasText: 'Commits by Day and Hour' })).toBeVisible();
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

    test('displays the exclude bots toggle', async ({ page }) => {
        // Scope to the heatmap controls
        const toggleWrapper = page.locator('.toggle-wrapper');
        const toggleLabel = toggleWrapper.locator('.toggle-label', { hasText: 'Exclude Bots' });
        const toggleSwitch = toggleWrapper.locator('.toggle-switch');

        await expect(toggleLabel).toBeVisible();
        await expect(toggleSwitch).toBeVisible();
    });

    test('toggle is unchecked by default', async ({ page }) => {
        const toggleInput = page.locator('#excludeBotsToggle');
        await expect(toggleInput).not.toBeChecked();
    });

    test('toggling exclude bots updates the heatmap', async ({ page }) => {
        const heatmapTable = page.locator('#heatmap-container table.heatmap-table');

        // Click the toggle (click the slider inside the wrapper since input is hidden)
        await page.locator('.toggle-wrapper .toggle-slider').click();

        // Check if input is checked
        await expect(page.locator('#excludeBotsToggle')).toBeChecked();

        // The heatmap should re-render. 
        await expect(heatmapTable).toBeVisible();

        // Toggle back
        await page.locator('.toggle-wrapper .toggle-slider').click();
        await expect(page.locator('#excludeBotsToggle')).not.toBeChecked();
    });

    test('tooltips are shown on hover', async ({ page }) => {
        const cell = page.locator('.heatmap-table td[data-tooltip]').first();
        if (await cell.count() > 0) {
            await cell.hover();

            const tooltip = page.locator('.heatmap-tooltip');
            await expect(tooltip).toBeVisible();

            // Get the expected text from the attribute
            const tooltipAttr = await cell.getAttribute('data-tooltip') || '';

            // Playwright's toHaveText normalizes whitespace. 
            // Since our tooltip uses white-space: pre-wrap, the newlines are visual.
            // But toHaveText might strip them if not careful.
            // Let's check if the tooltip contains the text.

            // We can split by newline and check if all parts are present
            const parts = tooltipAttr.split('\n');
            for (const part of parts) {
                await expect(tooltip).toContainText(part);
            }
        }
    });
});
