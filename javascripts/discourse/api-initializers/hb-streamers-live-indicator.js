// assets/javascripts/discourse/api-initializers/hb-streamers-live-indicator.js
import { apiInitializer } from "discourse/lib/api";
import { ajax } from "discourse/lib/ajax";

const STATUS_URL = "/streams/status.json";

// Adaptive polling:
// - When live: poll faster so badge disappears quickly after stream ends
// - When idle: poll slowly to reduce load
const POLL_VISIBLE_LIVE_MS = 8000;
const POLL_VISIBLE_IDLE_MS = 60000;
const POLL_HIDDEN_MS = 120000;

// If the UI (menu) appears and our last fetch is older than this, refresh immediately
const STALE_REFRESH_MS = 8000;

function isVisible() {
  return !document.hidden;
}

function normalizePath(href) {
  if (!href) return "";
  try {
    const url = new URL(href, window.location.origin);
    return url.pathname;
  } catch {
    return String(href).split("?")[0].split("#")[0];
  }
}

function isStreamsLink(a) {
  const path = normalizePath(a.getAttribute("href"));
  return path === "/streams" || path === "/streams/";
}

function findStreamsLinksIn(root) {
  if (!root) return [];
  const anchors = root.querySelectorAll ? root.querySelectorAll("a[href]") : [];
  return Array.from(anchors).filter(isStreamsLink);
}

function findAllStreamsNavLinks() {
  // Limit scanning to known navigation containers where menu links live
  const containers = document.querySelectorAll(
    "#navigation-bar, .sidebar-wrapper, .sidebar-section, .hamburger-panel, .d-header, .mobile-nav"
  );

  const links = new Set();

  containers.forEach((c) => {
    findStreamsLinksIn(c).forEach((a) => links.add(a));
  });

  // Conservative fallback if theme/layout differs
  if (!links.size) {
    document.querySelectorAll("a[href]").forEach((a) => {
      // Avoid scanning post content on huge pages by only considering links that look like nav links
      // (still safe: if it matches /streams, badge append is harmless)
      if (isStreamsLink(a)) links.add(a);
    });
  }

  return Array.from(links);
}

function upsertBadge(link, state) {
  let badge = link.querySelector(":scope > .hb-streams-live-badge");

  if (!state.live || !state.count) {
    if (badge) badge.remove();
    return;
  }

  if (!badge) {
    badge = document.createElement("span");
    badge.className = "hb-streams-live-badge";
    badge.setAttribute("aria-hidden", "true");
    link.appendChild(badge);
  }

  const display = state.count > 9 ? "9+" : String(state.count);
  badge.textContent = display;
  badge.title = `${state.count} live stream${state.count === 1 ? "" : "s"}`;
}

export default apiInitializer("1.8.0", (api) => {
  const currentUser = api.getCurrentUser?.();
  if (!currentUser) return; // members-only forum: no need on anon pages

  let state = { live: false, count: 0 };
  let lastFetchAt = 0;
  let timerId = null;
  let inFlight = false;
  let endpointMissing = false;

  function applyStateToNav() {
    const links = findAllStreamsNavLinks();
    links.forEach((link) => upsertBadge(link, state));
  }

  async function fetchStatus({ force = false } = {}) {
    if (endpointMissing || inFlight) return;

    const now = Date.now();
    if (!force && lastFetchAt && now - lastFetchAt < 1500) {
      return; // small anti-spam guard
    }

    inFlight = true;
    try {
      const res = await ajax(STATUS_URL);
      state = {
        live: !!res?.live,
        count: Number(res?.count || 0),
      };
      lastFetchAt = Date.now();

      // Links can be re-rendered, always re-apply after fetch
      applyStateToNav();
    } catch (e) {
      // If plugin endpoint isn't present yet, stop quietly
      const code = e?.jqXHR?.status;
      if (code === 404) {
        endpointMissing = true;
      }
      // On transient errors we keep previous state; next schedule will retry.
    } finally {
      inFlight = false;
    }
  }

  function nextIntervalMs() {
    if (!isVisible()) return POLL_HIDDEN_MS;
    return state.live ? POLL_VISIBLE_LIVE_MS : POLL_VISIBLE_IDLE_MS;
  }

  function scheduleNext() {
    if (endpointMissing) return;

    if (timerId) {
      clearTimeout(timerId);
      timerId = null;
    }

    const base = nextIntervalMs();
    // jitter prevents thundering herd
    const jitter = Math.floor(Math.random() * (state.live ? 1200 : 4000));

    timerId = setTimeout(async () => {
      await fetchStatus();
      scheduleNext();
    }, base + jitter);
  }

  function maybeRefreshBecauseUIAppeared() {
    // When the menu/links appear (mobile), immediately apply the last known state
    applyStateToNav();

    // If our last fetch is stale, refresh immediately so the user doesn't wait for the next poll
    const now = Date.now();
    if (isVisible() && (!lastFetchAt || now - lastFetchAt > STALE_REFRESH_MS)) {
      fetchStatus({ force: true });
    }
  }

  // Re-apply on route changes (nav can re-render)
  api.onPageChange(() => {
    maybeRefreshBecauseUIAppeared();
  });

  // If tab becomes visible, refresh quickly
  document.addEventListener("visibilitychange", () => {
    if (isVisible()) {
      fetchStatus({ force: true });
    }
    scheduleNext();
  });

  // MutationObserver: catches mobile hamburger menu opening (DOM nodes are created)
  const observer = new MutationObserver((mutations) => {
    for (const m of mutations) {
      if (!m.addedNodes || !m.addedNodes.length) continue;

      for (const node of m.addedNodes) {
        if (!(node instanceof HTMLElement)) continue;

        // If the added subtree contains a /streams link, update immediately
        const links = findStreamsLinksIn(node);
        if (links.length) {
          maybeRefreshBecauseUIAppeared();
          return;
        }
      }
    }
  });

  observer.observe(document.body, { childList: true, subtree: true });

  // Initial kick
  setTimeout(async () => {
    maybeRefreshBecauseUIAppeared();
    await fetchStatus({ force: true });
    scheduleNext();
  }, 300);
});
