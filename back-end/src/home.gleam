// IMPORTS --------------------------------------------------------------------

import mist/http.{BitBuilderBody}
import gleam/http/response
import gleam/bit_builder
import mist/handler.{Response}
import gleam/erlang/file
import gleam/erlang/os
import html/element.{Html, node, render, script, text}

// HTML -----------------------------------------------------------------------

pub fn render_page(html: Html) -> String {
  let doc_type = "<!DOCTYPE html>"

  let css_path = case os.get_env("ENV") {
    Ok("prod") -> "/app/front-end/dist/index.css"
    _ -> "../front-end/dist/index.css"
  }

  assert Ok(css) = file.read(css_path)

  let html =
    node(
      "html",
      [#("lang", "en")],
      [
        node(
          "head",
          [],
          [
            node("title", [], [text("Gleam Chat")]),
            text(
              "<link rel=\"preconnect\" href=\"https://fonts.googleapis.com\">
<link rel=\"preconnect\" href=\"https://fonts.gstatic.com\" crossorigin>
<link href=\"https://fonts.googleapis.com/css2?family=Outfit:wght@100;200;300;400;500;600;700;800;900&display=swap\" rel=\"stylesheet\">",
            ),
            node("style", [], [text(css)]),
          ],
        ),
        node("body", [], [html]),
      ],
    )
    |> render

  doc_type <> html
}

// HANDLER --------------------------------------------------------------------

pub fn home() {
  let bundle_path = case os.get_env("ENV") {
    Ok("prod") -> "/app/front-end/dist/bundle.js"
    _ -> "../front-end/dist/bundle.js"
  }

  assert Ok(front_end) = file.read(bundle_path)

  let script = script([], [text(front_end)])

  let page = render_page(script)

  response.new(200)
  |> response.set_body(BitBuilderBody(bit_builder.from_string(page)))
  |> Response
}
