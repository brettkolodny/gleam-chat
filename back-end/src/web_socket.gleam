import mist/websocket.{TextMessage}
import gleam/io
import gleam/dynamic
import gleam/result
import gleam/json
import gleam/string

type PortMsg {
  PortMsg(tag: String, value: String)
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

pub fn websocket() {
  use message, subject <- websocket.with_handler()
  io.debug(message)

  case message {
    TextMessage(msg) -> {
      use port_msg <- result.then(decode_port_msg(msg))
      case port_msg.tag {
        "whisper" ->
          websocket.send(subject, TextMessage(string.lowercase(port_msg.value)))
        "yell" ->
          websocket.send(subject, TextMessage(string.uppercase(port_msg.value)))
        _ -> Nil
      }
      Ok(Nil)
    }
    _ -> Error(Nil)
  }
}
