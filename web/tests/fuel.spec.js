import { test, expect } from '@playwright/test';

test('load fuel page and get console log', async ({ page }) => {
    const logs = [];
    page.on('console', msg => logs.push(`[${msg.type()}] ${msg.text()}`));
    page.on('pageerror', error => logs.push(`[error] ${error.message}`));

    await page.goto('http://localhost:5173/#/login');
    await page.fill('input[type="email"]', 'admin@semanur.com');
    await page.fill('input[type="password"]', 'password');
    await page.click('button[type="submit"]');

    await page.waitForTimeout(1000);
    await page.goto('http://localhost:5173/#/fuel');
    await page.waitForTimeout(2000);

    const fs = require('fs');
    fs.writeFileSync('playwright_logs.txt', logs.join('\n'));
});
