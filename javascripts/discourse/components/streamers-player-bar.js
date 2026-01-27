// assets/javascripts/discourse/components/streamers-player-bar.js
import Component from "@glimmer/component";
import { inject as service } from "@ember/service";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";

export default class StreamersPlayerBar extends Component {
  @service("streamers-player") streamersPlayer;

  @tracked menuOpen = false;

  get stream() {
    return this.streamersPlayer.currentStream;
  }

  get canShow() {
    return this.streamersPlayer.isVisible;
  }

  get toggleLabelKey() {
    return this.streamersPlayer.isPlaying ? "hb_streamers.pause" : "hb_streamers.play";
  }

  get toggleIcon() {
    return this.streamersPlayer.isPlaying ? "pause" : "play";
  }

  get muteLabelKey() {
    return this.streamersPlayer.muted ? "hb_streamers.unmute" : "hb_streamers.mute";
  }

  @action
  togglePlayPause() {
    this.menuOpen = false;

    const stream = this.stream;
    if (!stream) return;

    if (this.streamersPlayer.isPlaying) {
      this.streamersPlayer.pause();
    } else if (this.streamersPlayer.isPaused) {
      this.streamersPlayer.resume();
    } else {
      this.streamersPlayer.playOrToggle(stream);
    }
  }

  @action
  toggleMenu() {
    this.menuOpen = !this.menuOpen;
  }

  @action
  stop() {
    this.menuOpen = false;
    this.streamersPlayer.stop();
  }

  @action
  toggleMute() {
    this.streamersPlayer.toggleMute();
  }

  @action
  setVolume(e) {
    this.streamersPlayer.setVolume(e?.target?.value);
  }
}
