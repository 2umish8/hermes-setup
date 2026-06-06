# Dashboard Frontend — `index.html`

Single-page dark-theme dashboard using HTMX for live polling and vanilla JS for actions.

**File:** `~/.hermes/dashboard/index.html` (24KB, ~600 lines)

## Architecture

- **Single file**, no build step. Edit directly in code-server (port 8080).
- **HTMX 2** from CDN for auto-refresh: `hx-get="/api/stats" hx-trigger="load every:30s"`
- **Vanilla JS** for actions: modal open/close, fetch() calls, toast notifications
- **CSS custom properties** for dark GitHub-style theme

## Key Patterns

### HTMX Polling
```html
<!-- Stats auto-refresh every 30s -->
<div id="stats-panel" hx-get="/api/stats" hx-trigger="load every:30s" hx-swap="innerHTML">
```

The `htmx:afterSwap` event listener intercepts the swap and re-renders stats as structured HTML:
```javascript
document.body.addEventListener('htmx:afterSwap', function(evt) {
  if (evt.detail.target.id === 'stats-panel') {
    renderStats(evt.detail.xhr.response);
  }
});
```

**Why not HTMX for the table too?** The jobs table needs dynamic action buttons (pause/resume depend on state, delete needs confirmation). HTMX swap would lose event listeners. Use HTMX for raw JSON and `renderJobs()` to build DOM programmatically.

### Modal System

Two modals: job detail and create form. Both use `display: none` / `display: flex` toggle. Close on Escape key + overlay click.

```javascript
document.addEventListener('keydown', e => {
  if (e.key === 'Escape') { closeModal(); closeCreate(); }
});
```

### Responsive Design

Hides Next/Last Run columns on mobile — schedule + status are the key info at a glance.

```css
@media (max-width: 700px) {
  .jobs-table th:nth-child(4), .jobs-table td:nth-child(4),
  .jobs-table th:nth-child(5), .jobs-table td:nth-child(5) { display: none; }
}
```

### Status Badges

Four states with colored dot: **Scheduled** (green), **Paused** (amber), **Running** (blue), **Failed** (red).

### Toast Notifications

Positioned bottom-right, auto-dismiss 3.5s with slide-in animation.

## Key Edge Cases

- **Empty jobs list** — shows a prompt to create the first workflow
- **Job with long prompt** — preview truncates at 200 chars; full prompt in detail modal
- **No run logs yet** — shows "(no runs yet)" instead of empty section
- **Delete confirmation** — `confirm()` dialog before DELETE API call
- **XSS safety** — all user-controlled text (job names, prompts) passed through a `esc()` function that uses `textContent` assignment

## Editing Tips

- All API calls use relative paths — works behind reverse proxy or directly
- HTMX loaded from CDN — no local dependency
- Create form auto-resets after successful submission
- `htmx.trigger('#stats-panel', 'load')` in JS manually triggers an HTMX refresh after mutations