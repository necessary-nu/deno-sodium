#!/usr/bin/env -S deno run -A

import { parse as parseToml } from "https://deno.land/std@0.224.0/toml/mod.ts";

console.log("🔧 Post-processing generated files...");

// Read and parse Cargo.toml
const cargoToml = await Deno.readTextFile("Cargo.toml");
const cargo = parseToml(cargoToml) as { package: { version: string; repository: string } };
const version = cargo.package.version;
const repo = cargo.package.repository;

console.log(`Using version: ${version}, repo: ${repo}`);

// Read the NAPI-generated index.js and extract the last 7 lines (imports/exports)
const indexJs = await Deno.readTextFile("dist/index.js");
const lines = indexJs.split("\n");
const imports = lines.slice(-8, -1).join("\n"); // Last 7 non-empty lines

// Read the template
const template = await Deno.readTextFile("mod.ts.tpl");

// Replace placeholders
const processed = template
  .replace(/%VERSION%/g, version)
  .replace(/%REPO_URL%/g, repo)
  .replace(/%IMPORTS%/g, imports);

// Write the processed result
await Deno.writeTextFile("dist/mod.ts", processed);

console.log("🎨 Formatting generated code...");
const fmt = new Deno.Command("deno", {
  args: ["fmt", "dist"],
});
await fmt.output();

await Deno.remove("dist/index.js");
await Deno.rename("dist/index.d.ts", "dist/mod.d.ts");

console.log("✅ Post-processing complete!");