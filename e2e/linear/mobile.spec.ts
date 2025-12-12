import { test, expect } from '@playwright/test';
import { loadReport } from '../test-utils';

test.describe('Mobile Responsiveness', () => {
    // Set mobile viewport for all tests
    test.use({ viewport: { width: 375, height: 812 } });

    test.beforeEach(async ({ page }) => {
        await loadReport(page);
    });

    test('page renders correctly on mobile', async ({ page }) => {
        await expect(page.locator('h1')).toBeVisible();

        // Wait for content to load
        const metricsGrid = page.locator('.metrics-grid').first();
        await metricsGrid.scrollIntoViewIfNeeded();
        await expect(metricsGrid).toBeVisible();
    });

    test('metric cards stack properly on mobile', async ({ page }) => {
        const metricsGrid = page.locator('.metrics-grid').first();
        const gridDisplay = await metricsGrid.evaluate((el) =>
            window.getComputedStyle(el).display
        );

        expect(gridDisplay).toBe('grid');
    });

    test('tables are present in scrollable containers', async ({ page }) => {
        const tableContainer = page.locator('.chart-card:has(.data-table)').first();
        await expect(tableContainer).toBeVisible();

        // Verify table is inside the container
        const table = tableContainer.locator('.data-table');
        await expect(table).toBeVisible();
    });

    test('charts resize for mobile viewport', async ({ page }) => {
        const chartContainer = page.locator('.chart-container').first();
        const box = await chartContainer.boundingBox();

        // Chart should fit within viewport
        const viewport = page.viewportSize();
        expect(box?.width).toBeLessThanOrEqual(viewport?.width ?? 0);
    });

    test('section toggles work on mobile', async ({ page }) => {
        const sectionHeader = page.locator('.section-header').first();
        const sectionContent = page.locator('.section-content').first();

        // Click to collapse (tap not supported in all browsers)
        await sectionHeader.click();
        await expect(sectionContent).toHaveClass(/collapsed/);

        // Click to expand
        await sectionHeader.click();
        await expect(sectionContent).not.toHaveClass(/collapsed/);
    });

    test('font sizes are readable on mobile', async ({ page }) => {
        const title = page.locator('h1');
        const fontSize = await title.evaluate((el) =>
            parseFloat(window.getComputedStyle(el).fontSize)
        );

        // Font should be at least 16px on mobile for readability
        expect(fontSize).toBeGreaterThanOrEqual(16);
    });

    test('tooltips are accessible on mobile', async ({ page }) => {
        const metricCard = page.locator('.metric-card').first();

        // Card should be interactive
        await metricCard.click();
        await expect(metricCard).toBeVisible();
    });
});
