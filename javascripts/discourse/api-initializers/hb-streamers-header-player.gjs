// javascripts/discourse/api-initializers/hb-streamers-header-player.gjs
import { apiInitializer } from "discourse/lib/api";
import StreamersPlayerBar from "discourse/components/streamers-player-bar";

export default apiInitializer("1.0", (api) => {
  // In de nieuwe (Glimmer) header is dit de juiste manier om iets in de header-icons te plaatsen.
  if (!api?.headerIcons?.add) {
    // Als deze API niet bestaat (heel oude Discourse), doen we niets
    // zodat we geen errors veroorzaken.
    return;
  }

  api.headerIcons.add(
    "hb-streamers-player",
    <template>
      <li class="hb-streamers-header-item">
        <StreamersPlayerBar />
      </li>
    </template>,
    { after: "search" } // positie naast de bestaande icons
  );
});
