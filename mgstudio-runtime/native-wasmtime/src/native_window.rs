use std::collections::HashSet;
use std::sync::Arc;
use std::time::Duration;

use winit::application::ApplicationHandler;
use winit::dpi::{LogicalPosition, LogicalSize, PhysicalPosition, PhysicalSize};
use winit::event::{ElementState, MouseButton, MouseScrollDelta, WindowEvent};
use winit::event_loop::{ActiveEventLoop, EventLoop};
use winit::keyboard::{KeyCode, PhysicalKey};
use winit::platform::pump_events::EventLoopExtPumpEvents;
use winit::window::{CursorGrabMode, Fullscreen, Window, WindowAttributes, WindowId};

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
    pub wheel_x: f32,
    pub wheel_y: f32,
    pub text_events: Vec<String>,

    pub key_down: HashSet<KeyCode>,
    pub key_just_pressed: HashSet<KeyCode>,
    pub key_just_released: HashSet<KeyCode>,
    pub key_repeated: HashSet<KeyCode>,

    pub mouse_down: HashSet<MouseButton>,
    pub mouse_just_pressed: HashSet<MouseButton>,
    pub mouse_just_released: HashSet<MouseButton>,
    pub touch_events: Vec<TouchEvent>,
}

pub struct TouchEvent {
    pub id: i32,
    pub phase: i32,
    pub x: f32,
    pub y: f32,
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
        window.focus_window();

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
        let (should_close, input, scale_factor) = (
            &mut self.should_close,
            &mut self.input,
            &mut self.scale_factor,
        );
        let mut handler = PumpHandler {
            should_close,
            input,
            scale_factor,
        };
        // Non-blocking pump: process pending events and return immediately.
        let _ = self
            .event_loop
            .pump_app_events(Some(Duration::from_millis(1)), &mut handler);
    }

    pub fn inner_size(&self) -> PhysicalSize<u32> {
        self.window.inner_size()
    }

    pub fn window_arc(&self) -> Arc<Window> {
        self.window.clone()
    }

    pub fn scale_factor(&self) -> f64 {
        self.scale_factor
    }

    pub fn set_title(&self, title: &str) {
        self.window.set_title(title);
    }

    pub fn set_size(&self, width: i32, height: i32) {
        let w = width.max(1) as f64;
        let h = height.max(1) as f64;
        let _ = self.window.request_inner_size(LogicalSize::new(w, h));
    }

    pub fn set_resizable(&self, resizable: bool) {
        self.window.set_resizable(resizable);
    }

    pub fn set_cursor_visible(&self, visible: bool) {
        self.window.set_cursor_visible(visible);
    }

    pub fn set_cursor_grab_mode(&self, mode: i32) {
        let grab_mode = match mode {
            1 => CursorGrabMode::Confined,
            2 => CursorGrabMode::Locked,
            _ => CursorGrabMode::None,
        };
        let _ = self.window.set_cursor_grab(grab_mode);
    }

    pub fn set_mode(&self, mode: i32) {
        if mode == 0 {
            self.window.set_fullscreen(None);
            return;
        }
        self.window
            .set_fullscreen(Some(Fullscreen::Borderless(None)));
    }

    pub fn set_position(&self, x: i32, y: i32) {
        self.window
            .set_outer_position(LogicalPosition::new(x as f64, y as f64));
    }

    pub fn position_x(&self) -> i32 {
        self.window.outer_position().map(|pos| pos.x).unwrap_or(0)
    }

    pub fn position_y(&self) -> i32 {
        self.window.outer_position().map(|pos| pos.y).unwrap_or(0)
    }

    pub fn input_finish_frame(&mut self) {
        self.input.key_just_pressed.clear();
        self.input.key_just_released.clear();
        self.input.key_repeated.clear();
        self.input.text_events.clear();
        self.input.mouse_just_pressed.clear();
        self.input.mouse_just_released.clear();
        self.input.wheel_x = 0.0;
        self.input.wheel_y = 0.0;
        self.input.touch_events.clear();
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
        WindowEvent::MouseWheel { delta, .. } => {
            let (dx, dy) = match delta {
                MouseScrollDelta::LineDelta(x, y) => (x, y),
                MouseScrollDelta::PixelDelta(pos) => {
                    let logical: LogicalPosition<f64> = pos.to_logical(*scale_factor);
                    (logical.x as f32, logical.y as f32)
                }
            };
            input.wheel_x += dx;
            input.wheel_y += dy;
        }
        WindowEvent::Touch(touch) => {
            let logical: LogicalPosition<f64> = touch.location.to_logical(*scale_factor);
            let phase = match touch.phase {
                winit::event::TouchPhase::Started => 0,
                winit::event::TouchPhase::Moved => 1,
                winit::event::TouchPhase::Ended => 2,
                winit::event::TouchPhase::Cancelled => 3,
            };
            input.touch_events.push(TouchEvent {
                id: i32::try_from(touch.id).unwrap_or(-1),
                phase,
                x: logical.x as f32,
                y: logical.y as f32,
            });
        }
        WindowEvent::KeyboardInput { event, .. } => {
            if let PhysicalKey::Code(code) = event.physical_key {
                match event.state {
                    ElementState::Pressed => {
                        if event.repeat {
                            input.key_repeated.insert(code);
                        }
                        if let Some(text) = event.text.as_ref() {
                            push_text_event(input, text.as_str());
                        }
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
        WindowEvent::ScaleFactorChanged {
            scale_factor: sf, ..
        } => {
            *scale_factor = sf;
        }
        _ => {}
    }
}

fn set_cursor_position(
    input: &mut NativeWindowInput,
    scale_factor: f64,
    pos: PhysicalPosition<f64>,
) {
    let logical: LogicalPosition<f64> = pos.to_logical(scale_factor);
    input.mouse_x = logical.x as f32;
    input.mouse_y = logical.y as f32;
}

fn push_text_event(input: &mut NativeWindowInput, text: &str) {
    if text.is_empty() || text.chars().all(|ch| ch.is_control()) {
        return;
    }
    input.text_events.push(text.to_string());
}
