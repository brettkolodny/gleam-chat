import mist
import gleam/erlang/process.{Subject}
import gleam/http.{Get}
import gleam/http/request
import mist/handler.{Upgrade}
import web_socket.{websocket}
import home.{home}
import chat_server.{ChatEvent}

pub type ActorMsg {
  NewMessage(content: String)
}

pub fn main() {
  assert Ok(chat_sub) = chat_server.start()

  start(chat_sub)
  process.sleep_forever()
}

fn start(chat_sub: Subject(ChatEvent)) {
  assert Ok(_) =
    mist.serve(
      port: 8080,
      handler: handler.with_func(fn(req) {
        case req.method, request.path_segments(req) {
          Get, ["echo", "test"] ->
            websocket(chat_sub)
            |> Upgrade
          _, _ -> home()
        }
      }),
    )
}
