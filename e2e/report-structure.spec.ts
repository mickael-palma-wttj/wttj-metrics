import { test, expect, Page } from '@playwright/test';
import { loadReport } from './test-utils';

/**
 * Test fixtures and helpers for report tests
 */

test.describe('Report Structure', () => {
    test.beforeEach(async ({ page }) => {
        await loadReport(page);
    });

    test('has correct page title', async ({ page }) => {
        await expect(page).toHaveTitle(/Linear Metrics Dashboard/);
    });

    test('displays main header with date', async ({ page }) => {
        const header = page.locator('h1');
        await expect(header).toContainText('Linear Metrics Dashboard');
    });

    test('shows subtitle with generation date', async ({ page }) => {
        const subtitle = page.locator('.subtitle');
        await expect(subtitle).toBeVisible();
        await expect(subtitle).toContainText('Generated on');
    });

    test('has all main sections', async ({ page }) => {
        const sections = [
            'Key Metrics',
            'Bug Tracking',
            'Ticket Flow',
            'Current Distribution',
            'Team Comparison',
            'Cycles by Team'
        ];

        for (const section of sections) {
            await expect(page.locator('.section-title', { hasText: section })).toBeVisible();
        }
    });

    test('has footer with source info', async ({ page }) => {
        const footer = page.locator('footer');
        await expect(footer).toContainText('Linear API');
        await expect(footer).toContainText('WTTJ Metrics');
    });
});
