import { Page } from '@playwright/test';
import path from 'path';

export const LINEAR_REPORT_URL = `file://${path.resolve(__dirname, '..', 'report', 'linear_report.html')}`;
export const GITHUB_REPORT_URL = `file://${path.resolve(__dirname, '..', 'report', 'github_report.html')}`;

export async function loadReport(page: Page, type: 'linear' | 'github' = 'linear'): Promise<void> {
    const url = type === 'github' ? GITHUB_REPORT_URL : LINEAR_REPORT_URL;
    await page.goto(url, { waitUntil: 'networkidle' });
}
