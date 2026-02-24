// assets/javascripts/discourse/helpers/hb-user-profile-url.js
import { helper } from "@ember/component/helper";
import getURL from "discourse-common/lib/get-url";

export default helper(function hbUserProfileUrl([username]) {
  if (!username) {
    return getURL("/");
  }

  const u = String(username).trim();
  if (!u) {
    return getURL("/");
  }

  // Discourse user profile canonical path: /u/:username
  return getURL(`/u/${encodeURIComponent(u)}`);
});
