import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { registerDestructor } from "@ember/destroyable";
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

function fallbackFormattedNow(timezone) {
  try {
    const parts = new Intl.DateTimeFormat("en-GB", {
      timeZone: timezone || undefined,
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
      hour12: false,
    }).formatToParts(new Date());

    const byType = Object.fromEntries(parts.map((p) => [p.type, p.value]));
    if (byType.day && byType.month && byType.year && byType.hour && byType.minute) {
      return `${byType.day}-${byType.month}-${byType.year} at ${byType.hour}:${byType.minute}`;
    }
  } catch {
    // fall through
  }

  const now = new Date();
  const dd = String(now.getDate()).padStart(2, "0");
  const mm = String(now.getMonth() + 1).padStart(2, "0");
  const yyyy = String(now.getFullYear());
  const hh = String(now.getHours()).padStart(2, "0");
  const min = String(now.getMinutes()).padStart(2, "0");
  return `${dd}-${mm}-${yyyy} at ${hh}:${min}`;
}

export default class StreamsPageComponent extends Component {
  @tracked state = normalizeModel(this.args.initialModel);
  @tracked lastUpdatedDisplay = null;

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

  _syncLastUpdatedDisplay(nextState, { ensureFallback = false } = {}) {
    this.lastUpdatedDisplay =
      nextState?.formatted_updated_at ||
      nextState?.updated_at ||
      this.lastUpdatedDisplay ||
      (ensureFallback ? fallbackFormattedNow(nextState?.timezone || this.state?.timezone) : null);
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

    this._syncLastUpdatedDisplay(this.state, { ensureFallback: true });
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
                  <span class="hb-stream-meta-item">
                    {{i18n "streamers.listeners" count=stream.listeners}}
                  </span>

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
