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
    gpu: {
      device: null,
      queue: null,
      context: null,
      format: null,
    },
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
  };

  const ensureTriangleResources = () => {
    const { device, format } = state.gpu;
    if (!device || state.gpu.pipeline) {
      return;
    }
    const shaderModule = device.createShaderModule({
      code: `
struct VertexOut {
  @builtin(position) position : vec4<f32>,
  @location(0) color : vec4<f32>,
};

@vertex
fn vs_main(
  @location(0) position : vec2<f32>,
  @location(1) color : vec4<f32>
) -> VertexOut {
  var out : VertexOut;
  out.position = vec4<f32>(position, 0.0, 1.0);
  out.color = color;
  return out;
}

@fragment
fn fs_main(@location(0) color : vec4<f32>) -> @location(0) vec4<f32> {
  return color;
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
            arrayStride: 24,
            attributes: [
              { shaderLocation: 0, offset: 0, format: "float32x2" },
              { shaderLocation: 1, offset: 8, format: "float32x4" },
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
      0.0, 0.6, 1.0, 0.2, 0.2, 1.0,
      -0.6, -0.6, 0.2, 1.0, 0.2, 1.0,
      0.6, -0.6, 0.2, 0.2, 1.0, 1.0,
    ]);
    const vertexBuffer = device.createBuffer({
      size: vertices.byteLength,
      usage: GPUBufferUsage.VERTEX | GPUBufferUsage.COPY_DST,
    });
    device.queue.writeBuffer(vertexBuffer, 0, vertices);
    state.gpu.pipeline = pipeline;
    state.gpu.vertexBuffer = vertexBuffer;
    state.gpu.vertexCount = 3;
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
        ensureTriangleResources();
        const { pipeline, vertexBuffer, vertexCount } = state.gpu;
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
        if (pipeline && vertexBuffer && vertexCount > 0) {
          pass.setPipeline(pipeline);
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
    },
  };
}
