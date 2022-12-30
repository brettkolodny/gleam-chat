// IMPORTS --------------------------------------------------------------------

import mist/websocket.{BinaryMessage, Message, TextMessage, WebsocketHandler}
import gleam/option.{Some}
import gleam/dynamic
import gleam/result
import gleam/json
import gleam/bit_string
import gleam/erlang/process.{Subject}
import gleam/otp/actor
import chat_server.{
  ChatEvent, Connect, NewConnection, NewMessage, NewSpectator, PortMsg,
  RemoveConnection,
}

// UTILITY --------------------------------------------------------------------

fn decode_port_msg(port_msg: String) -> Result(PortMsg, Nil) {
  let decode_port_msg =
    dynamic.decode2(
      PortMsg,
      dynamic.field(named: "tag", of: dynamic.string),
      dynamic.field(named: "value", of: dynamic.string),
    )

  result.map_error(json.decode(port_msg, decode_port_msg), fn(_) { Nil })
}

fn decode_connect(port_msg: String) -> Result(PortMsg, Nil) {
  let decode_port_msg =
    dynamic.decode2(
      Connect,
      dynamic.field(named: "name", of: dynamic.string),
      dynamic.field(named: "colour", of: dynamic.string),
    )

  result.map_error(json.decode(port_msg, decode_port_msg), fn(_) { Nil })
}

fn message_to_string(message: Message) -> String {
  case message {
    TextMessage(msg) -> msg
    BinaryMessage(msg) -> result.unwrap(bit_string.to_string(msg), "")
  }
}

// HANDLER --------------------------------------------------------------------

pub fn websocket(chat_sub: Subject(ChatEvent)) {
  let on_close = fn(conn) { actor.send(chat_sub, RemoveConnection(conn)) }

  let on_init = fn(conn) { actor.send(chat_sub, NewSpectator(conn)) }

  let handler = fn(message, conn) {
    let port_msg =
      message
      |> message_to_string()
      |> decode_port_msg()
      |> result.or(decode_connect(message_to_string(message)))

    use port_msg <- result.then(port_msg)

    case port_msg {
      Connect(name, colour) ->
        actor.send(chat_sub, NewConnection(conn, name, colour))

      PortMsg(_, value) -> actor.send(chat_sub, NewMessage(conn, value))

      _ -> Nil
    }

    Ok(Nil)
  }

  WebsocketHandler(
    on_close: Some(on_close),
    on_init: Some(on_init),
    handler: handler,
  )
}
