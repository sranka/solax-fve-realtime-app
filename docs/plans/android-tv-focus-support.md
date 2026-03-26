# Android TV Focus & Launcher Support

## Context
The app runs on Android TV but the Settings modal (and other modals) don't receive focus when opened, making them unusable with a D-pad remote. There is currently zero focus management: no `tabindex`, no keyboard listeners, no `.focus()` calls. Additionally, the app lacks Android TV launcher metadata so it may not appear on the TV home screen.

## Changes

### 1. CSS focus-visible styles (`web/index.html` — style block, ~line 509)

Add visible focus rings for D-pad navigation on all interactive elements:
- `.btn:focus-visible`, `.header-btn:focus-visible`, `.conn-action-btn:focus-visible`, `.conn-item-info:focus-visible`, `.theme-btn:focus-visible`, `.lang-btn:focus-visible` → `outline: 2px solid var(--accent); outline-offset: 2px;`
- Replace `outline: none` on form inputs (lines 405, 413) with `outline: none` only for `:focus:not(:focus-visible)` so D-pad focus rings still appear

### 2. Focus management JS (`web/index.html` — script block, before modal code ~line 1495)

Add a focus stack utility (~40 lines):
- `_focusStack` array of `{modal, previousFocus}` entries
- `trapFocus(modalEl)` — pushes to stack, focuses first focusable child
- `releaseFocus()` — pops stack, restores previous focus
- `getFocusableElements(container)` — returns visible buttons, inputs, selects, textareas, `[tabindex="0"]` elements

### 3. Global keydown listener (`web/index.html` — script block)

Single `document.addEventListener('keydown', ...)` that handles:
- **Tab/Shift+Tab wrapping** inside active focus trap (prevent focus from leaving modal)
- **Escape key** closes topmost modal (confirm → edit → settings). Android TV back button sends Escape in WebView.
- **Enter/Space on `[tabindex="0"]`** elements triggers click (for non-button focusable elements)

### 4. Integrate focus trap into modal open/close (`web/index.html`)

- `openSettingsModal()` (line 1499): after adding `.open`, call `trapFocus(settingsModal)`
- `closeSettingsModal()` (line 1503): call `releaseFocus()`
- `openEditModal()` (line 1564): after adding `.open`, call `trapFocus(editModal)`, then focus `#cfgName`
- `closeEditModal()` (line 1588): call `releaseFocus()`
- `confirmDelete()` (line 1658): after adding `.open`, call `trapFocus(confirmOverlay)`, focus `#confirmNo`
- Extract confirm close logic into `closeConfirmDialog()` function, call `releaseFocus()` in it
- Update both confirm button handlers and the Escape handler to use `closeConfirmDialog()`

### 5. Make non-button interactive elements focusable (`web/index.html`)

- In `renderConnList()` (~line 1517): add `tabindex="0" role="button"` to `.conn-item-info` divs
- On `.logo-icon` (~line 516): add `tabindex="0" role="button"`
- On `#advancedToggle` (~line 781): add `tabindex="0" role="button"`

### 6. Android TV manifest (`android/app/src/main/AndroidManifest.xml`)

Add inside `<activity>`:
```xml
<intent-filter>
    <action android:name="android.intent.action.MAIN" />
    <category android:name="android.intent.category.LEANBACK_LAUNCHER" />
</intent-filter>
```

Add at `<manifest>` level (near permissions):
```xml
<uses-feature android:name="android.software.leanback" android:required="false" />
<uses-feature android:name="android.hardware.touchscreen" android:required="false" />
```

## Files to modify
- `web/index.html` — CSS focus styles, JS focus management, modal integration, tabindex attributes
- `android/app/src/main/AndroidManifest.xml` — leanback launcher + feature declarations

## Verification
1. Open the app in a browser, use Tab/Shift+Tab to navigate — focus should be visible and trapped inside modals
2. Press Escape to close modals — should close topmost modal and restore focus
3. Build Android APK and test on Android TV (or emulator with TV profile) — D-pad should navigate through the UI, Settings modal should receive focus when opened, Back button should close modals
4. Verify app appears on Android TV launcher
