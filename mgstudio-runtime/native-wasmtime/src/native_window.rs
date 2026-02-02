use std::collections::HashSet;
use std::sync::Arc;
use std::time::Duration;

use winit::application::ApplicationHandler;
use winit::dpi::{LogicalPosition, LogicalSize, PhysicalPosition, PhysicalSize};
use winit::event::{ElementState, MouseButton, WindowEvent};
use winit::event_loop::{ActiveEventLoop, EventLoop};
use winit::keyboard::{KeyCode, PhysicalKey};
use winit::platform::pump_events::EventLoopExtPumpEvents;
use winit::window::{Window, WindowAttributes, WindowId};

struct PumpHandler<'a> {
    should_close: &'a mut bool,
    input: &'a mut NativeWindowInput,
    scale_factor: &'a mut f64,
}

impl<'a> ApplicationHandler for PumpHandler<'a> {
    fn resumed(&mut self, _event_loop: &ActiveEventLoop) {}

    fn window_event(&mut self, _event_loop: &ActiveEventLoop, _id: WindowId, event: WindowEvent) {
        handle_window_event(self.should_close, self.input, self.scale_factor, event);
    }
}

#[derive(Default)]
pub struct NativeWindowInput {
    pub has_cursor: bool,
    pub mouse_x: f32,
    pub mouse_y: f32,

    pub key_down: HashSet<KeyCode>,
    pub key_just_pressed: HashSet<KeyCode>,
    pub key_just_released: HashSet<KeyCode>,

    pub mouse_down: HashSet<MouseButton>,
    pub mouse_just_pressed: HashSet<MouseButton>,
    pub mouse_just_released: HashSet<MouseButton>,
}

pub struct NativeWindow {
    event_loop: EventLoop<()>,
    window: Arc<Window>,

    pub should_close: bool,
    scale_factor: f64,
    pub input: NativeWindowInput,
}

impl NativeWindow {
    pub fn create(width: i32, height: i32, title: &str) -> anyhow::Result<Self> {
        let event_loop = EventLoop::new()?;

        // Note: `EventLoop::create_window` is deprecated, but it allows us to
        // create the window synchronously to satisfy mgstudio's host contract.
        #[allow(deprecated)]
        let window = event_loop.create_window(
            WindowAttributes::default()
                .with_title(title.to_string())
                .with_inner_size(LogicalSize::new(width.max(1) as f64, height.max(1) as f64)),
        )?;

        Ok(Self {
            event_loop,
            window: Arc::new(window),
            should_close: false,
            scale_factor: 1.0,
            input: NativeWindowInput::default(),
        })
    }

    pub fn pump_events(&mut self) {
        // Refresh scale factor each pump (can change when moving the window between displays).
        self.scale_factor = self.window.scale_factor();
        let (should_close, input, scale_factor) =
            (&mut self.should_close, &mut self.input, &mut self.scale_factor);
        let mut handler = PumpHandler {
            should_close,
            input,
            scale_factor,
        };
        // Non-blocking pump: process pending events and return immediately.
        let _ = self
            .event_loop
            .pump_app_events(Some(Duration::from_millis(0)), &mut handler);
    }

    pub fn inner_size(&self) -> PhysicalSize<u32> {
        self.window.inner_size()
    }

    pub fn window(&self) -> &Window {
        self.window.as_ref()
    }

    pub fn window_arc(&self) -> Arc<Window> {
        self.window.clone()
    }

    pub fn scale_factor(&self) -> f64 {
        self.scale_factor
    }

    pub fn input_finish_frame(&mut self) {
        self.input.key_just_pressed.clear();
        self.input.key_just_released.clear();
        self.input.mouse_just_pressed.clear();
        self.input.mouse_just_released.clear();
    }
}

fn handle_window_event(
    should_close: &mut bool,
    input: &mut NativeWindowInput,
    scale_factor: &mut f64,
    event: WindowEvent,
) {
    match event {
        WindowEvent::CloseRequested => {
            *should_close = true;
        }
        WindowEvent::CursorEntered { .. } => {
            input.has_cursor = true;
        }
        WindowEvent::CursorLeft { .. } => {
            input.has_cursor = false;
        }
        WindowEvent::CursorMoved { position, .. } => {
            input.has_cursor = true;
            set_cursor_position(input, *scale_factor, position);
        }
        WindowEvent::MouseInput { state, button, .. } => match state {
            ElementState::Pressed => {
                if input.mouse_down.insert(button) {
                    input.mouse_just_pressed.insert(button);
                }
            }
            ElementState::Released => {
                if input.mouse_down.remove(&button) {
                    input.mouse_just_released.insert(button);
                }
            }
        },
        WindowEvent::KeyboardInput { event, .. } => {
            if let PhysicalKey::Code(code) = event.physical_key {
                match event.state {
                    ElementState::Pressed => {
                        if input.key_down.insert(code) {
                            input.key_just_pressed.insert(code);
                        }
                    }
                    ElementState::Released => {
                        if input.key_down.remove(&code) {
                            input.key_just_released.insert(code);
                        }
                    }
                }
            }
        }
        WindowEvent::ScaleFactorChanged { scale_factor: sf, .. } => {
            *scale_factor = sf;
        }
        _ => {}
    }
}

fn set_cursor_position(input: &mut NativeWindowInput, scale_factor: f64, pos: PhysicalPosition<f64>) {
    let logical: LogicalPosition<f64> = pos.to_logical(scale_factor);
    input.mouse_x = logical.x as f32;
    input.mouse_y = logical.y as f32;
}
