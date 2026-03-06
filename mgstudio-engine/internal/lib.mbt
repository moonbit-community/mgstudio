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
/// Root exports for `Milky2018/mgstudio/internal`, aligned with Bevy's
/// `bevy_internal::lib`.
///
/// MoonBit packages are flat at the directory level, so `lib.mbt`,
/// `prelude.mbt`, and `default_plugins.mbt` all contribute to the same package
/// root instead of creating nested file modules.

///|
pub using @app {
  type AppExit,
  type AppLabel,
  type LogLevel,
  type LogPlugin,
  type PluginGroupBuilder,
  type RenderErrorPolicy,
  type RenderRuntimeError,
  type ScheduleRunnerMode,
  type ScheduleRunnerPlugin,
  type TaskPoolOptions,
  type TaskPoolPlugin,
  app_label,
  log_plugin_default,
  schedule_runner_plugin,
  task_pool_plugin,
}

///|
pub using @animation {
  type AnimationTargetId,
  type AnimationTransitions,
  type AnimationWeights,
  type RepeatAnimation,
  animation_plugin,
}

///|
pub using @asset {
  type AssetEvent,
  type AssetId,
  type AssetLoaderKind,
  type AssetSourceId,
  type DynamicTextureAtlasBuilder,
  type ImageArrayLayout,
  type ImageSampler,
  type LoadedFolder,
  type ParsedAssetPath,
  asset_plugin,
  asset_plugin_nearest,
}

///|
pub using @audio {
  type AudioPlugin,
  type AudioPlayer,
  type AudioSink,
  type AudioSource,
  type DefaultSpatialScale,
  type GlobalVolume,
  type PlaybackMode,
  type PlaybackSettings,
  type SpatialListener,
  type Volume,
  audio_plugin,
}

///|
pub using @diagnostics {
  type DiagnosticsPlugin,
  type EntityCountDiagnosticsPlugin,
  type FrameCountPlugin,
  type FrameTimeDiagnosticsPlugin,
  type LogDiagnosticsPlugin,
  diagnostics_plugin,
  entity_count_diagnostics_plugin,
  frame_count_plugin,
  frame_time_diagnostics_plugin,
  log_diagnostics_plugin,
}

///|
pub using @input {
  type ButtonState,
  type CursorMoved,
  type DoubleTapGesture,
  type FileDragAndDrop,
  type GamepadAxis,
  type GamepadAxisChangedEvent,
  type GamepadButton,
  type GamepadButtonChangedEvent,
  type GamepadButtonStateChangedEvent,
  type GamepadConnection,
  type GamepadConnectionEvent,
  type GamepadEvent,
  type GamepadInput,
  type KeyboardCharacter,
  type MouseMotion,
  type MouseScrollUnit,
  type MouseWheel,
  type PinchGesture,
  type RotationGesture,
  type Touch,
  type TouchPhase,
  type Touches,
  input_plugin,
}

///|
pub using @scene {
  type GltfAssetLabel,
  type GltfLodVisibilityPolicy,
  type SceneInstanceReady,
  type SceneNode3d,
  scene_plugin,
  scene_plugin_ecs,
}

///|
pub using @picking {
  type PickingEvents,
  type PickingHits,
  type PickingState,
  type PointerButton,
  type PointerEvent,
  type PointerEventKind,
  type PointerInput,
  type PointerInputs,
  picking_plugin,
}

///|
pub using @a11y {type A11yState, a11y_plugin}

///|
pub using @time {time_plugin}

///|
pub using @transform {
  type Affine2,
  transform_plugin,
  transform_plugin_ecs,
  transform_set_propagate,
  transform_set_update_children,
}

///|
pub using @visibility {visibility_plugin}

///|
pub using @window {type WindowResized, window_plugin}

///|
pub using @text {
  type ComputedTextBlock,
  type CosmicBuffer,
  type FontAtlas,
  type FontAtlasKey,
  type FontAtlasSet,
  type FontSmoothing,
  type GlyphAtlasInfo,
  type GlyphCacheKey,
  type GlyphRaster,
  type TextBackgroundColor,
  type TextBounds,
  type TextHandle,
  text_plugin,
}

///|
pub using @ui {
  type AccessibilityLabel,
  type BoxShadow,
  type ButtonColors,
  type CalculatedClip,
  type ContentSize,
  type GlobalZIndex,
  type ImageNode,
  type ImageNodeSize,
  type Label,
  type Outline,
  type RelativeCursorPosition,
  type ScrollPosition,
  type UiAntiAlias,
  type UiBoxShadowSamples,
  type UiContext,
  type UiLayout,
  type UiScale,
  type UiStack,
  ui_plugin,
}

///|
pub using @render2d {
  type AlphaMode2d,
  type Bloom2d,
  type ClearColor,
  type ClearColorConfig,
  type Mesh2d,
  type Mesh2dBundle,
  type MeshMaterial2d,
  type RenderTarget,
  type Wireframe2d,
  type Wireframe2dColor,
  type Wireframe2dConfig,
  render2d_plugin,
  render2d_plugin_ecs,
  wireframe2d_plugin,
}

///|
pub using @render3d {
  type AlphaMode3d,
  type Atmosphere,
  type AutoExposure,
  type ChromaticAberration,
  type ColorGrading,
  type ContactShadows,
  type EnvironmentMapLight,
  type FreeCamera,
  type FreeCameraState,
  type MotionBlur,
  type OrthographicProjection3d,
  type PerspectiveProjection3d,
  type ScreenSpaceAmbientOcclusion,
  type ScreenSpaceReflections,
  type ScreenSpaceTransmission,
  type TemporalAntiAliasing,
  type TemporalJitter,
  type Vignette,
  type VolumetricFog,
  type VolumetricLight,
  type Wireframe,
  type WireframeColor,
  type WireframeConfig,
  free_camera_plugin,
  render3d_plugin,
  wireframe_plugin,
}

///|
pub using @physics2d {
  type Collider2d,
  type CollisionEvent2d,
  type Physics2dConfig,
  type Physics2dContext,
  type Physics2dDebugRenderConfig,
  type Physics2dEvents,
  type RigidBody2d,
  type Velocity2d,
  physics2d_plugin,
}

///|
pub using @physics3d {
  type Collider3d,
  type CollisionEvent3d,
  type Physics3dConfig,
  type Physics3dContext,
  type Physics3dDebugRenderContext,
  type Physics3dEvents,
  type RigidBody3d,
  type Velocity3d,
  physics3d_debug_render_plugin,
  physics3d_plugin,
}
