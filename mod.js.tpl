/* @ts-self-types="./mod.d.ts" */

import { join } from "jsr:@std/path@1.1.2";
import { readFileSync } from "node:fs";
import { createRequire } from 'node:module';
import * as process from "node:process";
import { DenoDir, DiskCache, FileFetcher } from "jsr:@deno/cache-dir@0.25.0";

const require = createRequire("/")
require.extensions[".js"] = require.extensions[".node"]

const denoDir = new DenoDir()

// Build-time constants
const VERSION = "%VERSION%";
const REPO_URL = "%REPO_URL%";

const SUPPORTED_PLATFORMS = [
    "darwin-x64",
    "darwin-arm64",
    "linux-x64-gnu",
    "linux-x64-musl",
    "linux-arm64-gnu",
    "linux-arm64-musl",
    "win32-x64-msvc",
    // "win32-arm64-msvc",
]

function getNodeUrl(filename) {
  return `${REPO_URL}/releases/download/v${VERSION}/${filename}`;
}

const isMusl = async () => {
  let musl = false;
  if (process.platform === "linux") {
    musl = isMuslFromFilesystem();
    if (musl === null) {
      musl = isMuslFromReport() ?? false;
    }
  }
  return musl;
};

const isFileMusl = (f) => f.includes("libc.musl-") || f.includes("ld-musl-");

const isMuslFromFilesystem = () => {
  try {
    return readFileSync("/usr/bin/ldd", "utf-8").includes("musl");
  } catch {
    return false;
  }
};

const isMuslFromReport = () => {
  let report = null;
  if (typeof process.report?.getReport === "function") {
    process.report.excludeNetwork = true;
    report = process.report.getReport();
  }
  if (!report) {
    return null;
  }
  if (report.header && report.header.glibcVersionRuntime) {
    return false;
  }
  if (Array.isArray(report.sharedObjects)) {
    if (report.sharedObjects.some(isFileMusl)) {
      return true;
    }
  }
  return false;
};

async function requireNative()  {
  let triple = `${process.platform}-${process.arch}`;
  if (process.platform === "linux") {
    if (await isMusl()) {
      triple += "-musl";
    } else {
      triple += "-gnu";
    }
  } else if (process.platform === "win32") {
    triple += "-msvc";
  }

  const getter = new URL(getNodeUrl(`sodium.${triple}.node`))
  const c = denoDir.createHttpCache()
  const fetcher = new FileFetcher(() => c);
  const out = await fetcher.fetchOnce(getter);
  
  if (!out) {
    throw new Error(`Failed to fetch native binding for ${triple}`);
  }

  const { specifier } = out
  
  const cachedPath = join(
    denoDir.root,
    "remote",
    await DiskCache.getCacheFilename(new URL(specifier))
  );
  
  return require(cachedPath)
}

const nativeBinding = await requireNative();

%IMPORTS%

// Run ensureInit automatically
await ensureInit();
