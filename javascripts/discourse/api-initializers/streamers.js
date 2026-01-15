// javascripts/discourse/api-initializers/streamers.js
import { apiInitializer } from "discourse/lib/api";

/**
 * Theme initializer for the Streamers component.
 *
 * Belangrijk:
 * - Geen api.addRoute() hier; routes worden vanuit de plugin
 *   via een route-map toegevoegd.
 * - Dit bestand blijft staan zodat we later makkelijk header-links,
 *   auto-refresh, etc. kunnen toevoegen.
 */
export default apiInitializer("1.0", (api) => {
  // Voor nu doen we hier nog niets.
  // Als we straks extra UI-logica willen (bijv. knop in de header),
  // kunnen we dat hier met de theme-API doen.
});
