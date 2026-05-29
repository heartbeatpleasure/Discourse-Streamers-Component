// assets/javascripts/discourse/services/streamers-player.js
import Service from "@ember/service";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";

const STREAMS_URL = "/streams.json";

function noCacheUrl(path) {
  const separator = path.includes("?") ? "&" : "?";
  return `${path}${separator}_hb_streamers_player_ts=${Date.now()}`;
}

function sameMount(a, b) {
  return !!a && !!b && a === b;
}

export default class StreamersPlayerService extends Service {
  @tracked currentStream = null; // { mount, listen_url, username, name, avatar_template, title }
  @tracked status = "stopped"; // stopped | loading | playing | paused | error
  @tracked muted = false;
  @tracked volume = 1;
  @tracked errorMessage = null;

  _audio = null;

  constructor() {
    super(...arguments);

    // Maak 1 audio element en hang die aan de DOM (werkt betrouwbaarder op Safari/iOS)
    const audio = document.createElement("audio");
    audio.preload = "none";
    audio.autoplay = false;
    audio.muted = false;
    audio.volume = 1;
    audio.setAttribute("playsinline", "");
    audio.style.display = "none";

    audio.addEventListener("playing", () => {
      this.status = "playing";
      this.errorMessage = null;
    });

    audio.addEventListener("pause", () => {
      if (!this.currentStream) return;
      if (this.status !== "stopped") this.status = "paused";
    });

    audio.addEventListener("error", () => {
      if (!this.currentStream) return;
      this.status = "error";
      this.errorMessage = "Playback error.";
    });

    document.body.appendChild(audio);
    this._audio = audio;
  }

  get isVisible() {
    return !!this.currentStream;
  }

  get isPlaying() {
    return this.status === "playing";
  }

  get isPaused() {
    return this.status === "paused";
  }

  get isLoading() {
    return this.status === "loading";
  }

  get currentMount() {
    return this.currentStream?.mount || null;
  }

  setVolume(v) {
    const value = Number(v);
    if (Number.isNaN(value)) return;
    const clamped = Math.max(0, Math.min(1, value));

    this.volume = clamped;
    if (this._audio) this._audio.volume = clamped;
  }

  toggleMute() {
    this.muted = !this.muted;
    if (this._audio) this._audio.muted = this.muted;
  }

  stop() {
    if (this._audio) {
      try {
        this._audio.pause();
      } catch {}
      this._audio.src = "";
    }

    this.currentStream = null;
    this.status = "stopped";
    this.errorMessage = null;
  }

  pause() {
    if (!this._audio) return;
    try {
      this._audio.pause();
      this.status = "paused";
    } catch {}
  }

  async resume(preferredStream = null) {
    if (!this._audio || !this.currentStream?.mount) return;

    this.status = "loading";
    this.errorMessage = null;

    try {
      const freshStream = await this._freshStreamForResume(preferredStream);
      if (!freshStream?.listen_url) {
        throw new Error("Stream is no longer available.");
      }

      this._applyStream(freshStream, { replaceSource: true });
      await this._audio.play();
    } catch (e) {
      this.status = "error";
      this.errorMessage = e?.message || "Could not start playback.";
    }
  }

  async _freshStreamForResume(preferredStream = null) {
    const mount = this.currentStream?.mount;
    if (!mount) return null;

    if (
      sameMount(preferredStream?.mount, mount) &&
      preferredStream?.listen_url &&
      preferredStream.listen_url !== this.currentStream?.listen_url &&
      !preferredStream?.listener_blocked
    ) {
      return preferredStream;
    }

    const data = await ajax(noCacheUrl(STREAMS_URL));
    const streams = Array.isArray(data?.live_streams) ? data.live_streams : [];
    const freshStream = streams.find((stream) => sameMount(stream?.mount, mount));

    if (!freshStream || freshStream.listener_blocked || !freshStream.listen_url) {
      return null;
    }

    return freshStream;
  }

  _applyStream(stream, { replaceSource = false } = {}) {
    this.currentStream = {
      user_id: stream.user_id,
      username: stream.username,
      name: stream.name,
      avatar_template: stream.avatar_template,
      mount: stream.mount,
      listen_url: stream.listen_url,
      title: stream.title,
    };

    if (replaceSource && this._audio && stream.listen_url && this._audio.src !== stream.listen_url) {
      this._audio.src = stream.listen_url;
    }
  }

  async playOrToggle(stream) {
    if (!stream?.listen_url) return;

    const same =
      this.currentStream?.mount &&
      stream.mount &&
      this.currentStream.mount === stream.mount;

    if (same) {
      if (this.isPlaying) return this.pause();
      if (this.isPaused) return this.resume(stream);
      // loading/error -> opnieuw proberen
    }

    this._applyStream(stream);

    if (!this._audio) return;

    this._audio.muted = this.muted;
    this._audio.volume = this.volume;

    // reset voor nette switch
    try {
      this._audio.pause();
    } catch {}

    this._audio.src = stream.listen_url;
    this.status = "loading";
    this.errorMessage = null;

    try {
      await this._audio.play();
      // status wordt ook gezet door 'playing' event
    } catch (e) {
      this.status = "error";
      this.errorMessage = e?.message || "Could not start playback.";
    }
  }
}
