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

export async function createHost({ canvas }) {
  const state = {
    window: null,
    shouldClose: false,
    assets: {
      pendingTexturePath: null,
      lastError: null,
    },
    input: {
      pressed: new Set(),
      justPressed: new Set(),
      justReleased: new Set(),
      mouseButtons: new Set(),
      mouseJustPressed: new Set(),
      mouseJustReleased: new Set(),
      mouseX: 0,
      mouseY: 0,
      hasCursor: false,
      pointerBound: false,
      initialized: false,
    },
    gpu: {
      device: null,
      queue: null,
      context: null,
      format: null,
    },
  };

  const coerceAssetPath = (path) => {
    if (path == null) {
      throw new Error("Asset path is required");
    }
    let current = path;
    for (let i = 0; i < 4; i += 1) {
      if (typeof current === "string") {
        return current;
      }
      if (typeof current === "number" || typeof current === "bigint" || typeof current === "boolean") {
        return `${current}`;
      }
      if (typeof current === "object") {
        if (typeof current.value === "string") {
          return current.value;
        }
        if (typeof current.string === "string") {
          return current.string;
        }
        if (typeof current.toString === "function") {
          try {
            current = current.toString();
            continue;
          } catch {
            // Ignore and try other fallbacks.
          }
        }
        if (typeof current.valueOf === "function") {
          try {
            current = current.valueOf();
            continue;
          } catch {
            // Ignore and try other fallbacks.
          }
        }
      }
      break;
    }
    throw new Error(`Unsupported asset path type: ${typeof path}`);
  };

  const resolveAssetUrl = (path) => {
    const text = coerceAssetPath(path);
    if (!text || text.length === 0) {
      throw new Error("Asset path is empty");
    }
    if (/^(https?:)?\/\//.test(text) || text.startsWith("data:")) {
      return text;
    }
    const normalized = text.replace(/^\/+/, "");
    return `./assets/${normalized}`;
  };

  const ensureCanvas = (width, height) => {
    const target = canvas ?? document.createElement("canvas");
    target.width = width;
    target.height = height;
    if (!canvas) {
      document.body.appendChild(target);
    }
    return target;
  };

  const getCanvasPixelSize = (target) => {
    const dpr = window.devicePixelRatio || 1;
    const width = Math.max(1, Math.floor(target.clientWidth * dpr));
    const height = Math.max(1, Math.floor(target.clientHeight * dpr));
    return { width, height };
  };

  const updateWindowSize = () => {
    if (!state.window) {
      return;
    }
    const target = state.window.canvas;
    const { width, height } = getCanvasPixelSize(target);
    if (width === state.window.width && height === state.window.height) {
      return;
    }
    state.window.width = width;
    state.window.height = height;
    target.width = width;
    target.height = height;
    if (state.gpu.context && state.gpu.device) {
      state.gpu.context.configure({
        device: state.gpu.device,
        format: state.gpu.format,
        alphaMode: "premultiplied",
        usage: GPUTextureUsage.RENDER_ATTACHMENT,
        size: [width, height],
      });
    }
  };

  const initInput = () => {
    if (state.input.initialized) {
      return;
    }
    state.input.initialized = true;
    const { pressed, justPressed, justReleased } = state.input;
    window.addEventListener("keydown", (event) => {
      if (event.repeat) {
        return;
      }
      const code = event.code;
      if (!pressed.has(code)) {
        pressed.add(code);
        justPressed.add(code);
      }
    });
    window.addEventListener("keyup", (event) => {
      const code = event.code;
      if (pressed.delete(code)) {
        justReleased.add(code);
      }
    });
    window.addEventListener("blur", () => {
      pressed.clear();
      justPressed.clear();
      justReleased.clear();
    });
  };

  const mouseButtonName = (button) => {
    if (button === 0) {
      return "Left";
    }
    if (button === 1) {
      return "Middle";
    }
    if (button === 2) {
      return "Right";
    }
    return null;
  };

  const bindPointerEvents = (target) => {
    if (!target || state.input.pointerBound) {
      return;
    }
    state.input.pointerBound = true;
    const updateMousePosition = (event) => {
      const rect = target.getBoundingClientRect();
      const scaleX = rect.width > 0 ? target.width / rect.width : 1;
      const scaleY = rect.height > 0 ? target.height / rect.height : 1;
      state.input.mouseX = (event.clientX - rect.left) * scaleX;
      state.input.mouseY = (event.clientY - rect.top) * scaleY;
      state.input.hasCursor = true;
    };
    target.addEventListener("pointermove", (event) => {
      updateMousePosition(event);
    });
    target.addEventListener("pointerdown", (event) => {
      const name = mouseButtonName(event.button);
      if (name) {
        if (!state.input.mouseButtons.has(name)) {
          state.input.mouseButtons.add(name);
          state.input.mouseJustPressed.add(name);
        }
      }
      updateMousePosition(event);
    });
    target.addEventListener("pointerup", (event) => {
      const name = mouseButtonName(event.button);
      if (name && state.input.mouseButtons.delete(name)) {
        state.input.mouseJustReleased.add(name);
      }
      updateMousePosition(event);
    });
    target.addEventListener("pointerleave", () => {
      state.input.hasCursor = false;
    });
    target.addEventListener("contextmenu", (event) => {
      event.preventDefault();
    });
  };

  const initWebGpu = async (target) => {
    if (!navigator.gpu) {
      throw new Error("WebGPU not supported in this browser");
    }
    const adapter = await navigator.gpu.requestAdapter();
    if (!adapter) {
      throw new Error("WebGPU adapter unavailable");
    }
    const device = await adapter.requestDevice();
    const context = target.getContext("webgpu");
    const format = navigator.gpu.getPreferredCanvasFormat();
    state.gpu.device = device;
    state.gpu.queue = device.queue;
    state.gpu.context = context;
    state.gpu.format = format;
    state.gpu.pipeline = null;
    state.gpu.vertexBuffer = null;
    state.gpu.vertexCount = 0;
    state.gpu.bindGroup = null;
    state.gpu.sampler = null;
    state.gpu.textureView = null;
    state.gpu.uniformBuffer = null;
    state.gpu.spriteTransform = { x: 0, y: 0, rotation: 0, scaleX: 1, scaleY: 1 };
    state.gpu.cameraTransform = { x: 0, y: 0, rotation: 0 };
    state.gpu.drawEnabled = false;
    if (state.assets.pendingTexturePath) {
      const pendingPath = state.assets.pendingTexturePath;
      state.assets.pendingTexturePath = null;
      loadTextureFromPath(pendingPath);
    }
  };

  const ensureBindGroup = () => {
    const { pipeline, sampler, textureView, uniformBuffer } = state.gpu;
    if (!pipeline || !sampler || !textureView || !uniformBuffer) {
      return;
    }
    state.gpu.bindGroup = state.gpu.device.createBindGroup({
      layout: pipeline.getBindGroupLayout(0),
      entries: [
        { binding: 0, resource: sampler },
        { binding: 1, resource: textureView },
        { binding: 2, resource: { buffer: uniformBuffer } },
      ],
    });
  };

  const ensureTextureResources = () => {
    const { device, format } = state.gpu;
    if (!device || state.gpu.pipeline) {
      return;
    }
    const shaderModule = device.createShaderModule({
      code: `
struct VertexOut {
  @builtin(position) position : vec4<f32>,
  @location(0) uv : vec2<f32>,
};

struct TransformData {
  model : vec4<f32>,
  view : vec4<f32>,
  scale : vec4<f32>,
};

@group(0) @binding(0) var samp : sampler;
@group(0) @binding(1) var tex : texture_2d<f32>;
@group(0) @binding(2) var<uniform> u_transform : TransformData;

@vertex
fn vs_main(
  @location(0) position : vec2<f32>,
  @location(1) uv : vec2<f32>
) -> VertexOut {
  var out : VertexOut;
  let cosv = u_transform.model.z;
  let sinv = u_transform.model.w;
  let scaled = vec2<f32>(
    position.x * u_transform.scale.z,
    position.y * u_transform.scale.w
  );
  let rotated = vec2<f32>(
    scaled.x * cosv - scaled.y * sinv,
    scaled.x * sinv + scaled.y * cosv
  );
  let translated = rotated + u_transform.model.xy;
  let cam_cos = u_transform.view.z;
  let cam_sin = u_transform.view.w;
  let rel = translated - u_transform.view.xy;
  let view_pos = vec2<f32>(
    rel.x * cam_cos - rel.y * cam_sin,
    rel.x * cam_sin + rel.y * cam_cos
  );
  let ndc = vec2<f32>(
    view_pos.x * u_transform.scale.x,
    view_pos.y * u_transform.scale.y
  );
  out.position = vec4<f32>(ndc, 0.0, 1.0);
  out.uv = uv;
  return out;
}

@fragment
fn fs_main(@location(0) uv : vec2<f32>) -> @location(0) vec4<f32> {
  return textureSample(tex, samp, uv);
}
`,
    });
    const pipeline = device.createRenderPipeline({
      layout: "auto",
      vertex: {
        module: shaderModule,
        entryPoint: "vs_main",
        buffers: [
          {
            arrayStride: 16,
            attributes: [
              { shaderLocation: 0, offset: 0, format: "float32x2" },
              { shaderLocation: 1, offset: 8, format: "float32x2" },
            ],
          },
        ],
      },
      fragment: {
        module: shaderModule,
        entryPoint: "fs_main",
        targets: [
          {
            format,
            blend: {
              color: {
                srcFactor: "src-alpha",
                dstFactor: "one-minus-src-alpha",
                operation: "add",
              },
              alpha: {
                srcFactor: "src-alpha",
                dstFactor: "one-minus-src-alpha",
                operation: "add",
              },
            },
          },
        ],
      },
      primitive: {
        topology: "triangle-list",
      },
    });
    const halfSize = 64;
    const vertices = new Float32Array([
      -halfSize, halfSize, 0.0, 0.0,
      -halfSize, -halfSize, 0.0, 1.0,
      halfSize, -halfSize, 1.0, 1.0,
      -halfSize, halfSize, 0.0, 0.0,
      halfSize, -halfSize, 1.0, 1.0,
      halfSize, halfSize, 1.0, 0.0,
    ]);
    const vertexBuffer = device.createBuffer({
      size: vertices.byteLength,
      usage: GPUBufferUsage.VERTEX | GPUBufferUsage.COPY_DST,
    });
    device.queue.writeBuffer(vertexBuffer, 0, vertices);
    if (!state.gpu.sampler) {
      state.gpu.sampler = device.createSampler({
        magFilter: "nearest",
        minFilter: "nearest",
      });
    }
    if (!state.gpu.uniformBuffer) {
      state.gpu.uniformBuffer = device.createBuffer({
        size: 48,
        usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
      });
    }
    if (!state.gpu.textureView) {
      const textureSize = 64;
      const texture = device.createTexture({
        size: [textureSize, textureSize, 1],
        format: "rgba8unorm",
        usage: GPUTextureUsage.TEXTURE_BINDING | GPUTextureUsage.COPY_DST | GPUTextureUsage.RENDER_ATTACHMENT,
      });
      const pixelData = new Uint8Array(textureSize * textureSize * 4);
      for (let y = 0; y < textureSize; y += 1) {
        for (let x = 0; x < textureSize; x += 1) {
          const offset = (y * textureSize + x) * 4;
          const checker = ((x >> 3) ^ (y >> 3)) & 1;
          const base = checker ? 220 : 40;
          pixelData[offset] = base;
          pixelData[offset + 1] = 120;
          pixelData[offset + 2] = 255 - base;
          pixelData[offset + 3] = 255;
        }
      }
      device.queue.writeTexture(
        { texture },
        pixelData,
        { bytesPerRow: textureSize * 4 },
        [textureSize, textureSize, 1],
      );
      state.gpu.textureView = texture.createView();
    }
    state.gpu.pipeline = pipeline;
    state.gpu.vertexBuffer = vertexBuffer;
    state.gpu.vertexCount = 6;
    ensureBindGroup();
  };

  const loadTextureFromPath = async (path) => {
    const { device, queue } = state.gpu;
    if (!device || !queue) {
      state.assets.pendingTexturePath = path;
      return;
    }
    try {
      const url = resolveAssetUrl(path);
      const response = await fetch(url);
      if (!response.ok) {
        throw new Error(`Failed to load texture: ${url} (${response.status})`);
      }
      const blob = await response.blob();
      const image = await createImageBitmap(blob, {
        premultiplyAlpha: "none",
        colorSpaceConversion: "none",
      });
      ensureTextureResources();
      const texture = device.createTexture({
        size: [image.width, image.height, 1],
        format: "rgba8unorm",
        usage: GPUTextureUsage.TEXTURE_BINDING | GPUTextureUsage.COPY_DST | GPUTextureUsage.RENDER_ATTACHMENT,
      });
      queue.copyExternalImageToTexture(
        { source: image },
        { texture },
        [image.width, image.height],
      );
      state.gpu.textureView = texture.createView();
      ensureBindGroup();
    } catch (err) {
      const detail = {
        type: typeof path,
        tag: Object.prototype.toString.call(path),
        ctor: path?.constructor?.name,
        keys: path && typeof path === "object" ? Object.keys(path) : [],
        props: path && typeof path === "object" ? Object.getOwnPropertyNames(path) : [],
      };
      const message = err?.message ?? String(err);
      state.assets.lastError = message;
      console.error("Texture load error:", message, detail);
      window.dispatchEvent(new CustomEvent("mgstudio-asset-error", {
        detail: `${message} (${detail.type}, ${detail.tag})`,
      }));
      throw err;
    }
  };

  return {
    mgstudio_host: {
      window_create(width, height, title) {
        const target = ensureCanvas(width, height);
        if (typeof title === "string") {
          document.title = title;
        }
        const size = getCanvasPixelSize(target);
        state.window = { canvas: target, width: size.width, height: size.height };
        target.width = size.width;
        target.height = size.height;
        bindPointerEvents(target);
        return 1;
      },
      window_poll_events(_window) {
        // Event queue placeholder for Phase 1.
      },
      window_get_width(windowId) {
        windowId;
        updateWindowSize();
        return state.window ? state.window.width : 0;
      },
      window_get_height(windowId) {
        windowId;
        updateWindowSize();
        return state.window ? state.window.height : 0;
      },
      window_should_close(windowId) {
        windowId;
        return state.shouldClose;
      },
      window_request_close(windowId) {
        windowId;
        state.shouldClose = true;
      },
      window_run_loop(step) {
        const tick = () => {
          if (state.shouldClose) {
            return;
          }
          step();
          requestAnimationFrame(tick);
        };
        requestAnimationFrame(tick);
      },
      time_now() {
        return performance.now();
      },
      input_is_key_down(code) {
        const text = typeof code === "string" ? code : String(code);
        return state.input.pressed.has(text);
      },
      input_is_key_just_pressed(code) {
        const text = typeof code === "string" ? code : String(code);
        return state.input.justPressed.has(text);
      },
      input_is_key_just_released(code) {
        const text = typeof code === "string" ? code : String(code);
        return state.input.justReleased.has(text);
      },
      input_finish_frame() {
        state.input.justPressed.clear();
        state.input.justReleased.clear();
        state.input.mouseJustPressed.clear();
        state.input.mouseJustReleased.clear();
      },
      input_is_mouse_button_down(name) {
        const text = typeof name === "string" ? name : String(name);
        return state.input.mouseButtons.has(text);
      },
      input_is_mouse_button_just_pressed(name) {
        const text = typeof name === "string" ? name : String(name);
        return state.input.mouseJustPressed.has(text);
      },
      input_is_mouse_button_just_released(name) {
        const text = typeof name === "string" ? name : String(name);
        return state.input.mouseJustReleased.has(text);
      },
      input_mouse_x() {
        return state.input.mouseX;
      },
      input_mouse_y() {
        return state.input.mouseY;
      },
      input_has_cursor() {
        return state.input.hasCursor;
      },
      debug_string(value) {
        const detail = {
          type: typeof value,
          tag: Object.prototype.toString.call(value),
          ctor: value?.constructor?.name,
          keys: value && typeof value === "object" ? Object.keys(value) : [],
          props: value && typeof value === "object" ? Object.getOwnPropertyNames(value) : [],
        };
        console.log("debug_string value:", value, detail);
        if (value && typeof value === "object") {
          try {
            console.log("debug_string toString:", value.toString());
          } catch (err) {
            console.log("debug_string toString error:", err);
          }
          try {
            console.log("debug_string valueOf:", value.valueOf());
          } catch (err) {
            console.log("debug_string valueOf error:", err);
          }
        }
      },
      gpu_request_device() {
        if (!state.gpu.device) {
          throw new Error("WebGPU device not initialized. Call createHost() first.");
        }
        return 1;
      },
      gpu_get_queue(_device) {
        return 1;
      },
      gpu_create_surface(windowId) {
        windowId;
        if (!state.window) {
          throw new Error("Unknown window id");
        }
        return 1;
      },
      gpu_configure_surface(_device, _surface, width, height) {
        const { context, device, format } = state.gpu;
        if (!context || !device) {
          return;
        }
        if (state.window) {
          state.window.width = width;
          state.window.height = height;
          state.window.canvas.width = width;
          state.window.canvas.height = height;
        }
        context.configure({
          device,
          format,
          alphaMode: "premultiplied",
          usage: GPUTextureUsage.RENDER_ATTACHMENT,
          size: [width, height],
        });
      },
      gpu_set_draw_enabled(enabled) {
        state.gpu.drawEnabled = !!enabled;
      },
      gpu_set_sprite_transform(x, y, rotation, scaleX, scaleY) {
        state.gpu.spriteTransform = {
          x: Number(x) || 0,
          y: Number(y) || 0,
          rotation: Number(rotation) || 0,
          scaleX: Number(scaleX) || 1,
          scaleY: Number(scaleY) || 1,
        };
      },
      gpu_set_camera_transform(x, y, rotation) {
        state.gpu.cameraTransform = {
          x: Number(x) || 0,
          y: Number(y) || 0,
          rotation: Number(rotation) || 0,
        };
      },
      asset_load_texture(path) {
        loadTextureFromPath(path);
      },
      gpu_begin_frame(_surface) {
        const { context } = state.gpu;
        if (!context) {
          return 0;
        }
        state.gpu.currentTexture = context.getCurrentTexture();
        return 1;
      },
      gpu_end_frame(_frame) {
        const { device, queue, currentTexture } = state.gpu;
        if (!device || !queue || !currentTexture) {
          return;
        }
        ensureTextureResources();
        const { pipeline, vertexBuffer, vertexCount, bindGroup } = state.gpu;
        if (state.gpu.uniformBuffer && state.window) {
          const { width, height } = state.window;
          const scaleX = width > 0 ? 2 / width : 0;
          const scaleY = height > 0 ? 2 / height : 0;
          const tx = state.gpu.spriteTransform.x;
          const ty = state.gpu.spriteTransform.y;
          const rotation = state.gpu.spriteTransform.rotation;
          const cos = Math.cos(rotation);
          const sin = Math.sin(rotation);
          const camRotation = state.gpu.cameraTransform.rotation;
          const camCos = Math.cos(-camRotation);
          const camSin = Math.sin(-camRotation);
          const camX = state.gpu.cameraTransform.x;
          const camY = state.gpu.cameraTransform.y;
          const uniformData = new Float32Array([
            tx, ty, cos, sin,
            camX, camY, camCos, camSin,
            scaleX, scaleY, state.gpu.spriteTransform.scaleX, state.gpu.spriteTransform.scaleY,
          ]);
          queue.writeBuffer(state.gpu.uniformBuffer, 0, uniformData);
        }
        const encoder = device.createCommandEncoder();
        const pass = encoder.beginRenderPass({
          colorAttachments: [
            {
              view: currentTexture.createView(),
              clearValue: { r: 0.2, g: 0.2, b: 0.2, a: 1.0 },
              loadOp: "clear",
              storeOp: "store",
            },
          ],
        });
        if (state.gpu.drawEnabled && pipeline && vertexBuffer && vertexCount > 0) {
          pass.setPipeline(pipeline);
          if (bindGroup) {
            pass.setBindGroup(0, bindGroup);
          }
          pass.setVertexBuffer(0, vertexBuffer);
          pass.draw(vertexCount);
        }
        pass.end();
        queue.submit([encoder.finish()]);
      },
    },
    init: async () => {
      const target = canvas ?? document.querySelector("canvas") ?? ensureCanvas(800, 600);
      await initWebGpu(target);
      initInput();
    },
  };
}
