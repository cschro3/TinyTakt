// Zeit vom Erscheinen des Home-Bildschirms bis Mira (lavendelfarbene Pixel) sichtbar ist. Software-WebGL → relativ.
const { chromium } = require('playwright');
const [,, url, dpr='2'] = process.argv;
(async () => {
  const browser = await chromium.launch({ args: ['--use-gl=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
  const ctx = await browser.newContext({ viewport: { width: 393, height: 852 }, deviceScaleFactor: Number(dpr), isMobile: true, hasTouch: true, locale: 'de-DE' });
  const page = await ctx.newPage();
  await page.goto(url, { waitUntil: 'load', timeout: 120000 });
  await page.waitForTimeout(9000);
  for (let i = 0; i < 3; i++) { await page.mouse.click(196, 806); await page.waitForTimeout(1200); }
  const t0 = Date.now();
  await page.mouse.click(196, 806);
  let seen = -1;
  for (let k = 0; k < 90; k++) {
    const buf = await page.screenshot({ clip: { x: 30, y: 300, width: 140, height: 170 }, type: 'png' });
    const px = await page.evaluate(async (b64) => { const img = new Image(); img.src = 'data:image/png;base64,' + b64; await img.decode(); const c = document.createElement('canvas'); c.width = img.width; c.height = img.height; const x = c.getContext('2d'); x.drawImage(img, 0, 0); const d = x.getImageData(0, 0, c.width, c.height).data; let n = 0; for (let i = 0; i < d.length; i += 4) { const r = d[i], g = d[i + 1], b = d[i + 2]; if (r > 150 && b > 190 && g < 175 && b - g > 45 && r - g > 20) n++; } return n; }, buf.toString('base64'));
    if (px > 600) { seen = Date.now() - t0; break; }
    await page.waitForTimeout(250);
  }
  console.log(JSON.stringify({ url, dpr, sceneVisibleMs: seen }));
  await browser.close();
})();
