// javascripts/discourse/routes/streams.js
import DiscourseRoute from "discourse/routes/discourse";
import { ajax } from "discourse/lib/ajax";

export default class StreamsRoute extends DiscourseRoute {
  model() {
    // Backend endpoint van de plugin
    return ajax("/streams.json");
  }
}
