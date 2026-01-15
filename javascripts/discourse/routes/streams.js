import DiscourseRoute from "discourse/routes/discourse";
import { ajax } from "discourse/lib/ajax";

export default class StreamsRoute extends DiscourseRoute {
  model() {
    return ajax("/streams.json").catch(() => {
      // Simpele fout-afhandeling voor nu
      return { error: true };
    });
  }
}
