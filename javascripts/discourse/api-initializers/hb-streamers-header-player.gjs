import { apiInitializer } from "discourse/lib/api";
import StreamersPlayerBar from "../components/streamers-player-bar";

export default apiInitializer("1.0", (api) => {
  if (!api.headerIcons || !api.headerIcons.add) {
    return;
  }

  api.headerIcons.add(
    "hb-streamers-player",
    <template>
      <li class="hb-streamers-header-item">
        <StreamersPlayerBar />
      </li>
    </template>,
    { after: "search" }
  );
});
