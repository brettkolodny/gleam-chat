// IMPORTS --------------------------------------------------------------------

import { Elm } from "./Main.elm";

// ELM ------------------------------------------------------------------------

const $root = document.createElement("div");
document.body.appendChild($root);

const app = Elm.Main.init({
  node: $root,
});

// WEB SOCKET -----------------------------------------------------------------

const url = new URL(window.location.href);
const ws = new WebSocket(
  `${url.protocol === "https:" ? "wss" : "ws"}://${url.host}/ws`
);

ws.addEventListener("message", (event) => {
  app.ports.messageReceiver.send(JSON.parse(event.data));
});

app.ports.sendMessage.subscribe((message) => {
  ws.send(JSON.stringify(message));
});
