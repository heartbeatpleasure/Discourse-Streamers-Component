import { apiInitializer } from "discourse/lib/api";
import I18n from "I18n";

export default apiInitializer("1.8.0", (api) => {
  function ensureListenButtons() {
    const cards = document.querySelectorAll(".hb-streams-page .hb-stream-card");
    if (!cards?.length) return;

    cards.forEach((card) => {
      const userRow = card.querySelector(".hb-stream-user-row");
      if (!userRow) return;

      if (card.querySelector(".hb-stream-listen-btn")) return;

      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = "btn btn-primary hb-stream-listen-btn";
      btn.disabled = true; // later koppelen we dit aan een interne player / echte listen URL
      btn.textContent = I18n.t("hb_streamers.listen");
      btn.title = I18n.t("hb_streamers.listen_coming_soon");

      userRow.appendChild(btn);
    });
  }

  api.onPageChange((url) => {
    if (!url?.startsWith("/streams")) return;

    // wait for DOM render
    requestAnimationFrame(() => {
      ensureListenButtons();
    });
  });
});
