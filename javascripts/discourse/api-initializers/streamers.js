// assets/javascripts/discourse/api-initializers/streamers.js
import { apiInitializer } from "discourse/lib/api";
import I18n from "I18n";

function themeSetting(key, fallback = null) {
  if (typeof settings !== "undefined" && Object.prototype.hasOwnProperty.call(settings, key)) {
    return settings[key];
  }

  return fallback;
}

function enabledSetting(value, fallback = true) {
  if (value === null || value === undefined || value === "") {
    return fallback;
  }

  if (value === false || value === "false" || value === 0 || value === "0") {
    return false;
  }

  return true;
}

export default apiInitializer("1.0", (api) => {
  const showNavItem = enabledSetting(themeSetting("show_streamers_link_in_top_navigation", true));

  if (!showNavItem) {
    return;
  }

  api.addNavigationBarItem({
    name: "streams",
    displayName: I18n.t("streamers.title"),
    href: "/streams",
    title: I18n.t("streamers.title"),
  });
});
