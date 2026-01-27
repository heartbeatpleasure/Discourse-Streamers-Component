// assets/javascripts/discourse/api-initializers/streamers.js
import { apiInitializer } from "discourse/lib/api";
import I18n from "I18n";

export default apiInitializer("1.0", (api) => {
  api.addNavigationBarItem({
    name: "streams",
    displayName: I18n.t("streamers.title"),
    href: "/streams",
    title: I18n.t("streamers.title"),
  });
});
