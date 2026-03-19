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
pub struct DefaultPlugins {}

///|
fn default_plugins_marker() -> DefaultPlugins {
  DefaultPlugins::{  }
}

///|
const DEFAULT_PLUGINS_NAME : String = "DefaultPlugins"

///|
const MINIMAL_PLUGINS_NAME : String = "MinimalPlugins"

///|
const DEFAULT_PLUGIN_ID_LOG : String = "bevy_log::LogPlugin"

///|
const DEFAULT_PLUGIN_ID_TASK_POOL : String = "bevy_app::TaskPoolPlugin"

///|
const DEFAULT_PLUGIN_ID_WINDOW : String = @window.WINDOW_PLUGIN_ID

///|
const DEFAULT_PLUGIN_ID_WINIT : String = @winit.WINIT_PLUGIN_ID

///|
const DEFAULT_PLUGIN_ID_FRAME_COUNT : String = "bevy_diagnostic::FrameCountPlugin"

///|
const DEFAULT_PLUGIN_ID_STATES : String = "bevy_state::StatesPlugin"

///|
const DEFAULT_PLUGIN_ID_TIME : String = "bevy_time::TimePlugin"

///|
const DEFAULT_PLUGIN_ID_ASSET : String = "bevy_asset::AssetPlugin"

///|
const DEFAULT_PLUGIN_ID_SHADER : String = @shader.SHADER_PLUGIN_ID

///|
const DEFAULT_PLUGIN_ID_AUDIO : String = "bevy_audio::AudioPlugin"

///|
const DEFAULT_PLUGIN_ID_SCENE : String = "bevy_scene::ScenePlugin"

///|
const DEFAULT_PLUGIN_ID_ANIMATION : String = "bevy_animation::AnimationPlugin"

///|
const DEFAULT_PLUGIN_ID_TRANSFORM : String = "bevy_transform::TransformPlugin"

///|
const DEFAULT_PLUGIN_ID_DIAGNOSTICS : String = "bevy_diagnostic::DiagnosticsPlugin"

///|
const DEFAULT_PLUGIN_ID_VISIBILITY : String = "bevy_render::VisibilityPlugin"

///|
const DEFAULT_PLUGIN_ID_INPUT : String = "bevy_input::InputPlugin"

///|
const DEFAULT_PLUGIN_ID_PICKING : String = "bevy_picking::PickingPlugin"

///|
const DEFAULT_PLUGIN_ID_A11Y : String = "bevy_a11y::AccessibilityPlugin"

///|
const DEFAULT_PLUGIN_ID_UI : String = "bevy_ui::UiPlugin"

///|
const DEFAULT_PLUGIN_ID_UI_RENDER : String = "bevy_ui_render::UiRenderPlugin"

///|
const DEFAULT_PLUGIN_ID_GLTF : String = "bevy_gltf::GltfPlugin"

///|
const DEFAULT_PLUGIN_ID_TEXT : String = "bevy_text::TextPlugin"

///|
const DEFAULT_PLUGIN_ID_RENDER3D : String = @pbr.PBR_PLUGIN_ID

///|
const DEFAULT_PLUGIN_ID_ANTI_ALIAS : String = @anti_alias.ANTI_ALIAS_PLUGIN_ID

///|
const DEFAULT_PLUGIN_ID_SPRITE : String = @sprite.SPRITE_PLUGIN_ID

///|
const DEFAULT_PLUGIN_ID_SPRITE_RENDER : String = @sprite_render.SPRITE_RENDER_PLUGIN_ID

///|
const DEFAULT_PLUGIN_ID_PHYSICS2D : String = "mgstudio::Physics2dPlugin"

///|
const DEFAULT_PLUGIN_ID_PHYSICS3D : String = "mgstudio::Physics3dPlugin"

///|
const MINIMAL_PLUGIN_ID_TASK_POOL : String = "bevy_app::TaskPoolPlugin"

///|
const MINIMAL_PLUGIN_ID_FRAME_COUNT : String = "bevy_diagnostic::FrameCountPlugin"

///|
const MINIMAL_PLUGIN_ID_STATES : String = "bevy_state::StatesPlugin"

///|
const MINIMAL_PLUGIN_ID_TIME : String = "bevy_time::TimePlugin"

///|
const MINIMAL_PLUGIN_ID_SCHEDULE_RUNNER : String = "bevy_app::ScheduleRunnerPlugin"

///|
fn world_plugin(plugin : @app.Plugin[@ecs.World]) -> @app.Plugin[@ecs.World] {
  plugin
}

///|
fn default_plugins_builder(
  asset_plugin : @app.Plugin[@ecs.World],
) -> @app.PluginGroupBuilder[@ecs.World] {
  @app.PluginGroupBuilder::start_named(DEFAULT_PLUGINS_NAME)
  .add_named(
    id=DEFAULT_PLUGIN_ID_LOG,
    world_plugin(fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @app.log_plugin_default(app)
    }),
  )
  .add_named(
    id=DEFAULT_PLUGIN_ID_TASK_POOL,
    world_plugin(fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @app.task_pool_plugin(@app.TaskPoolPlugin::default())(app)
    }),
  )
  .add_named(
    id=DEFAULT_PLUGIN_ID_WINDOW,
    world_plugin(fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @window.window_plugin(app)
    }),
  )
  .add_named(
    id=DEFAULT_PLUGIN_ID_A11Y,
    world_plugin(fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @a11y.a11y_plugin(app)
    }),
  )
  .add_named(
    id=DEFAULT_PLUGIN_ID_WINIT,
    world_plugin(fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @winit.winit_plugin(app)
    }),
  )
  .add_named(
    id=DEFAULT_PLUGIN_ID_FRAME_COUNT,
    world_plugin(fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @diagnostic.frame_count_plugin(app)
    }),
  )
  .add_named(
    id=DEFAULT_PLUGIN_ID_STATES,
    world_plugin(fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @app.states_plugin(@app.StatesPlugin::default())(app)
    }),
  )
  .add_named(
    id=DEFAULT_PLUGIN_ID_TIME,
    world_plugin(fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @time.time_plugin(app)
    }),
  )
  .add_named(id=DEFAULT_PLUGIN_ID_ASSET, asset_plugin)
  .add_named(
    id=DEFAULT_PLUGIN_ID_SHADER,
    world_plugin(fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @shader.shader_plugin(app)
    }),
  )
  .add_named(
    id=DEFAULT_PLUGIN_ID_AUDIO,
    world_plugin(fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @audio.audio_plugin(app)
    }),
  )
  .add_named(
    id=DEFAULT_PLUGIN_ID_SCENE,
    world_plugin(fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @scene.scene_plugin(app)
    }),
  )
  .add_named(
    id=DEFAULT_PLUGIN_ID_ANIMATION,
    world_plugin(fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @animation.animation_plugin(app)
    }),
  )
  .add_named(
    id=DEFAULT_PLUGIN_ID_TRANSFORM,
    world_plugin(fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @transform.transform_plugin(app)
    }),
  )
  .add_named(
    id=DEFAULT_PLUGIN_ID_DIAGNOSTICS,
    world_plugin(fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @diagnostic.diagnostics_plugin(app)
    }),
  )
  .add_named(
    id=DEFAULT_PLUGIN_ID_VISIBILITY,
    world_plugin(fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @visibility.visibility_plugin(app)
    }),
  )
  .add_named(
    id=DEFAULT_PLUGIN_ID_INPUT,
    world_plugin(fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @input.input_plugin(app)
    }),
  )
  .add_named(
    id=DEFAULT_PLUGIN_ID_PICKING,
    world_plugin(fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @picking.picking_plugin(app)
    }),
  )
  .add_named(
    id=DEFAULT_PLUGIN_ID_UI,
    world_plugin(fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @ui.ui_plugin(app)
    }),
  )
  .add_named(
    id=DEFAULT_PLUGIN_ID_UI_RENDER,
    world_plugin(fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @ui_render.ui_render_plugin(app)
    }),
  )
  .add_named(
    id=DEFAULT_PLUGIN_ID_GLTF,
    world_plugin(fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @gltf.gltf_plugin(app)
    }),
  )
  .add_named(
    id=DEFAULT_PLUGIN_ID_TEXT,
    world_plugin(fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @text.text_plugin(app)
    }),
  )
  .add_named(
    id=DEFAULT_PLUGIN_ID_RENDER3D,
    world_plugin(fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @pbr.pbr_plugin(app)
    }),
  )
  .add_named(
    id=DEFAULT_PLUGIN_ID_ANTI_ALIAS,
    world_plugin(fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @anti_alias.anti_alias_plugin(app)
    }),
  )
  .add_named(
    id=DEFAULT_PLUGIN_ID_SPRITE,
    world_plugin(fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @sprite.sprite_plugin(app)
    }),
  )
  .add_named(
    id=DEFAULT_PLUGIN_ID_SPRITE_RENDER,
    world_plugin(fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @sprite_render.sprite_render_plugin_ecs(app)
    }),
  )
  .add_named(
    id=DEFAULT_PLUGIN_ID_PHYSICS2D,
    world_plugin(fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @physics2d.physics2d_plugin(app)
    }),
  )
  .add_named(
    id=DEFAULT_PLUGIN_ID_PHYSICS3D,
    world_plugin(fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @physics3d.physics3d_plugin(app)
    }),
  )
}

///|
pub fn DefaultPlugins::build() -> @app.PluginGroupBuilder[@ecs.World] {
  default_plugins_marker() |> ignore
  default_plugins_builder(fn(
    app : @app.App[@ecs.World],
  ) -> @app.App[@ecs.World] {
    @asset.asset_plugin(app)
  })
}

///|
pub fn[P : @app.PluginReplacement] DefaultPlugins::set(
  replacement : P,
) -> @app.PluginGroupBuilder[@ecs.World] {
  default_plugins_marker() |> ignore
  DefaultPlugins::build().set(replacement)
}

///|
pub struct MinimalPlugins {}

///|
fn minimal_plugins_marker() -> MinimalPlugins {
  MinimalPlugins::{  }
}

///|
fn minimal_plugins_builder() -> @app.PluginGroupBuilder[@ecs.World] {
  @app.PluginGroupBuilder::start_named(MINIMAL_PLUGINS_NAME)
  .add_named(
    id=MINIMAL_PLUGIN_ID_TASK_POOL,
    world_plugin(fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @app.task_pool_plugin(@app.TaskPoolPlugin::default())(app)
    }),
  )
  .add_named(
    id=MINIMAL_PLUGIN_ID_FRAME_COUNT,
    world_plugin(fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @diagnostic.frame_count_plugin(app)
    }),
  )
  .add_named(
    id=MINIMAL_PLUGIN_ID_STATES,
    world_plugin(fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @app.states_plugin(@app.StatesPlugin::default())(app)
    }),
  )
  .add_named(
    id=MINIMAL_PLUGIN_ID_TIME,
    world_plugin(fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @time.time_plugin(app)
    }),
  )
  .add_named(
    id=MINIMAL_PLUGIN_ID_SCHEDULE_RUNNER,
    world_plugin(fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
      @app.schedule_runner_plugin(@app.ScheduleRunnerPlugin::run_loop(0.0F))(
        app,
      )
    }),
  )
}

///|
pub fn MinimalPlugins::build() -> @app.PluginGroupBuilder[@ecs.World] {
  minimal_plugins_marker() |> ignore
  minimal_plugins_builder()
}

///|
/// Default plugin bundle, aligned with Bevy's `DefaultPlugins` concept.
pub fn default_plugins() -> Array[@app.Plugin[@ecs.World]] {
  DefaultPlugins::build().build()
}

///|
/// Default plugin bundle with "nearest" sampling for textures (useful for pixel art).
pub fn default_plugins_nearest() -> Array[@app.Plugin[@ecs.World]] {
  default_plugins_builder(fn(
    app : @app.App[@ecs.World],
  ) -> @app.App[@ecs.World] {
    @asset.asset_plugin_nearest(app)
  }).build()
}

///|
/// Minimal plugin bundle, aligned with Bevy's `MinimalPlugins` concept.
pub fn minimal_plugins() -> Array[@app.Plugin[@ecs.World]] {
  MinimalPlugins::build().build()
}
