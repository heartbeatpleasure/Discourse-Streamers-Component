import Component from "@glimmer/component";
import { service } from "@ember/service";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import icon from "discourse/helpers/d-icon";
import I18n from "I18n";

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

  get statusText() {
    if (this.streamersPlayer.isLoading) return I18n.t("hb_streamers.loading");
    if (this.streamersPlayer.isPlaying) return I18n.t("hb_streamers.playing");
    if (this.streamersPlayer.isPaused) return I18n.t("hb_streamers.paused");
    if (this.streamersPlayer.errorMessage) return I18n.t("hb_streamers.error");
    return "";
  }

  get toggleLabelKey() {
    return this.streamersPlayer.isPlaying ? "hb_streamers.pause" : "hb_streamers.play";
  }

  get toggleTitle() {
    return I18n.t(this.toggleLabelKey);
  }

  get toggleIcon() {
    return this.streamersPlayer.isPlaying ? "pause" : "play";
  }

  get optionsTitle() {
    return I18n.t("hb_streamers.options");
  }

  get muteLabelKey() {
    return this.streamersPlayer.muted ? "hb_streamers.unmute" : "hb_streamers.mute";
  }

  get muteText() {
    return I18n.t(this.muteLabelKey);
  }

  get volumeText() {
    return I18n.t("hb_streamers.volume");
  }

  get stopText() {
    return I18n.t("hb_streamers.stop");
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

  <template>
    {{#if this.canShow}}
      <li class="hb-streamers-header-item">
        <div class="hb-streamers-header-player" role="region" aria-label="Livestream player">
          <div class="hb-streamers-header-left">
            <span class="hb-streamers-header-name" title={{this.stream.username}}>
              {{this.displayUsername}}
            </span>

            <span class="hb-streamers-header-status">
              {{this.statusText}}
            </span>
          </div>

          <button
            type="button"
            class="hb-streamers-header-iconbtn hb-streamers-header-toggle"
            title={{this.toggleTitle}}
            aria-label={{this.toggleTitle}}
            {{on "click" this.togglePlayPause}}
          >
            {{icon this.toggleIcon}}
          </button>

          <button
            type="button"
            class="hb-streamers-header-iconbtn hb-streamers-header-menubtn"
            title={{this.optionsTitle}}
            aria-label={{this.optionsTitle}}
            {{on "click" this.toggleMenu}}
          >
            <span class="hb-streamers-header-dots" aria-hidden="true">⋯</span>
          </button>

          {{#if this.menuOpen}}
            <div class="hb-streamers-header-backdrop" {{on "click" this.closeMenu}}></div>

            <div class="hb-streamers-header-menu" role="dialog" aria-label="Player options">
              <div class="hb-streamers-header-menu-row">
                <span class="hb-streamers-header-menu-label">
                  {{this.volumeText}}
                </span>

                <input
                  class="hb-streamers-header-volume"
                  type="range"
                  min="0"
                  max="1"
                  step="0.05"
                  value={{this.streamersPlayer.volume}}
                  aria-label={{this.volumeText}}
                  {{on "input" this.setVolume}}
                />
              </div>

              <div class="hb-streamers-header-menu-actions">
                <button
                  type="button"
                  class="hb-streamers-header-actionbtn"
                  {{on "click" this.toggleMute}}
                >
                  {{this.muteText}}
                </button>

                <button
                  type="button"
                  class="hb-streamers-header-actionbtn hb-streamers-header-stopbtn"
                  {{on "click" this.stop}}
                >
                  {{this.stopText}}
                </button>
              </div>
            </div>
          {{/if}}
        </div>
      </li>
    {{/if}}
  </template>
}
