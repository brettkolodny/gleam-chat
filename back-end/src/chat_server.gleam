// IMPORTS --------------------------------------------------------------------

import gleam/otp/actor.{Continue, StartError}
import gleam/erlang/process.{Subject}
import gleam/list
import glisten/handler.{HandlerMessage}
import mist/websocket.{TextMessage}
import gleam/io
import gleam/json

// TYPES ----------------------------------------------------------------------

pub type ChatEvent {
  NewMessage(author: Subject(HandlerMessage), content: String)
  NewConnection(subject: Subject(HandlerMessage), name: String)
  RemoveConnection(subject: Subject(HandlerMessage))
  GetMessages(subject: Subject(HandlerMessage))
}

pub type PortMsg {
  PortMsg(tag: String, value: String)
}

type ChatState {
  ChatState(
    connections: List(#(Subject(HandlerMessage), String)),
    messages: List(#(String, String)),
  )
}

// MESSAGES -------------------------------------------------------------------

fn new_chat_state() -> ChatState {
  ChatState(connections: [], messages: [])
}

fn send_msg(conn: Subject(HandlerMessage), author: String, msg: String) -> Nil {
  let payload =
    json.object([
      #("tag", json.string("new-message")),
      #("value", json.array([author, msg], json.string)),
    ])
    |> json.to_string()

  websocket.send(conn, TextMessage(payload))
}

fn send_disconnect(conn: Subject(HandlerMessage), user: String) -> Nil {
  let payload =
    json.object([
      #("tag", json.string("user-disconnect")),
      #("value", json.array([user], json.string)),
    ])
    |> json.to_string()

  websocket.send(conn, TextMessage(payload))
}

fn send_connect(conn: Subject(HandlerMessage), user: String) -> Nil {
  let payload =
    json.object([
      #("tag", json.string("user-connect")),
      #("value", json.array([user], json.string)),
    ])
    |> json.to_string()

  websocket.send(conn, TextMessage(payload))
}

// SERVER ---------------------------------------------------------------------

pub fn start() -> Result(Subject(ChatEvent), StartError) {
  use event, state <- actor.start(new_chat_state())

  let ChatState(connections: conns, messages: msgs) = state

  let new_state = case event {
    NewMessage(conn, msg) ->
      case list.find(conns, fn(c) { c.0 == conn }) {
        Ok(#(_, author)) -> {
          list.map(conns, fn(conn) { send_msg(conn.0, author, msg) })
          let new_messages = list.take([#(author, msg), ..msgs], 100)
          ChatState(connections: conns, messages: new_messages)
        }
        _ -> state
      }

    NewConnection(conn, name) -> {
      let new_conns = [#(conn, name), ..conns]
      list.map(new_conns, fn(conn) { send_connect(conn.0, name) })
      ChatState(connections: new_conns, messages: msgs)
    }

    RemoveConnection(conn) ->
      case list.find(conns, fn(c) { c.0 == conn }) {
        Ok(#(_, author)) -> {
          let new_conns = list.filter(conns, fn(c) { c.0 != conn })
          list.map(new_conns, fn(conn) { send_disconnect(conn.0, author) })
          ChatState(connections: new_conns, messages: msgs)
        }
        _ -> state
      }

    GetMessages(conn) -> state
  }

  Continue(new_state)
}
