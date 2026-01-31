// assets/javascripts/discourse/api-initializers/hb-streamers-live-indicator.js
import { apiInitializer } from "discourse/lib/api";
import { ajax } from "discourse/lib/ajax";

// Polling interval for the UI indicator. The server should cache for a short TTL,
// so this can stay reasonably frequent without hammering Icecast.
const POLL_VISIBLE_MS = 30000;
const POLL_HIDDEN_MS = 120000;

const STATUS_URL = "/streams/status.json";

function isVisible() {
  return !document.hidden;
}

function normalizeHref(href) {
  if (!href) return "";
  try {
    // Handle absolute URLs
    const url = new URL(href, window.location.origin);
    return url.pathname;
  } catch {
    // Handle relative paths
    return String(href).split("?")[0].split("#")[0];
  }
}

function findStreamsNavLinks() {
  // Prefer known navigation containers to avoid touching links in post content.
  const selectors = [
    "#navigation-bar a[href]",
    ".sidebar-wrapper a[href]",
    ".sidebar-section a[href]",
    ".hamburger-panel a[href]",
    ".d-header a[href]",
  ];

  const containers = document.querySelectorAll(
    "#navigation-bar, .sidebar-wrapper, .sidebar-section, .hamburger-panel, .d-header"
  );

  const links = new Set();

  // Fast path: scan only in known containers
  containers.forEach((container) => {
    container.querySelectorAll("a[href]").forEach((a) => {
      const path = normalizeHref(a.getAttribute("href"));
      if (path === "/streams" || path === "/streams/") {
        links.add(a);
      }
    });
  });

  // Fallback: if containers are missing in a given layout, try a conservative global scan
  if (!links.size) {
    document.querySelectorAll(selectors.join(",")).forEach((a) => {
      const path = normalizeHref(a.getAttribute("href"));
      if (path === "/streams" || path === "/streams/") {
        links.add(a);
      }
    });
  }

  return Array.from(links);
}

function upsertBadge(link, { live, count }) {
  // We insert inside the link to keep the clickable area correct.
  // The badge itself is pointer-events:none (via CSS) so clicks still trigger the link.
  let badge = link.querySelector(":scope > .hb-streams-live-badge");

  if (!live || !count) {
    if (badge) {
      badge.remove();
    }
    return;
  }

  if (!badge) {
    badge = document.createElement("span");
    badge.className = "hb-streams-live-badge";
    badge.setAttribute("aria-hidden", "true");
    link.appendChild(badge);
  }

  const display = count > 9 ? "9+" : String(count);
  badge.textContent = display;

  // Helpful tooltip without relying on extra i18n keys
  badge.title = `${count} live stream${count === 1 ? "" : "s"}`;
}

export default apiInitializer("1.8.0", (api) => {
  // Members-only forum: indicator is only useful for logged-in users.
  // Guard just in case the component is ever enabled on a login page.
  const currentUser = api.getCurrentUser?.();
  if (!currentUser) {
    return;
  }

  let state = { live: false, count: 0 };
  let timerId = null;
  let endpointMissing = false;

  function applyStateToNav() {
    const links = findStreamsNavLinks();
    links.forEach((link) => upsertBadge(link, state));
  }

  async function fetchStatus() {
    if (endpointMissing) return;

    try {
      const res = await ajax(STATUS_URL);
      const live = !!res?.live;
      const count = Number(res?.count || 0);

      const next = { live, count };
      state = next;

      // Always re-apply; links may have been re-rendered.
      applyStateToNav();
    } catch (e) {
      // If the endpoint doesn't exist yet (plugin not updated), stop polling quietly.
      // Other transient errors are ignored; we'll try again later.
      if (e?.jqXHR?.status === 404) {
        endpointMissing = true;
      }
    }
  }

  function scheduleNext() {
    if (endpointMissing) return;

    if (timerId) {
      clearTimeout(timerId);
      timerId = null;
    }

    const base = isVisible() ? POLL_VISIBLE_MS : POLL_HIDDEN_MS;
    const jitter = Math.floor(Math.random() * 3000);
    timerId = setTimeout(async () => {
      await fetchStatus();
      scheduleNext();
    }, base + jitter);
  }

  // Keep the badge present after route changes (menus can rerender)
  api.onPageChange(() => {
    applyStateToNav();
  });

  document.addEventListener("visibilitychange", () => {
    scheduleNext();
  });

  // Initial kick (tiny delay helps when menu renders async)
  setTimeout(async () => {
    applyStateToNav();
    await fetchStatus();
    scheduleNext();
  }, 500);
});
