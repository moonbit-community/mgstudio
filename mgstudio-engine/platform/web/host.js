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
    },
    input: {
      pressed: new Set(),
      justPressed: new Set(),
      justReleased: new Set(),
      initialized: false,
    },
    gpu: {
      device: null,
      queue: null,
      context: null,
      format: null,
    },
  };

  const resolveAssetUrl = (path) => {
    if (path == null) {
      return null;
    }
    const text = typeof path === "string" ? path : String(path);
    if (!text || text.length === 0) {
      return null;
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
    state.gpu.spriteTransform = { x: 0, y: 0, rotation: 0 };
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

@group(0) @binding(0) var samp : sampler;
@group(0) @binding(1) var tex : texture_2d<f32>;
@group(0) @binding(2) var<uniform> u_transform : vec4<f32>;

@vertex
fn vs_main(
  @location(0) position : vec2<f32>,
  @location(1) uv : vec2<f32>
) -> VertexOut {
  var out : VertexOut;
  let cosv = u_transform.z;
  let sinv = u_transform.w;
  let rotated = vec2<f32>(
    position.x * cosv - position.y * sinv,
    position.x * sinv + position.y * cosv
  );
  let translated = rotated + u_transform.xy;
  out.position = vec4<f32>(translated, 0.0, 1.0);
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
        targets: [{ format }],
      },
      primitive: {
        topology: "triangle-list",
      },
    });
    const vertices = new Float32Array([
      -0.6, 0.6, 0.0, 0.0,
      -0.6, -0.6, 0.0, 1.0,
      0.6, -0.6, 1.0, 1.0,
      -0.6, 0.6, 0.0, 0.0,
      0.6, -0.6, 1.0, 1.0,
      0.6, 0.6, 1.0, 0.0,
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
        size: 16,
        usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
      });
    }
    if (!state.gpu.textureView) {
      const textureSize = 64;
      const texture = device.createTexture({
        size: [textureSize, textureSize, 1],
        format: "rgba8unorm",
        usage: GPUTextureUsage.TEXTURE_BINDING | GPUTextureUsage.COPY_DST,
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
    const url = resolveAssetUrl(path);
    if (!url) {
      return;
    }
    try {
      const response = await fetch(url);
      if (!response.ok) {
        console.warn(`Failed to load texture: ${url}`);
        return;
      }
      const blob = await response.blob();
      const image = await createImageBitmap(blob);
      ensureTextureResources();
      const texture = device.createTexture({
        size: [image.width, image.height, 1],
        format: "rgba8unorm",
        usage: GPUTextureUsage.TEXTURE_BINDING | GPUTextureUsage.COPY_DST,
      });
      queue.copyExternalImageToTexture(
        { source: image },
        { texture },
        [image.width, image.height],
      );
      state.gpu.textureView = texture.createView();
      ensureBindGroup();
    } catch (err) {
      console.error("Texture load error:", err);
    }
  };

  return {
    mgstudio_host: {
      window_create(width, height, title) {
        const target = ensureCanvas(width, height);
        if (typeof title === "string") {
          document.title = title;
        }
        state.window = { canvas: target, width, height };
        return 1;
      },
      window_poll_events(_window) {
        // Event queue placeholder for Phase 1.
      },
      window_get_width(windowId) {
        windowId;
        return state.window ? state.window.width : 0;
      },
      window_get_height(windowId) {
        windowId;
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
      gpu_set_sprite_transform(x, y, rotation) {
        state.gpu.spriteTransform = {
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
          const tx = state.gpu.spriteTransform.x * scaleX;
          const ty = state.gpu.spriteTransform.y * scaleY;
          const rotation = state.gpu.spriteTransform.rotation;
          const cos = Math.cos(rotation);
          const sin = Math.sin(rotation);
          const uniformData = new Float32Array([tx, ty, cos, sin]);
          queue.writeBuffer(state.gpu.uniformBuffer, 0, uniformData);
        }
        const encoder = device.createCommandEncoder();
        const pass = encoder.beginRenderPass({
          colorAttachments: [
            {
              view: currentTexture.createView(),
              clearValue: { r: 0.1, g: 0.6, b: 0.9, a: 1.0 },
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
