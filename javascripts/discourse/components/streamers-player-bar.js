// assets/javascripts/discourse/components/streamers-player-bar.js
import Component from "@glimmer/component";
import { inject as service } from "@ember/service";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";

const MAX_USERNAME_LEN = 24;

export default class StreamersPlayerBar extends Component {
  @service("streamers-player") streamersPlayer;

  @tracked menuOpen = false;

  get stream() {
    return this.streamersPlayer.currentStream;
  }

  get canShow() {
    return this.streamersPlayer.isVisible;
  }

  get displayUsername() {
    const u = (this.stream?.username || "").toString().trim();
    if (!u) return "";

    if (u.length <= MAX_USERNAME_LEN) return u;
    return `${u.slice(0, MAX_USERNAME_LEN - 1)}…`;
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
  closeMenu() {
    this.menuOpen = false;
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
