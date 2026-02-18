// assets/javascripts/discourse/components/streamers-chat-button.js
import Component from "@glimmer/component";
import { action } from "@ember/object";
import { openURL } from "discourse/lib/url";

export default class StreamersChatButton extends Component {
  get chatTopicId() {
    const raw = this.args.chatTopicId;
    const id = parseInt(raw, 10);
    return Number.isFinite(id) ? id : 0;
  }

  get isEnabled() {
    return this.chatTopicId > 0;
  }

  @action
  openChat() {
    if (!this.isEnabled) return;
    // /t/<id> redirects to canonical slugged URL
    openURL(`/t/${this.chatTopicId}`);
  }
}
