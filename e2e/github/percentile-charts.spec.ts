import { test, expect } from '@playwright/test';
import { loadReport } from '../test-utils';

test.describe('GitHub Percentile Charts - Efficiency Trends Section', () => {
    test.beforeEach(async ({ page }) => {
        await loadReport(page, 'github');
    });

    test('displays Time to First Review Percentiles chart', async ({ page }) => {
        const reviewChart = page.locator('#timeToReviewPercentilesChart');
        await expect(reviewChart).toBeVisible();
    });

    test('displays Time to Merge Percentiles chart', async ({ page }) => {
        const mergeChart = page.locator('#timeToMergePercentilesChart');
        await expect(mergeChart).toBeVisible();
    });

    test('Time to First Review chart has proper title', async ({ page }) => {
        const efficiencySection = page.locator('section', { has: page.locator('.section-title', { hasText: 'Efficiency Trends' }) });
        const chartTitle = efficiencySection.locator('.chart-title', { hasText: 'Time to First Review (P50/P75/P90/P95)' });

        await expect(chartTitle).toBeVisible();
    });

    test('Time to Merge chart has proper title', async ({ page }) => {
        const efficiencySection = page.locator('section', { has: page.locator('.section-title', { hasText: 'Efficiency Trends' }) });
        const chartTitle = efficiencySection.locator('.chart-title', { hasText: 'Time to Merge (P50/P75/P90/P95)' });

        await expect(chartTitle).toBeVisible();
    });

    test('efficiency percentile charts have tooltips', async ({ page }) => {
        const efficiencySection = page.locator('section', { has: page.locator('.section-title', { hasText: 'Efficiency Trends' }) });

        const reviewTooltip = efficiencySection.locator('.chart-title', { hasText: 'Time to First Review (P50/P75/P90/P95)' }).locator('.tooltip-icon');
        const mergeTooltip = efficiencySection.locator('.chart-title', { hasText: 'Time to Merge (P50/P75/P90/P95)' }).locator('.tooltip-icon');

        await expect(reviewTooltip).toBeVisible();
        await expect(mergeTooltip).toBeVisible();
    });
});

test.describe('GitHub Percentile Charts - Quality & Health Section', () => {
    test.beforeEach(async ({ page }) => {
        await loadReport(page, 'github');
    });

    test('displays PR Size Distribution chart', async ({ page }) => {
        const prSizeChart = page.locator('#prSizePercentilesChart');
        await expect(prSizeChart).toBeVisible();
    });

    test('displays CI Time to Green Percentiles chart', async ({ page }) => {
        const timeToGreenChart = page.locator('#timeToGreenPercentilesChart');
        await expect(timeToGreenChart).toBeVisible();
    });

    test('displays CI Success Rate Distribution chart', async ({ page }) => {
        const ciSuccessChart = page.locator('#ciSuccessHistogramChart');
        await expect(ciSuccessChart).toBeVisible();
    });

    test('PR Size Distribution chart has proper title', async ({ page }) => {
        const qualitySection = page.locator('section', { has: page.locator('.section-title', { hasText: 'Quality & Health' }) });
        const chartTitle = qualitySection.locator('.chart-title', { hasText: 'PR Size Distribution' });

        await expect(chartTitle).toBeVisible();
    });

    test('CI Time to Green chart has proper title', async ({ page }) => {
        const qualitySection = page.locator('section', { has: page.locator('.section-title', { hasText: 'Quality & Health' }) });
        const chartTitle = qualitySection.locator('.chart-title', { hasText: 'CI Time to Green (P50/P75/P90/P95)' });

        await expect(chartTitle).toBeVisible();
    });

    test('CI Success Rate Distribution chart has proper title', async ({ page }) => {
        const qualitySection = page.locator('section', { has: page.locator('.section-title', { hasText: 'Quality & Health' }) });
        const chartTitle = qualitySection.locator('.chart-title', { hasText: 'CI Success Rate Distribution' });

        await expect(chartTitle).toBeVisible();
    });

    test('quality percentile charts have tooltips', async ({ page }) => {
        const qualitySection = page.locator('section', { has: page.locator('.section-title', { hasText: 'Quality & Health' }) });

        const prSizeTooltip = qualitySection.locator('.chart-title', { hasText: 'PR Size Distribution' }).locator('.tooltip-icon');
        const timeToGreenTooltip = qualitySection.locator('.chart-title', { hasText: 'CI Time to Green' }).locator('.tooltip-icon');
        const ciSuccessTooltip = qualitySection.locator('.chart-title', { hasText: 'CI Success Rate Distribution' }).locator('.tooltip-icon');

        await expect(prSizeTooltip).toBeVisible();
        await expect(timeToGreenTooltip).toBeVisible();
        await expect(ciSuccessTooltip).toBeVisible();
    });
});

test.describe('GitHub Percentile Charts - Collaboration Section', () => {
    test.beforeEach(async ({ page }) => {
        await loadReport(page, 'github');
    });

    test('displays Weekly PR Throughput chart', async ({ page }) => {
        const throughputChart = page.locator('#weeklyThroughputChart');
        await expect(throughputChart).toBeVisible();
    });

    test('Weekly PR Throughput chart has proper title', async ({ page }) => {
        const collaborationSection = page.locator('section', { has: page.locator('.section-title', { hasText: 'Collaboration Trends' }) });
        const chartTitle = collaborationSection.locator('.chart-title', { hasText: 'Weekly PR Throughput' });

        await expect(chartTitle).toBeVisible();
    });

    test('Weekly PR Throughput chart has tooltip', async ({ page }) => {
        const collaborationSection = page.locator('section', { has: page.locator('.section-title', { hasText: 'Collaboration Trends' }) });
        const tooltip = collaborationSection.locator('.chart-title', { hasText: 'Weekly PR Throughput' }).locator('.tooltip-icon');

        await expect(tooltip).toBeVisible();
    });
});

test.describe('GitHub Percentile Charts - Canvas Rendering', () => {
    test.beforeEach(async ({ page }) => {
        await loadReport(page, 'github');
    });

    test('all GitHub percentile charts have non-zero dimensions', async ({ page }) => {
        // Wait for Chart.js to render
        await page.waitForTimeout(500);

        const chartIds = [
            'timeToReviewPercentilesChart',
            'timeToMergePercentilesChart',
            'prSizePercentilesChart',
            'timeToGreenPercentilesChart',
            'ciSuccessHistogramChart',
            'weeklyThroughputChart'
        ];

        for (const chartId of chartIds) {
            const chart = page.locator(`#${chartId}`);
            const box = await chart.boundingBox();

            expect(box?.width, `${chartId} should have width > 0`).toBeGreaterThan(0);
            expect(box?.height, `${chartId} should have height > 0`).toBeGreaterThan(0);
        }
    });
});
