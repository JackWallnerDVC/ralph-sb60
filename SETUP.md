# SB60 Blog Setup

## Prerequisites

1. **GitHub Account**: Create repo `sb60-intel.github.io`
2. **GitHub Pages**: Enable in repo settings (Source: GitHub Actions)
3. **Ruby/Jekyll**: Install for local testing
4. **Git**: Configure credentials for pushing

## Setup Steps

### 1. Create GitHub Repo

Go to https://github.com/new
- Name: `sb60-intel.github.io`
- Public repo
- Don't initialize (we'll push from local)

### 2. Configure Remote

```bash
cd /Users/jackwallner/clawd/ralph-sb60
git remote add origin https://github.com/YOUR_USERNAME/sb60-intel.github.io.git
# OR if using SSH:
git remote add origin git@github.com:YOUR_USERNAME/sb60-intel.github.io.git
```

### 3. Initial Push

```bash
cd /Users/jackwallner/clawd/ralph-sb60
git add .
git commit -m "Initial SB60 Intel setup"
git push -u origin main
```

### 4. Enable GitHub Pages

1. Go to repo Settings → Pages
2. Source: GitHub Actions
3. Save

### 5. Install Cron Job

```bash
cd /Users/jackwallner/clawd/skills/sb60-blog
./scripts/setup_cron.sh
```

### 6. Test Manual Run

```bash
cd /Users/jackwallner/clawd/skills/sb60-blog
./scripts/run_now.sh
```

## Verify

- Site: https://sb60-intel.github.io
- Should show the welcome post
- Check Actions tab for build status

## Local Development

```bash
cd /Users/jackwallner/clawd/ralph-sb60
bundle install
bundle exec jekyll serve
# Open http://localhost:4000
```

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Build fails | Check `_config.yml` syntax |
| Push rejected | Pull first: `git pull origin main` |
| Site not updating | Check Actions tab for errors |
| Cron not running | Check `crontab -l` |
