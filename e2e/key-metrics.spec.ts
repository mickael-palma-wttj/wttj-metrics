import { test, expect } from '@playwright/test';
import { loadReport } from './test-utils';

test.describe('Key Metrics Section', () => {
    test.beforeEach(async ({ page }) => {
        await loadReport(page);
    });

    test('displays all key metric cards', async ({ page }) => {
        const metricCards = page.locator('.metrics-grid').first().locator('.metric-card');
        await expect(metricCards).toHaveCount(10);
    });

    test('each metric card has value and label', async ({ page }) => {
        const firstMetricCard = page.locator('.metric-card').first();

        await expect(firstMetricCard.locator('.metric-value')).toBeVisible();
        await expect(firstMetricCard.locator('.metric-label')).toBeVisible();
    });

    test('metric values are formatted correctly', async ({ page }) => {
        // Check cycle time has "days" suffix
        const cycleTimeCard = page.locator('.metric-card', { hasText: 'Cycle Time' });
        await expect(cycleTimeCard.locator('.metric-value')).toContainText(/\d+\.?\d*\s*days/);

        // Check throughput has numeric value
        const throughputCard = page.locator('.metric-card', { hasText: 'Throughput' });
        await expect(throughputCard.locator('.metric-value')).toContainText(/\d+/);
    });

    test('metric card shows tooltip on hover', async ({ page }) => {
        const metricCard = page.locator('.metric-card').first();
        const tooltip = metricCard.locator('.tooltip');

        // Tooltip should be hidden initially
        await expect(tooltip).toBeHidden();

        // Hover over the card
        await metricCard.hover();

        // Tooltip should become visible
        await expect(tooltip).toBeVisible();
    });

    test('WIP metric shows current work in progress', async ({ page }) => {
        const wipCard = page.locator('.metric-card', { hasText: 'WIP' });
        await expect(wipCard).toBeVisible();
        await expect(wipCard.locator('.metric-value')).toContainText(/\d+/);
    });
});
