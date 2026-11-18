// Misst das Auswahlmenü (Figur/Welt/Zeit/Musik) im Headless-Chromium (Software-WebGL → relativ, kein iPhone-Ersatz).
// Aufruf: node tools/perf/picker_measure.js <URL> <Label> [dpr=2] [Wartezeit nach dem Öffnen in s=0]
// Die Wartezeit simuliert „Menü war schon eine Weile offen“ (Vorwärmen abgeschlossen).
const { chromium } = require('playwright');
const [,, url, label, dpr = '2', settle = '0'] = process.argv;
(async () => {
  const browser = await chromium.launch({ args: ['--use-gl=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
  const ctx = await browser.newContext({ viewport: { width: 393, height: 852 }, deviceScaleFactor: Number(dpr), isMobile: true, hasTouch: true, locale: 'de-DE' });
  const page = await ctx.newPage();
  const cdp = await ctx.newCDPSession(page);
  await page.goto(url, { waitUntil: 'load', timeout: 120000 });
  await page.waitForTimeout(9000);
  for (let i = 0; i < 4; i++) { await page.mouse.click(196, 806); await page.waitForTimeout(1200); }
  await page.waitForTimeout(7000);
  await page.mouse.click(30, 30); // Menü öffnen
  await page.waitForTimeout(1500 + Number(settle) * 1000);
  await page.evaluate(() => { window.__rec = []; window.__ph = {}; const f = t => { window.__rec.push(t); requestAnimationFrame(f); }; requestAnimationFrame(f); window.__mark = n => { window.__ph[n] = window.__rec.length; }; });
  const mark = n => page.evaluate(n => window.__mark(n), n);
  const tabs = { Figur: [49, 90], Welt: [148, 90], Zeit: [246, 90], Musik: [344, 90] };
  const scroll = async (dy) => cdp.send('Input.synthesizeScrollGesture', { x: 196, y: 500, yDistance: dy, speed: 1500, gestureSourceType: 'touch' });
  await mark('start');
  await page.waitForTimeout(3000);                 await mark('idle_end');
  await scroll(-1400); await page.waitForTimeout(1200); await scroll(-1400); await page.waitForTimeout(1200); await scroll(-1400); await page.waitForTimeout(1200);
  await mark('scroll_end');
  await scroll(2000); await page.waitForTimeout(1500); await scroll(2000); await page.waitForTimeout(1500); await scroll(2000); await page.waitForTimeout(1200); await mark('scrollup_end');
  const seq = ['Welt', 'Zeit', 'Musik', 'Figur', 'Welt', 'Figur', 'Zeit', 'Figur'];
  const tabMarks = [];
  for (const t of seq) { await mark('pre_' + tabMarks.length); await page.mouse.click(...tabs[t]); await page.waitForTimeout(1800); tabMarks.push(t); }
  await mark('tabs_end');
  await page.mouse.click(196, 560); await page.waitForTimeout(1500); await mark('tap_end'); // Kachel antippen
  const out = await page.evaluate(() => ({ rec: window.__rec, ph: window.__ph }));
  const iv = (a, b) => { const r = []; for (let i = a + 1; i < b; i++) r.push(out.rec[i] - out.rec[i - 1]); return r; };
  const stats = (a, b) => { const r = iv(a, b); if (!r.length) return null; const s = [...r].sort((x, y) => x - y); const q = p => s[Math.min(s.length - 1, Math.floor(p * s.length))]; return { frames: r.length, fps: +(1000 * r.length / r.reduce((x, y) => x + y, 0)).toFixed(1), p50: +q(.5).toFixed(0), p95: +q(.95).toFixed(0), max: +s[s.length - 1].toFixed(0) }; };
  const ph = out.ph;
  const res = { label, dpr: Number(dpr), idle: stats(ph.start, ph.idle_end), scroll_down: stats(ph.idle_end, ph.scroll_end), scroll_up: stats(ph.scroll_end, ph.scrollup_end), tabs: stats(ph.scrollup_end, ph.tabs_end), tap: stats(ph.tabs_end, ph.tap_end) };
  res.tabSwitchMaxMs = seq.map((t, i) => { const a = ph['pre_' + i], b = (ph['pre_' + (i + 1)] ?? ph.tabs_end); const r = iv(a, b); return [t, +Math.max(...r.slice(0, 12)).toFixed(0)]; });
  const m = await cdp.send('Performance.getMetrics').catch(() => null);
  console.log(JSON.stringify(res));
  await browser.close();
})();
