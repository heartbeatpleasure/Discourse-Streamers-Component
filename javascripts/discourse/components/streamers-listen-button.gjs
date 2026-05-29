import Component from "@glimmer/component";
import { service } from "@ember/service";
import { action } from "@ember/object";
import DButton from "discourse/components/d-button";

export default class StreamersListenButton extends Component {
  @service("streamers-player") streamersPlayer;

  get stream() {
    return this.args.stream;
  }

  get disabled() {
    return !!this.stream?.listener_blocked || !this.stream?.listen_url;
  }

  get isCurrent() {
    return (
      this.streamersPlayer.currentMount &&
      this.stream?.mount &&
      this.streamersPlayer.currentMount === this.stream.mount
    );
  }

  get labelKey() {
    if (this.stream?.listener_blocked) return "hb_streamers.listen_unavailable";
    if (this.disabled) return "hb_streamers.listen";
    if (!this.isCurrent) return "hb_streamers.listen";
    if (this.streamersPlayer.isLoading) return "hb_streamers.loading";
    if (this.streamersPlayer.isPlaying) return "hb_streamers.pause";
    if (this.streamersPlayer.isPaused) return "hb_streamers.resume";

    return "hb_streamers.listen";
  }

  @action
  onClick() {
    if (this.disabled) return;
    this.streamersPlayer.playOrToggle(this.stream);
  }

  <template>
    <DButton
      @class="btn-primary hb-stream-listen-btn"
      @action={{this.onClick}}
      @disabled={{this.disabled}}
      @label={{this.labelKey}}
    />
  </template>
}
