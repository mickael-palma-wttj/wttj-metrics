import { test, expect } from '@playwright/test';
import { loadReport } from '../test-utils';

test.describe('Bug Tracking Section', () => {
    test.beforeEach(async ({ page }) => {
        await loadReport(page);
    });

    test('displays bug metrics grid', async ({ page }) => {
        const bugSection = page.locator('section', { has: page.locator('.section-title', { hasText: 'Bug Tracking' }) });
        const bugMetricCards = bugSection.locator('.metric-card');

        await expect(bugMetricCards.first()).toBeVisible();
        // Should have multiple bug metric cards
        const count = await bugMetricCards.count();
        expect(count).toBeGreaterThanOrEqual(3);
    });

    test('bug overview has metric cards with values', async ({ page }) => {
        const bugSection = page.locator('section', { has: page.locator('.section-title', { hasText: 'Bug Tracking' }) });
        const metricCards = bugSection.locator('.metric-card');

        // Each card should have value and label
        const firstCard = metricCards.first();
        await expect(firstCard.locator('.metric-value')).toBeVisible();
        await expect(firstCard.locator('.metric-label')).toBeVisible();
    });

    test('shows bug resolution rate', async ({ page }) => {
        // Resolution rate is shown in the bug team table, not as a card
        const bugTeamTable = page.locator('.data-table').filter({ hasText: 'Resolution Rate' });
        await expect(bugTeamTable).toBeVisible();
    });

    test('displays bug status chart', async ({ page }) => {
        const bugStatusChart = page.locator('#bugStatusChart');
        await expect(bugStatusChart).toBeVisible();
    });

    test('displays bugs by priority chart', async ({ page }) => {
        const priorityChart = page.locator('#bugsPriorityChart');
        await expect(priorityChart).toBeVisible();
    });

    test('displays bug flow chart', async ({ page }) => {
        const bugFlowChart = page.locator('#bugFlowChart');
        await expect(bugFlowChart).toBeVisible();
    });

    test('displays bugs by team chart', async ({ page }) => {
        const teamChart = page.locator('#bugsByTeamChart');
        await expect(teamChart).toBeVisible();
    });

    test('bugs by team table shows team data', async ({ page }) => {
        const bugSection = page.locator('section', { has: page.locator('.section-title', { hasText: 'Bug Tracking' }) });
        const table = bugSection.locator('.data-table');

        // Table should have header row
        await expect(table.locator('thead tr')).toBeVisible();

        // Table should have data rows
        const dataRows = table.locator('tbody tr');
        const count = await dataRows.count();
        expect(count).toBeGreaterThan(0);
    });

    test('resolution rate has correct styling', async ({ page }) => {
        const bugSection = page.locator('section', { has: page.locator('.section-title', { hasText: 'Bug Tracking' }) });
        const resolutionRateCells = bugSection.locator('.progress-bar');

        const count = await resolutionRateCells.count();
        expect(count).toBeGreaterThan(0);
    });

    test('bug stats table has sortable columns', async ({ page }) => {
        const bugSection = page.locator('section', { has: page.locator('.section-title', { hasText: 'Bug Tracking' }) });
        const table = bugSection.locator('#bugStatsTable');

        // Check that sortable headers exist
        const sortableHeaders = table.locator('th.sortable');
        const headerCount = await sortableHeaders.count();
        expect(headerCount).toBe(6); // Team, Total Created, Closed, Open, MTTR, Resolution Rate
    });

    test('bug stats table sorts by resolution rate descending by default', async ({ page }) => {
        const bugSection = page.locator('section', { has: page.locator('.section-title', { hasText: 'Bug Tracking' }) });
        const table = bugSection.locator('#bugStatsTable');

        // Wait for table to be visible and sorted
        await table.waitFor({ state: 'visible' });

        // Check that Resolution Rate column (6th header) has desc class
        const resolutionRateHeader = table.locator('th').nth(5);
        await expect(resolutionRateHeader).toHaveClass(/desc/);
    });

    test('clicking sortable header toggles sort order', async ({ page }) => {
        const bugSection = page.locator('section', { has: page.locator('.section-title', { hasText: 'Bug Tracking' }) });
        const table = bugSection.locator('#bugStatsTable');

        // Get the first sortable header (Team)
        const teamHeader = table.locator('th.sortable').first();

        // Click to sort ascending
        await teamHeader.click();
        await expect(teamHeader).toHaveClass(/asc/);

        // Click again to sort descending
        await teamHeader.click();
        await expect(teamHeader).toHaveClass(/desc/);
    });

    test('sorting by open bugs column works', async ({ page }) => {
        const bugSection = page.locator('section', { has: page.locator('.section-title', { hasText: 'Bug Tracking' }) });
        const table = bugSection.locator('#bugStatsTable');

        // Click Open column header (4th column, index 3)
        const openHeader = table.locator('th.sortable').nth(3);
        await openHeader.click();

        // Verify it has a sort indicator
        const hasAscOrDesc = await openHeader.evaluate(el =>
            el.classList.contains('asc') || el.classList.contains('desc')
        );
        expect(hasAscOrDesc).toBe(true);
    });
});
