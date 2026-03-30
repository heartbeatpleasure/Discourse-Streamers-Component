import Component from "@glimmer/component";
import { action } from "@ember/object";
import DButton from "discourse/components/d-button";
import { ajax } from "discourse/lib/ajax";
import DiscourseURL from "discourse/lib/url";
import getURL from "discourse-common/lib/get-url";

export default class StreamersChatButton extends Component {
  get chatChannelId() {
    const raw = this.args.chatTopicId;
    const id = parseInt(raw, 10);
    return Number.isFinite(id) ? id : 0;
  }

  get isEnabled() {
    return this.chatChannelId > 0;
  }

  @action
  async openChat() {
    if (!this.isEnabled) {
      return;
    }

    const channelId = this.chatChannelId;
    let slug = "-";

    try {
      let data;

      try {
        data = await ajax(getURL(`/chat/api/channels/${channelId}.json`));
      } catch {
        // ignore and try next
      }

      if (!data) {
        try {
          data = await ajax(getURL(`/chat/api/channels/${channelId}`));
        } catch {
          // ignore
        }
      }

      slug =
        data?.channel?.slug ||
        data?.chat_channel?.slug ||
        data?.channel_slug ||
        data?.slug ||
        "-";
    } catch {
      // ignore
    }

    const path = `/chat/c/${slug}/${channelId}`;

    if (DiscourseURL?.routeTo) {
      DiscourseURL.routeTo(path);
    } else {
      window.location.href = getURL(path);
    }
  }

  <template>
    {{#if this.isEnabled}}
      <DButton
        @class="btn-default hb-stream-chat-btn"
        @action={{this.openChat}}
        @icon="comments"
        @label="streamers.chat"
      />
    {{/if}}
  </template>
}
