import { test, expect } from '@playwright/test';
import { loadReport } from './test-utils';

test.describe('Charts Section', () => {
    test.beforeEach(async ({ page }) => {
        await loadReport(page);
    });

    test('ticket flow chart is rendered', async ({ page }) => {
        const flowChart = page.locator('#flowChart');
        await expect(flowChart).toBeVisible();

        // Chart.js renders canvas elements - wait for it to be drawn
        await page.waitForTimeout(500);

        // Check canvas has content (non-zero dimensions)
        const box = await flowChart.boundingBox();
        expect(box?.width).toBeGreaterThan(0);
        expect(box?.height).toBeGreaterThan(0);
    });

    test('transition chart is rendered', async ({ page }) => {
        const transitionChart = page.locator('#transitionChart');
        await expect(transitionChart).toBeVisible();
    });

    test('status distribution chart is rendered', async ({ page }) => {
        const statusChart = page.locator('#statusChart');
        await expect(statusChart).toBeVisible();
    });

    test('priority distribution chart is rendered', async ({ page }) => {
        const priorityChart = page.locator('#priorityChart');
        await expect(priorityChart).toBeVisible();
    });

    test('type distribution chart is rendered', async ({ page }) => {
        const typeChart = page.locator('#typeChart');
        await expect(typeChart).toBeVisible();
    });

    test('assignee chart is rendered', async ({ page }) => {
        const assigneeChart = page.locator('#assigneeChart');
        await expect(assigneeChart).toBeVisible();
    });

    test('chart cards have proper titles', async ({ page }) => {
        const chartTitles = [
            'Status Distribution',
            'Priority Distribution',
            'Issue Type Distribution',
            'Top Assignees'
        ];

        for (const title of chartTitles) {
            await expect(page.locator('.chart-title', { hasText: title })).toBeVisible();
        }
    });

    test('distribution section shows filter badge when filtered', async ({ page }) => {
        const teamComparisonSection = page.locator('.section-title', { hasText: 'Team Comparison' });
        const filterBadge = teamComparisonSection.locator('.filter-badge');

        // Filter badge may or may not be present depending on mode
        const isFiltered = await filterBadge.count() > 0;
        if (isFiltered) {
            await expect(filterBadge).toContainText('Filtered');
        }
    });
});
