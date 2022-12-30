// IMPORTS --------------------------------------------------------------------

import gleam/option.{None, Option, Some}
import gleam/list
import gleam/json
import gleam/otp/actor.{Continue, StartError}
import gleam/erlang/process.{Subject}
import glisten/handler.{HandlerMessage}
import mist/websocket.{TextMessage}

// TYPES ----------------------------------------------------------------------

pub type ChatEvent {
  NewMessage(author: Subject(HandlerMessage), content: String)
  NewConnection(subject: Subject(HandlerMessage), name: String, colour: String)
  RemoveConnection(subject: Subject(HandlerMessage))
  GetMessages(subject: Subject(HandlerMessage))
  NewSpectator(subject: Subject(HandlerMessage))
}

pub type PortMsg {
  PortMsg(tag: String, value: String)
  Connect(name: String, colour: String)
}

type User {
  User(
    conn: Subject(HandlerMessage),
    name: Option(String),
    colour: Option(String),
  )
}

type ChatState {
  ChatState(connections: List(User), messages: List(#(String, String, String)))
}

// MESSAGES -------------------------------------------------------------------

fn new_chat_state() -> ChatState {
  ChatState(connections: [], messages: [])
}

fn send_msg(
  to conn: Subject(HandlerMessage),
  user user: User,
  msg msg: String,
) -> Nil {
  let payload =
    json.object([
      #("tag", json.string("new-message")),
      #("content", json.string(msg)),
      #(
        "author",
        user.name
        |> option.unwrap("")
        |> json.string(),
      ),
      #(
        "colour",
        user.colour
        |> option.unwrap("")
        |> json.string(),
      ),
    ])
    |> json.to_string()

  websocket.send(conn, TextMessage(payload))
}

fn send_disconnect(conn: Subject(HandlerMessage), user: String) -> Nil {
  let payload =
    json.object([
      #("tag", json.string("user-disconnect")),
      #("name", json.string(user)),
    ])
    |> json.to_string()

  websocket.send(conn, TextMessage(payload))
}

fn send_connect(conn: Subject(HandlerMessage), user: String) -> Nil {
  let payload =
    json.object([
      #("tag", json.string("user-connect")),
      #("name", json.string(user)),
    ])
    |> json.to_string()

  websocket.send(conn, TextMessage(payload))
}

fn get_messages(
  conn: Subject(HandlerMessage),
  messages: List(#(String, String, String)),
) -> Nil {
  let message_jsons =
    messages
    |> list.map(fn(msg) {
      let #(username, content, colour) = msg

      json.object([
        #("content", json.string(content)),
        #("author", json.string(username)),
        #("colour", json.string(colour)),
      ])
      |> json.to_string()
    })

  let payload =
    json.object([
      #("tag", json.string("get-messages")),
      #("messages", json.array(from: message_jsons, of: json.string)),
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
      case list.find(conns, fn(c) { c.conn == conn }) {
        Ok(user) -> {
          list.map(
            conns,
            fn(conn) { send_msg(to: conn.conn, user: user, msg: msg) },
          )
          let username = option.unwrap(user.name, "")
          let colour = option.unwrap(user.colour, "charcoal")
          let new_messages = list.take([#(username, msg, colour), ..msgs], 100)
          ChatState(connections: conns, messages: new_messages)
        }
        _ -> state
      }

    NewConnection(conn, name, colour) -> {
      let conns = list.filter(conns, fn(c) { c.conn != conn })
      let new_user = User(conn: conn, name: Some(name), colour: Some(colour))
      let new_conns = [new_user, ..conns]
      list.map(new_conns, fn(conn) { send_connect(conn.conn, name) })
      ChatState(connections: new_conns, messages: msgs)
    }

    RemoveConnection(conn) ->
      case list.find(conns, fn(c) { c.conn == conn }) {
        Ok(User(conn, name, _colour)) -> {
          let new_conns = list.filter(conns, fn(c) { c.conn != conn })
          let username = option.unwrap(name, "")
          list.map(new_conns, fn(conn) { send_disconnect(conn.conn, username) })
          ChatState(connections: new_conns, messages: msgs)
        }
        _ -> state
      }

    NewSpectator(conn) -> {
      let spectator = User(conn: conn, name: None, colour: None)
      let new_conns = [spectator, ..conns]
      get_messages(conn, msgs)
      ChatState(connections: new_conns, messages: msgs)
    }

    GetMessages(_) -> state
  }

  Continue(new_state)
}
