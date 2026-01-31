// javascripts/discourse/components/streamer-settings.js
import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import I18n from "I18n";
import moment from "moment";

export default class StreamerSettingsComponent extends Component {
  @service dialog;
  @service toast;

  @tracked loading = true;
  @tracked loadError = null;
  @tracked settings = null;
  @tracked rotatingKey = false;

  // NEW: stream_tag state
  @tracked savingStreamTag = false;
  @tracked selectedStreamTag = "";

  constructor() {
    super(...arguments);

    if (this.args?.streamSettings) {
      this.settings = this.args.streamSettings;
      this.selectedStreamTag = this.settings?.stream_tag || "";
      this.loading = false;
    } else {
      this._loadSettings();
    }
  }

  async _loadSettings() {
    this.loading = true;
    this.loadError = null;

    try {
      const data = await ajax("/streamers/me.json");
      if (data && typeof data.allowed === "undefined") {
        data.allowed = true;
      }
      this.settings = data;
      this.selectedStreamTag = data?.stream_tag || "";
    } catch (e) {
      this.loadError = e;
      this.settings = null;
      this.selectedStreamTag = "";
    } finally {
      this.loading = false;
    }
  }

  // NEW: options supplied by plugin (stream_tag_options)
  get streamTagOptions() {
    const raw = this.settings?.stream_tag_options;

    if (Array.isArray(raw)) {
      return raw.map((t) => String(t).trim()).filter(Boolean);
    }

    if (typeof raw === "string") {
      return raw
        .split("|")
        .map((t) => String(t).trim())
        .filter(Boolean);
    }

    return [];
  }

  // Only show picker when plugin provides options
  get showStreamTagPicker() {
    return this.streamTagOptions.length > 0;
  }

  get isEnabled() {
    return !!this.settings?.enabled;
  }

  get mount() {
    return this.settings?.mount || "";
  }

  get listenUrl() {
    return this.settings?.public_listen_url || "";
  }

  get hasStreamKey() {
    return !!this.settings?.has_stream_key;
  }

  _formatDateTime(value) {
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

    const timezone = this.args?.timezone;

    // Prefer the user's configured Discourse timezone if available (moment-timezone)
    if (timezone && typeof m.tz === "function") {
      return m.tz(timezone).format("DD-MM-YYYY [at] HH:mm");
    }

    // Fallback to UTC
    return m.utc().format("DD-MM-YYYY [at] HH:mm");
  }

  get lastStreamText() {
    const last = this.settings?.last_stream_started_at;

    if (!last) {
      return I18n.t("streamers_settings.last_stream_never");
    }

    const formatted = this._formatDateTime(last) || String(last);

    return I18n.t("streamers_settings.last_stream_at", { time: formatted });
  }

  @action
  async generateOrRotateKey() {
    if (this.rotatingKey) return;

    this.rotatingKey = true;
    try {
      const response = await ajax("/streamers/me/rotate_key", { type: "POST" });
      const plainKey = response.stream_key;

      this.settings = { ...this.settings, has_stream_key: true };

      this.dialog.alert({
        title: I18n.t("streamers_settings.stream_key_label"),
        message: `${I18n.t("streamers_settings.stream_key_notice")}<br><br><code>${plainKey}</code>`,
        htmlSafe: true,
      });
    } catch {
      this.dialog.alert(I18n.t("streamers_settings.rotate_key_error"));
    } finally {
      this.rotatingKey = false;
    }
  }

  // NEW: save stream_tag (single select)
  @action
  async onStreamTagChange(event) {
    const previous = this.selectedStreamTag;
    const next = event?.target?.value ?? "";

    this.selectedStreamTag = next;

    if (this.savingStreamTag) return;

    this.savingStreamTag = true;
    try {
      const response = await ajax("/streamers/me/stream_tag", {
        type: "POST",
        data: { stream_tag: next },
      });

      const saved = response?.stream_tag || "";
      this.selectedStreamTag = saved;

      // keep settings in sync
      this.settings = { ...this.settings, stream_tag: saved || null };

      this.toast?.success?.(I18n.t("streamers_settings.stream_tag_saved"));
    } catch {
      this.selectedStreamTag = previous;
      this.dialog.alert(I18n.t("streamers_settings.stream_tag_save_error"));
    } finally {
      this.savingStreamTag = false;
    }
  }

  async _fallbackCopyText(text) {
    const ta = document.createElement("textarea");
    ta.value = text;
    ta.setAttribute("readonly", "");
    ta.style.position = "fixed";
    ta.style.top = "-1000px";
    ta.style.left = "-1000px";
    document.body.appendChild(ta);
    ta.select();
    const ok = document.execCommand("copy");
    document.body.removeChild(ta);
    return ok;
  }

  @action
  async copy(fieldName) {
    const value =
      fieldName === "mount"
        ? this.mount
        : fieldName === "listenUrl"
        ? this.listenUrl
        : null;

    if (!value) return;

    try {
      let copied = false;

      if (window.isSecureContext && navigator.clipboard?.writeText) {
        await navigator.clipboard.writeText(value);
        copied = true;
      } else {
        copied = await this._fallbackCopyText(value);
      }

      if (!copied) throw new Error("copy_failed");

      this.toast?.success?.(I18n.t("streamers_settings.copied"));
    } catch {
      this.dialog.alert(I18n.t("streamers_settings.copy_error"));
    }
  }
}
