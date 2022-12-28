import { Elm } from "./Main.elm";

const $root = document.createElement("div");
document.body.appendChild($root);

const app = Elm.Main.init({
  node: $root,
});

const ws = new WebSocket("ws://localhost:8080/echo/test");

ws.addEventListener("message", (event) => {
  console.log(event.data);
  app.ports.messageReceiver.send(JSON.parse(event.data));
});

app.ports.sendMessage.subscribe((message) => {
  ws.send(JSON.stringify(message));
});
