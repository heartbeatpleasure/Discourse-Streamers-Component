import DiscourseRoute from "discourse/routes/discourse";
import { ajax } from "discourse/lib/ajax";
import I18n from "I18n";
import { themePrefix } from "discourse-common/lib/get-owner";

export default class StreamsRoute extends DiscourseRoute {
  titleToken() {
    return I18n.t(themePrefix("streamers.title"));
  }

  model() {
    return ajax("/streams.json");
  }
}
