# SB60 Blog Launch Checklist

## Quick Setup (5 minutes)

### 1. Choose Your URL

**Option A: Keep Current URL**
- Site will be at: `https://jackwallnerdvc.github.io/ralph-sb60`
- No changes needed

**Option B: Custom Domain**
- Buy domain (e.g., sb60intel.com) ~$12/yr
- Update `_config.yml` with new URL
- Add CNAME file

**Option C: Different GitHub Username**
- Rename GitHub account to `sb60-intel`
- OR create org account `sb60-intel`
- Update remote URL

### 2. Enable GitHub Pages

1. Go to https://github.com/JackWallnerDVC/ralph-sb60/settings/pages
2. Source: **Deploy from a branch**
3. Branch: **main** / **root**
4. Save

### 3. Commit Everything

```bash
cd /Users/jackwallner/clawd/ralph-sb60
git add .
git commit -m "SB60 Intel v1.0 - ready for launch"
git push origin main
```

### 4. Install Cron Job

```bash
cd /Users/jackwallner/clawd/skills/sb60-blog
./scripts/setup_cron.sh
```

### 5. Test First Post

```bash
./scripts/run_now.sh
```

## Verify Launch

- [ ] Site loads at your URL
- [ ] Welcome post is visible
- [ ] Author pages work
- [ ] RSS feed works (`/feed.xml`)
- [ ] Cron job installed (`crontab -l`)

## Next Posts (Auto-Scheduled)

| Time (UTC) | Persona |
|------------|---------|
| 00:00 | Insider |
| 06:00 | Analyst |
| 12:00 | Local |
| 18:00 | Rotating |

## Support

- Site URL: Check repo Settings → Pages
- Build status: Actions tab in repo
- Logs: `tail -f /Users/jackwallner/clawd/ralph-sb60/.ralph/publish.log`
