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
  const wasmOptions = { importedStringConstants: "_" };
  const response = await fetch("./runner.wasm");
  if (!response.ok) {
    throw new Error(`Failed to fetch runner.wasm: ${response.status}`);
  }
  const fallbackResponse = response.clone();
  try {
    const { instance } = await WebAssembly.instantiateStreaming(response, imports, wasmOptions);
    return instance;
  } catch (err) {
    const buffer = await fallbackResponse.arrayBuffer();
    const { instance } = await WebAssembly.instantiate(buffer, imports, wasmOptions);
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

function setupMenu({ onRun, onReload }) {
  const menu = document.getElementById("mgstudio-menu");
  if (!menu) {
    return null;
  }
  const buttons = Array.from(menu.querySelectorAll("button"));
  buttons.forEach((button) => {
    const runTarget = button.dataset.run;
    const action = button.dataset.action;
    if (runTarget) {
      button.addEventListener("click", () => onRun(runTarget, button));
    } else if (action === "reload") {
      button.addEventListener("click", () => onReload(button));
    }
  });
  return {
    setEnabled(enabled) {
      buttons.forEach((button) => {
        button.disabled = !enabled;
      });
    },
  };
}

async function main() {
  const canvas = document.getElementById("mgstudio-canvas");
  const setStatus = createStatusOverlay();
  if (!navigator.gpu) {
    setStatus("WebGPU is not available in this browser.");
    return;
  }
  window.addEventListener("mgstudio-asset-error", (event) => {
    const message = event?.detail ?? "Unknown asset error";
    setStatus(`Asset error: ${message}`);
  });
  const host = await createHost({ canvas });
  await host.init();
  setStatus("WebGPU initialized.");

  const imports = {
    ...host,
    "wasm:js-string": {
      concat: (a, b) => `${a}${b}`,
    },
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
  setStatus("WASM loaded. Choose an example.");

  let running = false;
  const menu = setupMenu({
    onRun: (name, button) => {
      if (running) {
        return;
      }
      const entry = instance.exports[name];
      if (typeof entry !== "function") {
        setStatus(`Missing export: ${name}`);
        return;
      }
      running = true;
      if (menu) {
        menu.setEnabled(false);
      }
      entry();
      if (button) {
        button.disabled = true;
      }
      setStatus(`Running: ${name.replace("run_", "")}`);
    },
    onReload: () => {
      window.location.reload();
    },
  });

  if (!menu) {
    setStatus(`WASM loaded. Exports: ${exportNames.join(", ")}`);
  }
}

main().catch((err) => {
  const setStatus = createStatusOverlay();
  setStatus(`Error: ${err.message ?? err}`);
  console.error(err);
});
