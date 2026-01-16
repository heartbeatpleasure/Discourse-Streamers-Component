// assets/javascripts/discourse/routes/streams.js
import DiscourseRoute from "discourse/routes/discourse";
import { ajax } from "discourse/lib/ajax";
import { getOwner } from "@ember/application";

export default class StreamsRoute extends DiscourseRoute {
  async model() {
    // Data ophalen van de backend plugin
    const data = await ajax("/streams.json");

    // Veiligheid: als er geen live_streams zijn, gewoon teruggeven
    if (!data || !data.live_streams || !data.live_streams.length) {
      return data;
    }

    // Via Ember de site-settings service pakken
    let siteSettings;
    try {
      const owner = getOwner(this);
      siteSettings = owner && owner.lookup("service:site-settings");
    } catch (e) {
      // Als dit om wat voor reden dan ook faalt, geven we de data zonder listen_url terug
      return data;
    }

    const statusUrl = siteSettings && siteSettings.streamers_icecast_status_url;
    if (!statusUrl) {
      // Geen status-URL ingesteld → ook dan gewoon data teruggeven
      return data;
    }

    // Van bv. https://stream.heartbeatpleasure.com/radio/status-json.xsl
    // naar https://stream.heartbeatpleasure.com/radio/
    let baseUrl;
    try {
      baseUrl = statusUrl.replace(/status-json\.xsl.*$/i, "");
      if (!baseUrl.endsWith("/")) {
        baseUrl += "/";
      }
    } catch (e) {
      return data;
    }

    // Voor elke stream een listen_url toevoegen
    data.live_streams = data.live_streams.map((stream) => {
      const mount = (stream.mount || "").replace(/^\//, ""); // "/test" → "test"
      let listen_url = null;

      if (mount && baseUrl) {
        listen_url = `${baseUrl}${mount}`;
      }

      // nieuwe property listen_url toevoegen, rest ongemoeid laten
      return { ...stream, listen_url };
    });

    return data;
  }
}
