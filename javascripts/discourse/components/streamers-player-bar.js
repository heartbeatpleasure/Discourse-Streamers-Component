// assets/javascripts/discourse/components/streamers-player-bar.js
import Component from "@glimmer/component";
import { inject as service } from "@ember/service";
import { action } from "@ember/object";

export default class StreamersPlayerBar extends Component {
  @service("streamers-player") streamersPlayer;

  get stream() {
    return this.streamersPlayer.currentStream;
  }

  get canShow() {
    return this.streamersPlayer.isVisible;
  }

  @action
  togglePlayPause() {
    if (!this.stream) return;

    if (this.streamersPlayer.isPlaying) {
      this.streamersPlayer.pause();
    } else if (this.streamersPlayer.isPaused) {
      this.streamersPlayer.resume();
    } else {
      this.streamersPlayer.playOrToggle(this.stream);
    }
  }

  @action
  stop() {
    this.streamersPlayer.stop();
  }

  @action
  openExternal() {
    const url = this.stream?.listen_url;
    if (!url) return;
    window.open(url, "_blank", "noopener,noreferrer");
  }

  @action
  setVolume(e) {
    this.streamersPlayer.setVolume(e?.target?.value);
  }

  @action
  toggleMute() {
    this.streamersPlayer.toggleMute();
  }
}
