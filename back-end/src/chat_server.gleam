import gleam/otp/actor.{Continue, StartError}
import gleam/erlang/process.{Subject}
import gleam/list
import glisten/handler.{HandlerMessage}
import mist/websocket.{TextMessage}
import gleam/io
import gleam/json

pub type ChatEvent {
  NewMessage(author: Subject(HandlerMessage), content: String)
  NewConnection(subject: Subject(HandlerMessage), name: String)
  RemoveConnection(subject: Subject(HandlerMessage))
}

pub type PortMsg {
  PortMsg(tag: String, value: String)
}

type ChatState {
  ChatState(
    connections: List(#(Subject(HandlerMessage), String)),
    messages: List(String),
  )
}

fn new_chat_state() -> ChatState {
  ChatState(connections: [], messages: [])
}

fn send_msg(conn: Subject(HandlerMessage), author: String, msg: String) -> Nil {
  let payload =
    json.object([
      #("tag", json.string("new-message")),
      #("value", json.string(author <> ": " <> msg)),
    ])
    |> json.to_string()

  websocket.send(conn, TextMessage(payload))
}

pub fn start() -> Result(Subject(ChatEvent), StartError) {
  use event, state <- actor.start(new_chat_state())

  let ChatState(connections: conns, messages: msgs) = state

  let new_state = case event {
    NewMessage(conn, msg) ->
      case list.find(conns, fn(c) { c.0 == conn }) {
        Ok(#(_, author)) -> {
          list.map(conns, fn(conn) { send_msg(conn.0, author, msg) })
          ChatState(connections: conns, messages: [msg, ..msgs])
        }
        _ -> state
      }

    NewConnection(conn, name) ->
      ChatState(connections: [#(conn, name), ..conns], messages: msgs)

    RemoveConnection(conn) -> {
      let new_conns = list.filter(conns, fn(c) { c.0 != conn })
      ChatState(connections: new_conns, messages: msgs)
    }
  }

  io.debug(new_state)

  Continue(new_state)
}
