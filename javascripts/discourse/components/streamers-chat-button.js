// assets/javascripts/discourse/components/streamers-chat-button.js
import Component from "@glimmer/component";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { openURL } from "discourse/lib/url";
import getURL from "discourse-common/lib/get-url";

export default class StreamersChatButton extends Component {
  get chatChannelId() {
    // NOTE: despite the setting name (historical), in your setup this value represents
    // a Discourse Chat *channel* id.
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

    // Canonical chat URL is: /chat/c/<slug>/<id>
    // We only store the id, so we try to fetch the slug. If that fails, we fall back
    // to a dash slug; the route should still resolve by id in most Discourse versions.
    let slug = "-";

    try {
      // Endpoint varies by Discourse/Chat version; try a couple of common ones.
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

    openURL(getURL(`/chat/c/${slug}/${channelId}`));
  }
}
