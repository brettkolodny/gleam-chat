import mist/http.{BitBuilderBody}
import gleam/http/response
import gleam/bit_builder
import mist/handler.{Response}
import gleam/erlang/file
import html/element.{Html, h1, node, render, script, text}

pub fn render_page(html: Html) -> String {
  let doc_type = "<!DOCTYPE html>"

  let html =
    node(
      "html",
      [#("lang", "en")],
      [
        node(
          "head",
          [],
          [
            node("title", [], [text("Brett Kolodny")]),
            text(
              "<link rel=\"preconnect\" href=\"https://fonts.googleapis.com\">
<link rel=\"preconnect\" href=\"https://fonts.gstatic.com\" crossorigin>
<link href=\"https://fonts.googleapis.com/css2?family=Outfit:wght@100;200;300;400;500;600;700;800;900&display=swap\" rel=\"stylesheet\">",
            ),
            node(
              "style",
              [],
              [text("html { font-family: 'Outfit', sans-serif; }")],
            ),
          ],
        ),
        node("body", [], [h1([], [text("Welcome to the PEG Stack!")]), html]),
      ],
    )
    |> render

  doc_type <> html
}

pub fn home() {
  assert Ok(front_end) = file.read("../front-end/dist/bundle.js")

  let script = script([], [text(front_end)])

  let page = render_page(script)

  response.new(200)
  |> response.set_body(BitBuilderBody(bit_builder.from_string(page)))
  |> Response
}
