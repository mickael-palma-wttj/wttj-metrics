import { Page } from '@playwright/test';
import path from 'path';

export const REPORT_URL = `file://${path.resolve(__dirname, '..', 'report', 'report.html')}`;

export async function loadReport(page: Page): Promise<void> {
    await page.goto(REPORT_URL, { waitUntil: 'networkidle' });
}
