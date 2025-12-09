import { test, expect } from '@playwright/test';
import { loadReport } from '../test-utils';

test.describe('GitHub Report Structure', () => {
    test.beforeEach(async ({ page }) => {
        await loadReport(page, 'github');
    });

    test('has correct page title', async ({ page }) => {
        await expect(page).toHaveTitle(/GitHub Metrics Dashboard/);
    });

    test('displays main header with date', async ({ page }) => {
        const header = page.locator('h1');
        await expect(header).toContainText('GitHub Metrics Dashboard');
    });

    test('shows subtitle with generation date', async ({ page }) => {
        const subtitle = page.locator('.subtitle');
        await expect(subtitle).toBeVisible();
        await expect(subtitle).toContainText('Generated on');
    });

    test('has all main sections', async ({ page }) => {
        const sections = [
            'Key Metrics',
            'Trends'
        ];

        for (const section of sections) {
            await expect(page.locator('.section-title', { hasText: section })).toBeVisible();
        }
    });

    test('has all charts', async ({ page }) => {
        const charts = [
            'Time to Merge History',
            'Time to First Review History',
            'Reviews & Comments History',
            'PR Size History'
        ];

        for (const chart of charts) {
            await expect(page.locator('.chart-title', { hasText: chart })).toBeVisible();
        }
    });

    test('has footer with source info', async ({ page }) => {
        const footer = page.locator('footer');
        await expect(footer).toContainText('GitHub API');
        await expect(footer).toContainText('WTTJ Metrics');
    });
});
