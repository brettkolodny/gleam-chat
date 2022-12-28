import mist
import gleam/erlang/process
import gleam/http.{Get}
import gleam/http/request
import mist/handler.{Upgrade}
import web_socket.{websocket}
import home.{home}

pub fn main() {
  start()
  process.sleep_forever()
}

fn start() {
  assert Ok(_) =
    mist.serve(
      port: 8080,
      handler: handler.with_func(fn(req) {
        case req.method, request.path_segments(req) {
          Get, ["echo", "test"] ->
            websocket()
            |> Upgrade
          _, _ -> home()
        }
      }),
    )
}
// fn handle_request(req: Request(BitString)) {
//   use req <- handler.with_func()

//   case req.method, request.path_segments(req) {
//     Get, ["echo", "test"] -> websocket()
//     _, _ ->
//       // assert Ok(front_end) = file.read_bits("../front-end/index.html")
//       // response.new(200)
//       // |> response.set_body(bit_builder.from_bit_string(front_end))
//       home()
//   }
// }
