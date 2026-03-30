import avatar from "discourse/helpers/avatar";
import { i18n } from "discourse-i18n";
import StreamerSettings from "../components/streamer-settings";
import StreamersChatButton from "../components/streamers-chat-button";
import StreamersListenButton from "../components/streamers-listen-button";
import hbUserProfileUrl from "../helpers/hb-user-profile-url";

export default <template>
  <div class="hb-streams-page">
    <h1 class="hb-streams-title">
      {{i18n "streamers.title"}}
    </h1>

    {{#if @model.live_streams.length}}
      <div class="hb-streams-list">
        {{#each @model.live_streams as |stream|}}
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
                    @chatTopicId={{if stream.chat_topic_id stream.chat_topic_id @model.chat_topic_id}}
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

    {{#if @model.me}}
      {{#if @model.me.allowed}}
        <section class="hb-stream-settings-wrapper">
          <div class="hb-stream-settings-card">
            <StreamerSettings @streamSettings={{@model.me}} @timezone={{@model.timezone}} />
          </div>
        </section>
      {{/if}}
    {{/if}}

    {{#if @model.updated_at}}
      <p class="hb-streams-updated">
        {{i18n
          "streamers.last_updated"
          time=(if @model.formatted_updated_at @model.formatted_updated_at @model.updated_at)
        }}
      </p>
    {{/if}}
  </div>
</template>;
