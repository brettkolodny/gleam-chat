import mist/http.{BitBuilderBody}
import gleam/http/response
import gleam/bit_builder
import mist/handler.{Response}
import gleam/erlang/file

pub fn home() {
  assert Ok(front_end) = file.read_bits("../front-end/dist/index.html")

  response.new(200)
  |> response.set_body(BitBuilderBody(bit_builder.from_bit_string(front_end)))
  |> Response
}
