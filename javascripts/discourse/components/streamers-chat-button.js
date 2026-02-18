// assets/javascripts/discourse/components/streamers-chat-button.js
import Component from "@glimmer/component";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { openURL } from "discourse/lib/url";
import { getURL } from "discourse-common/lib/get-url";

export default class StreamersChatButton extends Component {
  get chatTopicId() {
    // NOTE: despite the setting name, in your setup this value represents a Discourse Chat *channel* id.
    const raw = this.args.chatTopicId;
    const id = parseInt(raw, 10);
    return Number.isFinite(id) ? id : 0;
  }

  get isEnabled() {
    return this.chatTopicId > 0;
  }

  @action
  async openChat() {
    if (!this.isEnabled) return;

    const channelId = this.chatTopicId;

    // Prefer canonical chat URL with slug: /chat/c/<slug>/<id>
    // We only have the id, so we try to fetch the slug from the chat API.
    // If that fails, fall back to /chat/c/-/<id> (Discourse usually redirects/corrects).
    let slug = "-";

    try {
      // Endpoint varies slightly by Discourse version; try both.
      let data = await ajax(getURL(`/chat/api/channels/${channelId}.json`));
      if (!data) {
        data = await ajax(getURL(`/chat/api/channels/${channelId}`));
      }

      slug =
        data?.channel?.slug ||
        data?.channel_slug ||
        data?.slug ||
        data?.chat_channel?.slug ||
        "-";
    } catch (e) {
      // ignore
    }

    openURL(getURL(`/chat/c/${slug}/${channelId}`));
  }
}
