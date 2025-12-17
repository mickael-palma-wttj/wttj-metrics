import { test, expect } from '@playwright/test';
import { loadReport } from '../test-utils';

test.describe('Percentile Charts - Bug Tracking Section', () => {
    test.beforeEach(async ({ page }) => {
        await loadReport(page);
    });

    test('displays Bug MTTR by Team chart', async ({ page }) => {
        const bugMttrChart = page.locator('#bugMttrChart');
        await expect(bugMttrChart).toBeVisible();
    });

    test('Bug MTTR chart has proper title and tooltip', async ({ page }) => {
        const bugSection = page.locator('section', { has: page.locator('.section-title', { hasText: 'Bug Tracking' }) });
        const chartTitle = bugSection.locator('.chart-title', { hasText: 'Bug MTTR by Team' });

        await expect(chartTitle).toBeVisible();

        // Verify tooltip exists
        const tooltipIcon = chartTitle.locator('.tooltip-icon');
        await expect(tooltipIcon).toBeVisible();
    });
});

test.describe('Percentile Charts - Ticket Flow Section', () => {
    test.beforeEach(async ({ page }) => {
        await loadReport(page);
    });

    test('displays Daily Throughput Percentiles chart', async ({ page }) => {
        const throughputChart = page.locator('#throughputPercentilesChart');
        await expect(throughputChart).toBeVisible();
    });

    test('displays Weekly Throughput Trend chart', async ({ page }) => {
        const weeklyChart = page.locator('#weeklyThroughputChart');
        await expect(weeklyChart).toBeVisible();
    });

    test('Daily Throughput Percentiles chart has proper title', async ({ page }) => {
        const flowSection = page.locator('section', { has: page.locator('.section-title', { hasText: 'Ticket Flow' }) });
        const chartTitle = flowSection.locator('.chart-title', { hasText: 'Daily Throughput Percentiles' });

        await expect(chartTitle).toBeVisible();
    });

    test('Weekly Throughput Trend chart has proper title', async ({ page }) => {
        const flowSection = page.locator('section', { has: page.locator('.section-title', { hasText: 'Ticket Flow' }) });
        const chartTitle = flowSection.locator('.chart-title', { hasText: 'Weekly Throughput Trend' });

        await expect(chartTitle).toBeVisible();
    });

    test('throughput charts have tooltips', async ({ page }) => {
        const flowSection = page.locator('section', { has: page.locator('.section-title', { hasText: 'Ticket Flow' }) });

        const dailyTooltip = flowSection.locator('.chart-title', { hasText: 'Daily Throughput Percentiles' }).locator('.tooltip-icon');
        const weeklyTooltip = flowSection.locator('.chart-title', { hasText: 'Weekly Throughput Trend' }).locator('.tooltip-icon');

        await expect(dailyTooltip).toBeVisible();
        await expect(weeklyTooltip).toBeVisible();
    });
});

test.describe('Percentile Charts - Team Comparison Section', () => {
    test.beforeEach(async ({ page }) => {
        await loadReport(page);
    });

    test('displays Cycle Velocity Distribution chart', async ({ page }) => {
        const velocityChart = page.locator('#velocityDistributionChart');
        await expect(velocityChart).toBeVisible();
    });

    test('displays Completion Rate Distribution chart', async ({ page }) => {
        const completionChart = page.locator('#completionDistributionChart');
        await expect(completionChart).toBeVisible();
    });

    test('displays Completion Rate Histogram chart', async ({ page }) => {
        const histogramChart = page.locator('#completionHistogramChart');
        await expect(histogramChart).toBeVisible();
    });

    test('Cycle Velocity Distribution chart has proper title', async ({ page }) => {
        const teamSection = page.locator('section', { has: page.locator('.section-title', { hasText: 'Team Comparison' }) });
        const chartTitle = teamSection.locator('.chart-title', { hasText: 'Cycle Velocity Distribution' });

        await expect(chartTitle).toBeVisible();
    });

    test('Completion Rate Distribution chart has proper title', async ({ page }) => {
        const teamSection = page.locator('section', { has: page.locator('.section-title', { hasText: 'Team Comparison' }) });
        const chartTitle = teamSection.locator('.chart-title', { hasText: 'Completion Rate Distribution' });

        await expect(chartTitle).toBeVisible();
    });

    test('Completion Rate Histogram chart has proper title', async ({ page }) => {
        const teamSection = page.locator('section', { has: page.locator('.section-title', { hasText: 'Team Comparison' }) });
        const chartTitle = teamSection.locator('.chart-title', { hasText: 'Completion Rate Histogram' });

        await expect(chartTitle).toBeVisible();
    });

    test('Team Comparison charts have tooltips', async ({ page }) => {
        const teamSection = page.locator('section', { has: page.locator('.section-title', { hasText: 'Team Comparison' }) });

        const velocityTooltip = teamSection.locator('.chart-title', { hasText: 'Cycle Velocity Distribution' }).locator('.tooltip-icon');
        const completionTooltip = teamSection.locator('.chart-title', { hasText: 'Completion Rate Distribution' }).locator('.tooltip-icon');
        const histogramTooltip = teamSection.locator('.chart-title', { hasText: 'Completion Rate Histogram' }).locator('.tooltip-icon');

        await expect(velocityTooltip).toBeVisible();
        await expect(completionTooltip).toBeVisible();
        await expect(histogramTooltip).toBeVisible();
    });

    test('charts grid has margin-top for spacing after table', async ({ page }) => {
        const teamSection = page.locator('section', { has: page.locator('.section-title', { hasText: 'Team Comparison' }) });
        const chartsGrid = teamSection.locator('.charts-grid');

        // Verify margin-top is applied
        const marginTop = await chartsGrid.evaluate(el => getComputedStyle(el).marginTop);
        expect(marginTop).toBe('24px'); // 1.5rem = 24px
    });
});

test.describe('Percentile Charts - Canvas Rendering', () => {
    test.beforeEach(async ({ page }) => {
        await loadReport(page);
    });

    test('all percentile charts have non-zero dimensions', async ({ page }) => {
        // Wait for Chart.js to render
        await page.waitForTimeout(500);

        const chartIds = [
            'bugMttrChart',
            'throughputPercentilesChart',
            'weeklyThroughputChart',
            'velocityDistributionChart',
            'completionDistributionChart',
            'completionHistogramChart'
        ];

        for (const chartId of chartIds) {
            const chart = page.locator(`#${chartId}`);
            const box = await chart.boundingBox();

            expect(box?.width, `${chartId} should have width > 0`).toBeGreaterThan(0);
            expect(box?.height, `${chartId} should have height > 0`).toBeGreaterThan(0);
        }
    });
});
