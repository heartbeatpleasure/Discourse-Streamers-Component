import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.0", (api) => {
  if (!api.headerIcons || !api.headerIcons.add) {
    return;
  }

  api.headerIcons.add(
    "hb-streamers-player",
    <template>
      <li class="hb-streamers-header-item">
        {{streamers-player-bar}}
      </li>
    </template>,
    { after: "search" }
  );
});
