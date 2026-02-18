// assets/javascripts/discourse/components/streamers-chat-button.js
import Component from "@glimmer/component";
import { getURL } from "discourse-common/lib/get-url";

export default class StreamersChatButton extends Component {
  get chatTopicId() {
    const raw = this.args.chatTopicId;
    const id = parseInt(raw, 10);
    return Number.isFinite(id) ? id : 0;
  }

  get isEnabled() {
    return this.chatTopicId > 0;
  }

  get href() {
    if (!this.isEnabled) return null;
    // /t/<id> redirects to the canonical slugged URL
    return getURL(`/t/${this.chatTopicId}`);
  }
}
