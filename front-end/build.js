const esbuild = require("esbuild");
const ElmPlugin = require("esbuild-plugin-elm");
const fs = require("fs");

const watch = process.argv.includes("--watch");
const isProd = process.env.NODE_ENV === "production";

const writeHtml = () => {
  const bundle = fs.readFileSync("./dist/bundle.js");

  const htmlFile = `<!DOCTYPE html>
  <html lang="en">
    <head>
      <meta charset="UTF-8" />
      <meta http-equiv="X-UA-Compatible" content="IE=edge" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <title>Document</title>
    </head>
    <body></body>
    <script>
        ${bundle.toString()}
    </script>
  </html>`;

  fs.writeFileSync("./dist/index.html", htmlFile);
};

esbuild
  .build({
    entryPoints: ["src/index.js"],
    bundle: true,
    outfile: "dist/bundle.js",
    plugins: [
      ElmPlugin({
        debug: true,
        optimize: isProd,
        clearOnWatch: watch,
        verbose: true,
      }), // options are documented below
    ],
  })
  .catch((e) => (console.error(e), process.exit(1)))
  .then(() => writeHtml());
