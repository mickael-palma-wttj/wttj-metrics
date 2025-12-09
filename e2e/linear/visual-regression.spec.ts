import { test, expect } from '@playwright/test';
import { loadReport } from '../test-utils';

test.describe('Visual Regression', () => {
    test.beforeEach(async ({ page }) => {
        await loadReport(page);
        // Wait for charts to render
        await page.waitForTimeout(1000);
    });

    test('full page can be captured', async ({ page }) => {
        // Just verify page loads and can be screenshotted
        const screenshot = await page.screenshot({ fullPage: true });
        expect(screenshot.length).toBeGreaterThan(0);
    });

    test('key metrics section is visible', async ({ page }) => {
        const metricsSection = page.locator('section').first();
        await expect(metricsSection).toBeVisible();

        const screenshot = await metricsSection.screenshot();
        expect(screenshot.length).toBeGreaterThan(0);
    });

    test('bug tracking section is visible', async ({ page }) => {
        const bugSection = page.locator('section', {
            has: page.locator('.section-title', { hasText: 'Bug Tracking' })
        });
        await expect(bugSection).toBeVisible();
    });

    test('cycles table is visible', async ({ page }) => {
        const cyclesSection = page.locator('section', {
            has: page.locator('.section-title', { hasText: 'Cycles by Team' })
        });

        // Scroll to section first
        await cyclesSection.scrollIntoViewIfNeeded();
        await expect(cyclesSection).toBeVisible();
    });

    test('metric card hover state shows tooltip', async ({ page }) => {
        const metricCard = page.locator('.metric-card').first();
        const tooltip = metricCard.locator('.tooltip');

        await metricCard.hover();
        // Wait for tooltip animation
        await page.waitForTimeout(300);

        await expect(tooltip).toBeVisible();
    });

    test('collapsed section has collapsed class', async ({ page }) => {
        const firstSection = page.locator('section').first();
        const sectionHeader = firstSection.locator('.section-header');
        const sectionContent = firstSection.locator('.section-content');

        // Collapse the section
        await sectionHeader.click();
        await page.waitForTimeout(300);

        await expect(sectionContent).toHaveClass(/collapsed/);
    });
});
