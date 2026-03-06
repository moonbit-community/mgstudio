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

///|
/// Common exports collected in the style of Bevy's `bevy_internal::prelude`.
///
/// In MoonBit this file contributes directly to the
/// `Milky2018/mgstudio/internal` package root.

///|
pub using @app {
  type App,
  type Plugin,
  type PluginGroup,
  type Res,
  type ResMut,
  type ScheduleStage,
  type SystemConfig,
  type SystemSet,
  trait Resource,
  trait SystemParam,
  system,
  system_param,
  system_param2,
  system_param3,
  system_param4,
  system_set,
}

///|
pub using @ecs {
  type ComponentAccess,
  type ComponentKey,
  type EventKey,
  type Query1,
  type Query2,
  type Query3,
  type ResourceAccess,
  type ResourceKey,
  type World,
  trait Component,
  trait EventData,
  trait ResourceData,
  register_component,
  register_event,
  register_resource,
}

///|
pub using @input {
  type ButtonInput,
  type Gamepad,
  type KeyboardInput,
  type MouseButtonInput,
  type TouchInput,
  key_just_pressed,
  key_just_released,
  key_pressed,
  mouse_button_just_pressed,
  mouse_button_just_released,
  mouse_button_pressed,
  mouse_position,
  primary_pointer_position,
}

///|
pub using @math {
  type IVec2,
  type Quat,
  type Rect,
  type Transform,
  type URect,
  type UVec2,
  type Vec2,
  type Vec3,
  type Vec4,
}

///|
pub using @time {type Time, type Timer, type TimerMode}

///|
pub using @transform {type GlobalTransform}

///|
pub using @window {
  type CursorGrabMode,
  type CursorIcon,
  type KeyCode,
  type MouseButton,
  type WindowMode,
}

///|
pub using @asset {
  type AssetServer,
  type Font,
  type Handle,
  type Image,
  type Shader,
  type TextureAtlas,
  type TextureAtlasLayout,
}

///|
pub using @diagnostics {
  type Diagnostic,
  type Diagnostics,
  type DiagnosticPath,
  type FrameCount,
}

///|
pub using @animation {
  type AnimationClip,
  type AnimationGraph,
  type AnimationGraphHandle,
  type AnimationPlayer,
}

///|
pub using @scene {type Scene, type SceneRoot}

///|
pub using @visibility {
  type InheritedVisibility,
  type ViewVisibility,
  type Visibility,
  type VisibilityRange,
}

///|
pub using @hierarchy {type Children, type Parent}

///|
pub using @mesh {
  type Mesh,
  type Mesh2dGeometry,
  type Mesh3dGeometry,
  type Mesh3dPrimitiveTopology,
}

///|
pub using @render2d {
  type Anchor,
  type Camera,
  type Camera2d,
  type Camera2dBundle,
  type Color,
  type OrthographicProjection,
  type Projection,
  type RenderLayers,
  type Sprite,
  type SpriteBundle,
  type Viewport,
}

///|
pub using @render3d {
  type Bloom,
  type Camera3d,
  type Camera3dBundle,
  type DirectionalLight,
  type Exposure,
  type Fxaa,
  type Hdr,
  type Mesh3d,
  type MeshMaterial3d,
  type MeshMaterial3dBundle,
  type Msaa,
  type PointLight,
  type Projection3d,
  type Skybox,
  type SpotLight,
  type StandardMaterial,
}

///|
pub using @text {
  type Justify,
  type LineBreak,
  type LineHeight,
  type Text2d,
  type Text2dBundle,
  type TextColor,
  type TextFont,
  type TextLayout,
  type TextSpan,
  type TextSpanBundle,
  type YAxisOrientation,
}

///|
pub using @ui {
  type AlignContent,
  type AlignItems,
  type AlignSelf,
  type BackgroundColor,
  type BorderColor,
  type BorderRadius,
  type Button,
  type Display,
  type Interaction,
  type JustifyContent,
  type JustifyItems,
  type JustifySelf,
  type Node,
  type Overflow,
  type PositionType,
  type UiImage,
  type UiRect,
  type UiRoot,
  type UiText,
  type Val,
  type ZIndex,
}
