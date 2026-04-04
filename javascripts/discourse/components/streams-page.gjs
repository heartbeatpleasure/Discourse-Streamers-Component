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

export default class StreamsPageComponent extends Component {
  @tracked state = normalizeModel(this.args.initialModel);

  constructor() {
    super(...arguments);

    this._handlePageUpdate = this._handlePageUpdate.bind(this);

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

      {{#if this.state.updated_at}}
        <p class="hb-streams-updated">
          {{i18n
            "streamers.last_updated"
            time=(if this.state.formatted_updated_at this.state.formatted_updated_at this.state.updated_at)
          }}
        </p>
      {{/if}}
    </div>
  </template>
}
