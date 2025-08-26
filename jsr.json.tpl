{
  "name": "@necessary/sodium",
  "version": "%VERSION%",
  "description": "Deno bindings for libsodium with focus on GitHub secret encryption",
  "exports": "./mod.ts",
  "publish": {
    "include": [
      "mod.ts",
      "mod.d.ts",
      "*.node",
      "README.md"
    ]
  },
  "keywords": [
    "libsodium",
    "crypto",
    "github",
    "secrets",
    "encryption",
    "deno",
    "native"
  ],
  "license": "MIT"
}