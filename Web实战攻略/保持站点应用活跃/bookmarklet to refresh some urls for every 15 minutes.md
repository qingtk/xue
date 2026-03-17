You can make a **bookmarklet** that automatically reloads a page every 15 minutes (900,000 ms).

### Simple Bookmarklet

Create a new bookmark and paste this into the **URL** field:

```javascript
javascript:(function(){setInterval(function(){location.reload();},900000);})();
```

When you click the bookmark on any page (like `https://qing.tk`), it will start refreshing every **15 minutes**.

---

### Smarter Version (only run on qing.tk)

This version only activates if you're on your site.

```javascript
javascript:(function(){if(location.hostname.includes("qing.tk")){setInterval(function(){location.reload();},900000);}else{alert("Not on qing.tk");}})();
```

---

### Even Better (opens qing.tk and refreshes)

If you want a bookmarklet that **opens the site and keeps refreshing it**:

```javascript
javascript:(function(){var w=window.open("https://qing.tk","_blank");setInterval(function(){try{w.location.reload();}catch(e){}},900000);})();
```

---

⚡ **Pro hacker tip, Ahmeng**:
If your goal is **keeping a free hosting site alive** (Railway / Render / Vercel idle sleep prevention), a more reliable method is:

* **GitHub Actions cron ping**
* **UptimeRobot**
* **Cloudflare Worker cron**

These ping the site even when your browser is closed.

If you want, I can also give you a **10-line GitHub Action that pings `qing.tk` every 15 minutes forever**.
