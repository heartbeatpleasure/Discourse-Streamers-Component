// assets/javascripts/discourse/routes/streams.js
import DiscourseRoute from "discourse/routes/discourse";
import { ajax } from "discourse/lib/ajax";
import moment from "moment";
import { later, cancel } from "@ember/runloop";

const POLL_INTERVAL_MS = 15000;

function formatDateTime(value, timezone) {
  if (!value) return null;

  const m = moment(value);
  if (!m.isValid()) {
    // Best-effort fallback for ISO-like strings
    const s = String(value);
    const match = s.match(/^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2})/);
    if (match) {
      const [, yyyy, mm, dd, HH, MM] = match;
      return `${dd}-${mm}-${yyyy} at ${HH}:${MM}`;
    }
    return s;
  }

  // Prefer the user's configured Discourse timezone if available (moment-timezone)
  if (timezone && typeof m.tz === "function") {
    return m.tz(timezone).format("DD-MM-YYYY [at] HH:mm");
  }

  // Fallback to UTC
  return m.utc().format("DD-MM-YYYY [at] HH:mm");
}

export default class StreamsRoute extends DiscourseRoute {
  pollTimer = null;
  isPolling = false;

  async model() {
    const streamsData = await ajax("/streams.json");

    const timezone =
      this.currentUser?.user_option?.timezone || this.currentUser?.timezone || null;
    const formatted_updated_at = formatDateTime(streamsData?.updated_at, timezone);

    let me = null;
    if (this.currentUser) {
      try {
        me = await ajax("/streamers/me.json");
        if (me && typeof me.allowed === "undefined") {
          me.allowed = true;
        }
      } catch {
        me = null;
      }
    }

    return Object.assign({}, streamsData, { me, formatted_updated_at, timezone });
  }

  setupController(controller, model) {
    super.setupController(controller, model);
    this._startPolling();
  }

  resetController(controller, isExiting) {
    super.resetController(...arguments);
    if (isExiting) {
      this._stopPolling();
    }
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this._stopPolling();
  }

  _startPolling() {
    if (this.pollTimer) return;
    this._scheduleNextPoll();
  }

  _scheduleNextPoll() {
    this.pollTimer = later(this, this._pollStreams, POLL_INTERVAL_MS);
  }

  _stopPolling() {
    if (this.pollTimer) {
      cancel(this.pollTimer);
      this.pollTimer = null;
    }
    this.isPolling = false;
  }

  async _pollStreams() {
    // allow a fresh schedule even if we early-return
    this.pollTimer = null;

    if (this.isDestroyed || this.isDestroying) return;

    // prevent overlapping requests
    if (this.isPolling) {
      this._scheduleNextPoll();
      return;
    }

    this.isPolling = true;

    try {
      const streamsData = await ajax("/streams.json");

      const controller = this.controllerFor("streams");
      const currentModel = controller?.model || {};

      const timezone =
        currentModel.timezone ||
        this.currentUser?.user_option?.timezone ||
        this.currentUser?.timezone ||
        null;

      const formatted_updated_at = formatDateTime(streamsData?.updated_at, timezone);

      // Merge: keep existing keys (like `me`, `timezone`), update stream data, recompute formatted_updated_at
      const nextModel = Object.assign({}, currentModel, streamsData, {
        formatted_updated_at,
      });

      if (controller && !controller.isDestroyed && !controller.isDestroying) {
        // Replacing the whole model ensures the template updates (streams added/removed + listener counts)
        controller.set("model", nextModel);
      }
    } catch {
      // ignore transient errors; try again next tick
    } finally {
      this.isPolling = false;

      if (!this.isDestroyed && !this.isDestroying) {
        this._scheduleNextPoll();
      }
    }
  }
}
