// Copyright 2025 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import { createHost } from "./host.js";

function makePrintChar() {
  let buffer = "";
  return (code) => {
    const char = String.fromCharCode(code);
    if (char === "\n") {
      console.log(buffer);
      buffer = "";
    } else {
      buffer += char;
    }
  };
}

async function loadWasm(imports) {
  const response = await fetch("./runner.wasm");
  if (!response.ok) {
    throw new Error(`Failed to fetch runner.wasm: ${response.status}`);
  }
  try {
    const { instance } = await WebAssembly.instantiateStreaming(response, imports);
    return instance;
  } catch (err) {
    const buffer = await response.arrayBuffer();
    const { instance } = await WebAssembly.instantiate(buffer, imports);
    return instance;
  }
}

function createStatusOverlay() {
  const overlay = document.createElement("div");
  overlay.style.position = "fixed";
  overlay.style.left = "12px";
  overlay.style.top = "12px";
  overlay.style.padding = "8px 12px";
  overlay.style.background = "rgba(0, 0, 0, 0.7)";
  overlay.style.color = "#ffffff";
  overlay.style.fontFamily = "monospace";
  overlay.style.fontSize = "12px";
  overlay.style.zIndex = "9999";
  overlay.textContent = "Loading...";
  document.body.appendChild(overlay);
  return (text) => {
    overlay.textContent = text;
  };
}

async function main() {
  const canvas = document.getElementById("mgstudio-canvas");
  const setStatus = createStatusOverlay();
  if (!navigator.gpu) {
    setStatus("WebGPU is not available in this browser.");
    return;
  }
  const host = await createHost({ canvas });
  await host.init();
  setStatus("WebGPU initialized.");

  const imports = {
    ...host,
    spectest: {
      print_char: makePrintChar(),
    },
    "moonbit:ffi": {
      make_closure: (funcref, closure) => funcref.bind(null, closure),
    },
  };

  setStatus("Loading WASM...");
  const instance = await loadWasm(imports);
  const exportNames = Object.keys(instance.exports || {});
  console.log("WASM exports:", exportNames);
  setStatus(`WASM loaded. Exports: ${exportNames.join(", ")}`);
  if (instance.exports.run_sprite) {
    instance.exports.run_sprite();
    setStatus("Running: sprite");
  } else if (instance.exports.main) {
    instance.exports.main();
    setStatus("Running: main");
  } else if (instance.exports._start) {
    instance.exports._start();
    setStatus("Running: _start");
  } else {
    throw new Error("No entrypoint exported from WASM module.");
  }
}

main().catch((err) => {
  const setStatus = createStatusOverlay();
  setStatus(`Error: ${err.message ?? err}`);
  console.error(err);
});
