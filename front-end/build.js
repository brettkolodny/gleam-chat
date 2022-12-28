const esbuild = require("esbuild");
const ElmPlugin = require("esbuild-plugin-elm");
const fs = require("fs");

const watch = process.argv.includes("--watch");
const isProd = process.env.NODE_ENV === "production";

esbuild
  .build({
    entryPoints: ["src/index.js"],
    bundle: true,
    outfile: "dist/bundle.js",
    watch: {
      onRebuild(error, result) {
        if (error) console.error("watch build failed:", error);
        else console.log("watch build succeeded:", result);
      },
    },
    plugins: [
      ElmPlugin({
        debug: true,
        optimize: isProd,
        clearOnWatch: watch,
        verbose: true,
      }), // options are documented below
    ],
  })
  .catch((e) => (console.error(e), process.exit(1)));
