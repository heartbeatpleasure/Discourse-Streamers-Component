import { apiInitializer } from "discourse/lib/api";
import StreamersPlayerBar from "../components/streamers-player-bar";

export default apiInitializer("1.0", (api) => {
  if (!api.headerIcons || !api.headerIcons.add) {
    return;
  }

  api.headerIcons.add(
    "hb-streamers-player",
    <template>
      <StreamersPlayerBar />
    </template>,
    { after: "search" }
  );
});
