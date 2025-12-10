import { test, expect } from '@playwright/test';
import { loadReport } from '../test-utils';

test.describe('Section Collapsibility', () => {
    test.beforeEach(async ({ page }) => {
        await loadReport(page);
    });

    test('sections have toggle switches', async ({ page }) => {
        const toggleSwitches = page.locator('.toggle-switch');
        const count = await toggleSwitches.count();

        // Should have multiple toggle switches (one per section)
        expect(count).toBeGreaterThanOrEqual(5);
    });

    test('clicking toggle switch collapses section', async ({ page }) => {
        const firstSection = page.locator('section').first();
        const sectionContent = firstSection.locator('.section-content');
        const toggleCheckbox = firstSection.locator('.toggle-switch input');

        // Section should be visible initially (checkbox checked)
        await expect(toggleCheckbox).toBeChecked();
        await expect(sectionContent).toBeVisible();

        // Click the toggle label (visible element) instead of the hidden input
        const toggleLabel = firstSection.locator('.toggle-switch');
        await toggleLabel.scrollIntoViewIfNeeded();
        await toggleLabel.click();

        // Section content should be collapsed
        await expect(sectionContent).toHaveClass(/collapsed/);
    });

    test('clicking section header toggles section', async ({ page }) => {
        const firstSection = page.locator('section').first();
        const sectionHeader = firstSection.locator('.section-header');
        const sectionContent = firstSection.locator('.section-content');

        // Click header to collapse
        await sectionHeader.click();
        await expect(sectionContent).toHaveClass(/collapsed/);

        // Click again to expand
        await sectionHeader.click();
        await expect(sectionContent).not.toHaveClass(/collapsed/);
    });

    test('chevron rotates when section is collapsed', async ({ page }) => {
        const firstSection = page.locator('section').first();
        const sectionHeader = firstSection.locator('.section-header');
        const chevron = firstSection.locator('.chevron');

        // Check initial state (expanded) - no collapsed class
        await expect(chevron).not.toHaveClass(/collapsed/);

        // Collapse section
        await sectionHeader.click();

        // Chevron should have collapsed class (rotated via CSS)
        await expect(chevron).toHaveClass(/collapsed/);
    });

    test('all sections can be collapsed and expanded', async ({ page }) => {
        const sections = page.locator('section');
        const count = await sections.count();

        for (let i = 0; i < count; i++) {
            const section = sections.nth(i);
            const sectionHeader = section.locator('.section-header');
            const sectionContent = section.locator('.section-content');

            // Collapse
            await sectionHeader.click();
            await expect(sectionContent).toHaveClass(/collapsed/);

            // Expand
            await sectionHeader.click();
            await expect(sectionContent).not.toHaveClass(/collapsed/);
        }
    });
});
