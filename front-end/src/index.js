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
  const data = JSON.parse(event.data);

  if (data.tag === "new-message") {
    app.ports.messageReceiver.send(data);
  } else if (data.tag === "user-connect") {
    app.ports.connectionReceiver.send(data);
  } else if (data.tag === "user-disconnect") {
    app.ports.disconnectionReceiver.send(data);
  } else if (data.tag === "get-messages") {
    app.ports.pastMessagesReceiver.send(data.messages);
  } else {
    console.error(`Unexpected websocket message: ${event.data}`);
  }
});

app.ports.sendMessage.subscribe((message) => {
  ws.send(JSON.stringify(message));
});

app.ports.connectUser.subscribe((message) => {
  ws.send(JSON.stringify(message));
});
