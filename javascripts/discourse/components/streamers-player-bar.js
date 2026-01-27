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

  get toggleLabel() {
    if (this.streamersPlayer.isPlaying) return "hb_streamers.pause";
    if (this.streamersPlayer.isPaused) return "hb_streamers.play";
    if (this.streamersPlayer.isLoading) return "hb_streamers.loading";
    if (this.streamersPlayer.errorMessage) return "hb_streamers.play";
    return "hb_streamers.play";
  }

  get toggleIcon() {
    // 1 knop die togglet: playing => pause icon, anders play icon
    return this.streamersPlayer.isPlaying ? "pause" : "play";
  }

  @action
  togglePlayPause() {
    const stream = this.stream;
    if (!stream) return;

    if (this.streamersPlayer.isPlaying) {
      this.streamersPlayer.pause();
    } else if (this.streamersPlayer.isPaused) {
      this.streamersPlayer.resume();
    } else {
      // stopped/loading/error -> probeer af te spelen
      this.streamersPlayer.playOrToggle(stream);
    }
  }
}
