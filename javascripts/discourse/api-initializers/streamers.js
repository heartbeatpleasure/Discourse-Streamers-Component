// assets/javascripts/discourse/api-initializers/streamers.js
import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.0", (api) => {
  // Voeg een "Streams" item toe aan de hoofdnavigatie
  api.addNavigationBarItem({
    name: "streams",
    displayName: "Streams",
    href: "/streams",
    title: "Live audio streams",
  });
});
