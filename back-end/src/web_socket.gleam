import mist/websocket.{BinaryMessage, Message, TextMessage, WebsocketHandler}
import gleam/option.{None, Some}
import gleam/dynamic
import gleam/result
import gleam/json
import gleam/bit_string
import gleam/erlang/process.{Subject}
import gleam/otp/actor
import chat_server.{
  ChatEvent, NewConnection, NewMessage, PortMsg, RemoveConnection,
}

fn decode_port_msg(port_msg: String) -> Result(PortMsg, Nil) {
  let decode_port_msg =
    dynamic.decode2(
      PortMsg,
      dynamic.field(named: "tag", of: dynamic.string),
      dynamic.field(named: "value", of: dynamic.string),
    )

  result.map_error(json.decode(port_msg, decode_port_msg), fn(_) { Nil })
}

fn message_to_string(message: Message) -> String {
  case message {
    TextMessage(msg) -> msg
    BinaryMessage(msg) -> result.unwrap(bit_string.to_string(msg), "")
  }
}

pub fn websocket(chat_sub: Subject(ChatEvent)) {
  let on_close = fn(conn) { actor.send(chat_sub, RemoveConnection(conn)) }

  let handler = fn(message, conn) {
    use port_msg <- result.then(decode_port_msg(message_to_string(message)))

    case port_msg.tag {
      "connect" -> actor.send(chat_sub, NewConnection(conn, port_msg.value))

      "message" -> actor.send(chat_sub, NewMessage(conn, port_msg.value))

      _ -> Nil
    }

    Ok(Nil)
  }

  WebsocketHandler(on_close: Some(on_close), on_init: None, handler: handler)
}
