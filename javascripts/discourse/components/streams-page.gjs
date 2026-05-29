import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
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
      this.listenerDialogStream = refreshedStream || null;
    }

    this._syncLastUpdatedDisplay(this.state, { ensureFallback: true });
  }

  @action
  openListenerDialog(stream) {
    this.listenerDialogStream = stream;
  }

  @action
  closeListenerDialog() {
    this.listenerDialogStream = null;
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
                    class="hb-stream-user-link"
                    href={{hbUserProfileUrl stream.username}}
                    title={{stream.username}}
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
                        class="hb-stream-user-link"
                        href={{hbUserProfileUrl stream.username}}
                        title={{stream.username}}
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
                  <button
                    type="button"
                    class="hb-stream-listeners-trigger"
                    {{on "click" (fn this.openListenerDialog stream)}}
                  >
                    {{i18n "streamers.listeners" count=stream.listeners}}
                  </button>

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
              <div class="hb-stream-listeners-eyebrow">
                {{i18n "streamers.listeners_known"}}
              </div>
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

          {{#if this.listenerDialogDetailsVisible}}
            {{#if this.listenerDialogKnownListeners.length}}
              <div class="hb-stream-listeners-list">
                {{#each this.listenerDialogKnownListeners as |listener|}}
                  <a
                    class="hb-stream-listener-row"
                    href={{hbUserProfileUrl listener.username}}
                    title={{listener.username}}
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
            {{else}}
              <p class="hb-stream-listeners-empty">
                {{i18n "streamers.listeners_none_known"}}
              </p>
            {{/if}}

            {{#if this.listenerDialogPublicCount}}
              <p class="hb-stream-listeners-public">
                {{i18n "streamers.listeners_public" count=this.listenerDialogPublicCount}}
              </p>
            {{/if}}
          {{else}}
            <p class="hb-stream-listeners-empty">
              {{i18n "streamers.listeners_hidden"}}
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
