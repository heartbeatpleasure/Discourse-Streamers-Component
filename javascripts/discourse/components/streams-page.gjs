import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { registerDestructor } from "@ember/destroyable";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { ajax } from "discourse/lib/ajax";
import avatar from "discourse/helpers/avatar";
import { i18n } from "discourse-i18n";
import StreamerSettings from "./streamer-settings";
import StreamersChatButton from "./streamers-chat-button";
import StreamersListenButton from "./streamers-listen-button";
import hbUserProfileUrl from "../helpers/hb-user-profile-url";

const PAGE_EVENT = "hb-streamers:page-update";

function normalizeModel(model) {
  return {
    ...(model || {}),
    live_streams: Array.isArray(model?.live_streams) ? model.live_streams : [],
    me: model?.me || null,
    timezone: model?.timezone || null,
    chat_topic_id: model?.chat_topic_id || 0,
    updated_at: model?.updated_at || null,
    formatted_updated_at: model?.formatted_updated_at || null,
  };
}

function formatUpdatedAt(value, timezone) {
  const date = value ? new Date(value) : new Date();
  if (Number.isNaN(date.getTime())) {
    return value || null;
  }

  try {
    const parts = new Intl.DateTimeFormat("en-GB", {
      timeZone: timezone || undefined,
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
      hour12: false,
    }).formatToParts(date);

    const byType = Object.fromEntries(parts.map((p) => [p.type, p.value]));
    if (
      byType.day &&
      byType.month &&
      byType.year &&
      byType.hour &&
      byType.minute &&
      byType.second
    ) {
      return `${byType.day}-${byType.month}-${byType.year} at ${byType.hour}:${byType.minute}:${byType.second}`;
    }
  } catch {
    // fall through
  }

  const dd = String(date.getDate()).padStart(2, "0");
  const mm = String(date.getMonth() + 1).padStart(2, "0");
  const yyyy = String(date.getFullYear());
  const hh = String(date.getHours()).padStart(2, "0");
  const min = String(date.getMinutes()).padStart(2, "0");
  const sec = String(date.getSeconds()).padStart(2, "0");
  return `${dd}-${mm}-${yyyy} at ${hh}:${min}:${sec}`;
}

export default class StreamsPageComponent extends Component {
  @service appEvents;

  @tracked state = normalizeModel(this.args.initialModel);
  @tracked lastUpdatedDisplay = null;
  @tracked listenerDialogStream = null;

  constructor() {
    super(...arguments);

    this._handlePageUpdate = this._handlePageUpdate.bind(this);
    this._syncLastUpdatedDisplay(this.state, { ensureFallback: true });

    if (typeof window !== "undefined") {
      window.addEventListener(PAGE_EVENT, this._handlePageUpdate);
      registerDestructor(this, () => {
        window.removeEventListener(PAGE_EVENT, this._handlePageUpdate);
        this._clearNativeCardLayer();
        this._setNativeCardLayerOpen(false);
      });
    }

    if (!this.state.me) {
      this._loadMe();
    }
  }

  get hasUpdatedDisplay() {
    return !!this.lastUpdatedDisplay;
  }

  get listenerDialogKnownListeners() {
    const listeners = this.listenerDialogStream?.known_listeners;
    return Array.isArray(listeners) ? listeners : [];
  }

  get listenerDialogPublicCount() {
    return Number(this.listenerDialogStream?.public_listener_count || 0);
  }

  get listenerDialogDetailsVisible() {
    return this.listenerDialogStream?.listener_details_visible !== false;
  }

  get listenerDialogHasKnownListeners() {
    return this.listenerDialogKnownListeners.length > 0;
  }

  get listenerDialogHasPublicListeners() {
    return this.listenerDialogPublicCount > 0;
  }

  get listenerDialogShowEmpty() {
    return !this.listenerDialogHasKnownListeners && !this.listenerDialogHasPublicListeners;
  }

  get listenerDialogUsername() {
    return this.listenerDialogStream?.username || this.listenerDialogStream?.name || "";
  }

  _syncLastUpdatedDisplay(nextState, { ensureFallback = false } = {}) {
    this.lastUpdatedDisplay =
      formatUpdatedAt(nextState?.updated_at, nextState?.timezone || this.state?.timezone) ||
      nextState?.formatted_updated_at ||
      this.lastUpdatedDisplay ||
      (ensureFallback ? formatUpdatedAt(null, nextState?.timezone || this.state?.timezone) : null);
  }

  async _loadMe() {
    try {
      const me = await ajax("/streamers/me.json");
      if (me && typeof me.allowed === "undefined") {
        me.allowed = true;
      }
      this.state = normalizeModel({ ...this.state, me });
    } catch {
      // anonymous user or endpoint unavailable; leave settings hidden
    }
  }

  _handlePageUpdate(event) {
    const nextState = event?.detail?.state;
    if (!nextState) {
      return;
    }

    this.state = normalizeModel({
      ...this.state,
      ...nextState,
      me: nextState.me ?? this.state.me,
      timezone: nextState.timezone ?? this.state.timezone,
      chat_topic_id: nextState.chat_topic_id ?? this.state.chat_topic_id,
    });

    if (this.listenerDialogStream?.mount) {
      const refreshedStream = this.state.live_streams.find(
        (stream) => stream.mount === this.listenerDialogStream.mount
      );
      this.listenerDialogStream = this._canOpenListenerDialog(refreshedStream) ? refreshedStream : null;
      if (!this.listenerDialogStream) {
        this._setNativeCardLayerOpen(false);
      }
    }

    this._syncLastUpdatedDisplay(this.state, { ensureFallback: true });
  }

  _canOpenListenerDialog(stream) {
    return !!stream && stream.listener_details_visible !== false && Number(stream.listeners || 0) > 0;
  }

  _setNativeCardLayerOpen(open) {
    try {
      document?.documentElement?.classList?.toggle("hb-stream-listeners-open", !!open);
      document?.body?.classList?.toggle("hb-stream-listeners-open", !!open);
    } catch {
      // ignore
    }
  }

  cleanUsername(username) {
    return String(username || "").replace(/^@+/, "").trim();
  }

  _clearNativeCardLayer() {
    try {
      document
        .querySelectorAll(".hb-stream-native-card-layer, .hb-stream-native-card-popup")
        .forEach((el) => {
          el.classList?.remove("hb-stream-native-card-layer");
          el.classList?.remove("hb-stream-native-card-popup");
        });
    } catch {
      // ignore
    }
  }

  _raiseNativeCardLayer() {
    const apply = () => {
      try {
        const selectors = [
          "#d-menu-portals",
          ".d-menu-portals",
          ".fk-d-menu-modal",
          ".fk-d-menu-content",
          ".floating-ui-portal",
          ".ember-basic-dropdown-content",
          "#user-card",
          "#group-card",
          ".user-card",
          ".group-card",
          ".card-contents",
          ".card-content",
        ];

        document.querySelectorAll(selectors.join(",")).forEach((el) => {
          if (!el?.classList) {
            return;
          }

          const isKnownCard =
            el.id === "user-card" ||
            el.id === "group-card" ||
            el.classList.contains("user-card") ||
            el.classList.contains("group-card") ||
            Boolean(el.closest?.("#user-card,#group-card,.user-card,.group-card"));

          const looksLikeCardContent =
            el.classList.contains("card-contents") ||
            (el.classList.contains("card-content") &&
              Boolean(
                el.querySelector?.(
                  ".user-card-avatar,.user-card-controls,.names,.metadata,.card-row,[data-user-card]"
                )
              ));

          const isKnownPortal =
            el.id === "d-menu-portals" ||
            el.classList.contains("d-menu-portals") ||
            el.classList.contains("fk-d-menu-modal") ||
            el.classList.contains("fk-d-menu-content") ||
            el.classList.contains("floating-ui-portal") ||
            el.classList.contains("ember-basic-dropdown-content");

          if (!(isKnownCard || looksLikeCardContent || isKnownPortal)) {
            return;
          }

          el.classList.add("hb-stream-native-card-layer");
          if (isKnownCard || looksLikeCardContent) {
            el.classList.add("hb-stream-native-card-popup");
          }

          let parent = el.parentElement;
          while (parent && parent !== document.body && parent !== document.documentElement) {
            if (
              parent.id === "d-menu-portals" ||
              parent.classList?.contains("d-menu-portals") ||
              parent.classList?.contains("fk-d-menu-modal") ||
              parent.classList?.contains("fk-d-menu-content") ||
              parent.classList?.contains("floating-ui-portal") ||
              parent.classList?.contains("ember-basic-dropdown-content")
            ) {
              parent.classList.add("hb-stream-native-card-layer");
            }
            parent = parent.parentElement;
          }
        });
      } catch {
        // ignore
      }
    };

    apply();
    setTimeout(apply, 60);
    setTimeout(apply, 180);
    setTimeout(apply, 360);
  }

  _triggerNativeUserCard(username, event) {
    if (!event) {
      return;
    }

    if (event.button && event.button !== 0) {
      return;
    }
    if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) {
      return;
    }

    const cleanedUsername = this.cleanUsername(username);
    if (!cleanedUsername || cleanedUsername === "unknown") {
      return;
    }

    const target = event.currentTarget || event.target?.closest?.("[data-user-card]");
    if (!target || !this.appEvents?.trigger) {
      return;
    }

    event.preventDefault?.();
    event.stopPropagation?.();
    this._setNativeCardLayerOpen(true);
    this._raiseNativeCardLayer();
    this.appEvents.trigger("topic-header:trigger-user-card", cleanedUsername, target, event);
    this._raiseNativeCardLayer();
  }

  @action
  openListenerDialog(stream) {
    if (!this._canOpenListenerDialog(stream)) {
      return;
    }

    this.listenerDialogStream = stream;
    this._setNativeCardLayerOpen(true);
  }

  @action
  closeListenerDialog() {
    this.listenerDialogStream = null;
    this._clearNativeCardLayer();
    this._setNativeCardLayerOpen(false);
  }

  @action
  handleStreamerUserClick(stream, event) {
    this._triggerNativeUserCard(stream?.username, event);
  }

  @action
  handleListenerUserClick(listener, event) {
    this._triggerNativeUserCard(listener?.username, event);
  }

  <template>
    <div class="hb-streams-page">
      <h1 class="hb-streams-title">
        {{i18n "streamers.title"}}
      </h1>

      {{#if this.state.live_streams.length}}
        <div class="hb-streams-list">
          {{#each this.state.live_streams as |stream|}}
            <article class="hb-stream-card">
              <div class="hb-stream-avatar">
                {{#if stream.username}}
                  <a
                    class="hb-stream-user-link trigger-user-card"
                    href={{hbUserProfileUrl stream.username}}
                    data-user-card={{this.cleanUsername stream.username}}
                    title={{stream.username}}
                    {{on "click" (fn this.handleStreamerUserClick stream)}}
                  >
                    {{avatar
                      stream
                      usernamePath="username"
                      namePath="name"
                      avatarTemplatePath="avatar_template"
                      imageSize="huge"
                    }}
                  </a>
                {{else}}
                  {{avatar
                    stream
                    usernamePath="username"
                    namePath="name"
                    avatarTemplatePath="avatar_template"
                    imageSize="huge"
                  }}
                {{/if}}
              </div>

              <div class="hb-stream-main">
                <div class="hb-stream-user-row">
                  <span class="hb-stream-username">
                    {{#if stream.username}}
                      <a
                        class="hb-stream-user-link trigger-user-card"
                        href={{hbUserProfileUrl stream.username}}
                        data-user-card={{this.cleanUsername stream.username}}
                        title={{stream.username}}
                        {{on "click" (fn this.handleStreamerUserClick stream)}}
                      >
                        {{if stream.username stream.username stream.name}}
                      </a>
                    {{else}}
                      {{if stream.username stream.username stream.name}}
                    {{/if}}
                  </span>

                  <span class="hb-stream-live-pill">
                    {{i18n "streamers.live"}}
                  </span>

                  {{#if stream.stream_tag}}
                    <span class="hb-stream-tag-pill">
                      {{stream.stream_tag}}
                    </span>
                  {{/if}}

                  <div class="hb-stream-actions">
                    <StreamersChatButton
                      @chatTopicId={{if stream.chat_topic_id stream.chat_topic_id this.state.chat_topic_id}}
                    />
                    <StreamersListenButton @stream={{stream}} />
                  </div>
                </div>

                <div class="hb-stream-meta">
                  {{#if stream.listener_details_visible}}
                    {{#if stream.listeners}}
                      <button
                        type="button"
                        class="hb-stream-listeners-trigger"
                        {{on "click" (fn this.openListenerDialog stream)}}
                      >
                        {{i18n "streamers.listeners" count=stream.listeners}}
                      </button>
                    {{else}}
                      <span class="hb-stream-meta-item">
                        {{i18n "streamers.listeners" count=stream.listeners}}
                      </span>
                    {{/if}}
                  {{else}}
                    <span class="hb-stream-meta-item">
                      {{i18n "streamers.listeners" count=stream.listeners}}
                    </span>
                  {{/if}}

                  {{#if stream.age}}
                    <span class="hb-stream-meta-sep">•</span>
                    <span class="hb-stream-meta-item">
                      Age: {{stream.age}}
                    </span>
                  {{/if}}

                  {{#if stream.gender}}
                    <span class="hb-stream-meta-sep">•</span>
                    <span class="hb-stream-meta-item">
                      {{stream.gender}}
                    </span>
                  {{/if}}
                </div>
              </div>
            </article>
          {{/each}}
        </div>
      {{else}}
        <p class="hb-streams-empty">
          {{i18n "streamers.no_streams"}}
        </p>
      {{/if}}

      {{#if this.listenerDialogStream}}
        <div
          class="hb-stream-listeners-backdrop"
          role="presentation"
          {{on "click" this.closeListenerDialog}}
        ></div>

        <section
          class="hb-stream-listeners-dialog"
          role="dialog"
          aria-modal="true"
          aria-label={{i18n "streamers.listeners_title" username=this.listenerDialogUsername}}
        >
          <div class="hb-stream-listeners-dialog-header">
            <div>
              <h2 class="hb-stream-listeners-title">
                {{i18n "streamers.listeners_title" username=this.listenerDialogUsername}}
              </h2>
            </div>

            <button
              type="button"
              class="hb-stream-listeners-close"
              aria-label={{i18n "streamers.listeners_close"}}
              {{on "click" this.closeListenerDialog}}
            >
              ×
            </button>
          </div>

          {{#if this.listenerDialogHasKnownListeners}}
            <div class="hb-stream-listeners-list">
              {{#each this.listenerDialogKnownListeners as |listener|}}
                <a
                  class="hb-stream-listener-row trigger-user-card"
                  href={{hbUserProfileUrl listener.username}}
                  data-user-card={{this.cleanUsername listener.username}}
                  title={{listener.username}}
                  {{on "click" (fn this.handleListenerUserClick listener)}}
                >
                  <span class="hb-stream-listener-avatar">
                    {{avatar
                      listener
                      usernamePath="username"
                      namePath="name"
                      avatarTemplatePath="avatar_template"
                      imageSize="large"
                    }}
                  </span>

                  <span class="hb-stream-listener-main">
                    <span class="hb-stream-listener-name">
                      {{listener.username}}
                    </span>

                    {{#if listener.has_multiple_sessions}}
                      <span class="hb-stream-listener-sessions">
                        {{i18n "streamers.listener_sessions" count=listener.session_count}}
                      </span>
                    {{/if}}
                  </span>
                </a>
              {{/each}}
            </div>
          {{/if}}

          {{#if this.listenerDialogShowEmpty}}
            <p class="hb-stream-listeners-empty">
              {{i18n "streamers.listeners_none_known"}}
            </p>
          {{/if}}

          {{#if this.listenerDialogHasPublicListeners}}
            <p class="hb-stream-listeners-public">
              {{i18n "streamers.listeners_public" count=this.listenerDialogPublicCount}}
            </p>
          {{/if}}
        </section>
      {{/if}}

      {{#if this.state.me}}
        {{#if this.state.me.allowed}}
          <section class="hb-stream-settings-wrapper">
            <div class="hb-stream-settings-card">
              <StreamerSettings
                @streamSettings={{this.state.me}}
                @timezone={{this.state.timezone}}
              />
            </div>
          </section>
        {{/if}}
      {{/if}}

      {{#if this.hasUpdatedDisplay}}
        <p class="hb-streams-updated">
          {{i18n "streamers.last_updated" time=this.lastUpdatedDisplay}}
        </p>
      {{/if}}
    </div>
  </template>
}
