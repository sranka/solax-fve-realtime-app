# PWA: Manifest, Icons & Offline Shell

## Goal

Make the web app installable on iOS and Android home screens with proper icons, standalone display mode (no browser chrome), and basic offline support so the app opens cleanly even without connectivity.

## Scope

- Web app manifest with icons
- Standalone/fullscreen display mode
- Network-first service worker for offline shell
- Works in Safari and Chrome

**Out of scope:** push notifications, background sync, offline data display, changes to Capacitor builds or server.

## Changes

### 1. Generate PNG icons from `web/icon.svg`

- `web/apple-touch-icon.png` — 180x180
- `web/icon-192.png` — 192x192
- `web/icon-512.png` — 512x512

### 2. Create `web/manifest.json`

```json
{
  "name": "Solax FVE Realtime",
  "short_name": "Solax FVE",
  "display": "standalone",
  "start_url": "/",
  "theme_color": "#0a0e1a",
  "background_color": "#0a0e1a",
  "icons": [
    { "src": "icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "icon-512.png", "sizes": "512x512", "type": "image/png" }
  ]
}
```

### 3. Create `web/sw.js` — network-first service worker

- **install**: pre-cache `index.html`, `build-info.js`, icons, manifest
- **fetch**: try network first; on success update cache; on failure fall back to cached version
- **activate**: clean up old caches
- Versioned cache name (can be tied to `build-info.js` stamp)

### 4. Update `index.html` `<head>` — add meta/link tags

```html
<link rel="manifest" href="manifest.json">
<link rel="apple-touch-icon" href="apple-touch-icon.png">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
```

### 5. Replace service worker unregistration with registration

Remove the existing unregistration block (~lines 1914-1918) and replace with:

```javascript
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('sw.js');
}
```

### 6. Update `scripts/stamp-build.sh`

Include `sw.js` in the fingerprint calculation so the cache busts on deploy.
