import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("0.8.41", (api) => {
  // Registreer een nieuwe pagina-route /streams
  // De Ember-route staat in javascripts/discourse/routes/streams.js
  api.addRoute("streams", "/streams");

  // Voeg een item toe aan de discovery navigation bar (Latest / Categories / etc.)
  api.addNavigationBarItem({
    name: "streams",
    displayName: "streamers.title",
    title: "streamers.title",
    href: "/streams",
  });
});
