/* @ts-self-types="./mod.d.ts" */

import { readFileSync } from "node:fs";
import * as process from "node:process";

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

function getNodeUrl(filename: string) {
  return `${REPO_URL}/releases/download/v${VERSION}/${filename}`;
}

const isMusl = async () => {
  let musl = false;
  if (process.platform === "linux") {
    musl = isMuslFromFilesystem();
    if (musl === null) {
      musl = isMuslFromReport() ?? false;
    }
    if (musl === null) {
      musl = await isMuslFromChildProcess();
    }
  }
  return musl;
};

const isFileMusl = (f: string) => f.includes("libc.musl-") || f.includes("ld-musl-");

const isMuslFromFilesystem = () => {
  try {
    return readFileSync("/usr/bin/ldd", "utf-8").includes("musl");
  } catch {
    return null;
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

const isMuslFromChildProcess = async () => {
  try {
    return (await import("node:child_process")).exec("ldd --version", {
      encoding: "utf8",
    }).includes("musl");
  } catch (e) {
    // If we reach this case, we don't know if the system is musl or not, so is better to just fallback to false
    return false;
  }
};

async function requireNative() {
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

    return await import(getNodeUrl(`sodium.${triple}.node`));
}

const nativeBinding = await requireNative();

%IMPORTS%

// Run ensureInit automatically
await ensureInit();
