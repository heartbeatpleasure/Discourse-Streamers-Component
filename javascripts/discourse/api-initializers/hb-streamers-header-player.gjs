import { apiInitializer } from "discourse/lib/api";
import StreamersPlayerBar from "../components/streamers-player-bar";

export default apiInitializer((api) => {
  // Veiligheidscheck: alleen uitvoeren als headerIcons API bestaat
  if (!api.headerIcons || !api.headerIcons.add) {
    return;
  }

  const headerPlayer = <template>
    <li class="hb-streamers-header-item">
      <StreamersPlayerBar />
    </li>
  </template>;

  api.headerIcons.add("hb-streamers-player", headerPlayer, { after: "search" });
});
