// assets/javascripts/discourse/components/streamers-listen-button.js
import Component from "@glimmer/component";
import { inject as service } from "@ember/service";
import { action } from "@ember/object";

export default class StreamersListenButton extends Component {
  @service("streamers-player") streamersPlayer;

  get stream() {
    return this.args.stream;
  }

  get disabled() {
    return !this.stream?.listen_url;
  }

  get isCurrent() {
    return (
      this.streamersPlayer.currentMount &&
      this.stream?.mount &&
      this.streamersPlayer.currentMount === this.stream.mount
    );
  }

  get labelKey() {
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
}
