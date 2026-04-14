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
fn named_default_plugin(
  name : String,
  plugin : @app.Plugin[@ecs.World],
) -> @app.NamedWorldPlugin {
  @app.named_world_plugin(name, plugin)
}

///|
fn default_plugins_builder(
  asset_plugin : @app.Plugin[@ecs.World],
) -> @app.PluginGroupBuilder[@ecs.World] {
  @app.PluginGroupBuilder::start_named(DEFAULT_PLUGINS_NAME)
  .add_typed(
    named_default_plugin("mgstudio.log.LogPlugin", fn(
      app : @app.App[@ecs.World],
    ) -> @app.App[@ecs.World] {
      @app.log_plugin_default(app)
    }),
  )
  .add_typed(
    named_default_plugin("mgstudio.window.WindowPlugin", fn(
      app : @app.App[@ecs.World],
    ) -> @app.App[@ecs.World] {
      @window.window_plugin(app)
    }),
  )
  .add_typed(
    named_default_plugin("mgstudio.a11y.AccessibilityPlugin", fn(
      app : @app.App[@ecs.World],
    ) -> @app.App[@ecs.World] {
      @a11y.a11y_plugin(app)
    }),
  )
  .add_typed(
    named_default_plugin("mgstudio.winit.WinitPlugin", fn(
      app : @app.App[@ecs.World],
    ) -> @app.App[@ecs.World] {
      @winit.winit_plugin(app)
    }),
  )
  .add_typed(@diagnostic.FrameCountPlugin::default())
  .add_typed(
    named_default_plugin("mgstudio.app.StatesPlugin", fn(
      app : @app.App[@ecs.World],
    ) -> @app.App[@ecs.World] {
      @app.states_plugin(@app.StatesPlugin::default())(app)
    }),
  )
  .add_typed(
    named_default_plugin("mgstudio.time.TimePlugin", fn(
      app : @app.App[@ecs.World],
    ) -> @app.App[@ecs.World] {
      @time.time_plugin(app)
    }),
  )
  .add_typed(
    named_default_plugin("mgstudio.asset.WebAssetPlugin", fn(
      app : @app.App[@ecs.World],
    ) -> @app.App[@ecs.World] {
      @asset.web_asset_plugin(
        @asset.WebAssetPlugin::default().with_silence_startup_warning(true),
      )(app)
    }),
  )
  .add_typed(named_default_plugin("mgstudio.asset.AssetPlugin", asset_plugin))
  .add_typed(
    named_default_plugin("mgstudio.shader.ShaderPlugin", fn(
      app : @app.App[@ecs.World],
    ) -> @app.App[@ecs.World] {
      @shader.shader_plugin(app)
    }),
  )
  .add_typed(
    named_default_plugin("mgstudio.audio.AudioPlugin", fn(
      app : @app.App[@ecs.World],
    ) -> @app.App[@ecs.World] {
      @audio.audio_plugin(app)
    }),
  )
  .add_typed(
    named_default_plugin("mgstudio.scene.ScenePlugin", fn(
      app : @app.App[@ecs.World],
    ) -> @app.App[@ecs.World] {
      @scene.scene_plugin(app)
    }),
  )
  .add_typed(@animation.AnimationPlugin::default())
  .add_typed(
    named_default_plugin("mgstudio.transform.TransformPlugin", fn(
      app : @app.App[@ecs.World],
    ) -> @app.App[@ecs.World] {
      @transform.transform_plugin(app)
    }),
  )
  .add_typed(@diagnostic.DiagnosticsPlugin::default())
  .add_typed(
    named_default_plugin("mgstudio.render.RenderPlugin", fn(
      app : @app.App[@ecs.World],
    ) -> @app.App[@ecs.World] {
      @render.render_plugin(app)
    }),
  )
  .add_typed(
    named_default_plugin("mgstudio.visibility.VisibilityPlugin", fn(
      app : @app.App[@ecs.World],
    ) -> @app.App[@ecs.World] {
      @visibility.visibility_plugin(app)
    }),
  )
  .add_typed(
    named_default_plugin("mgstudio.input.InputPlugin", fn(
      app : @app.App[@ecs.World],
    ) -> @app.App[@ecs.World] {
      @input.input_plugin(app)
    }),
  )
  .add_typed(
    named_default_plugin("mgstudio.picking.PickingPlugin", fn(
      app : @app.App[@ecs.World],
    ) -> @app.App[@ecs.World] {
      @picking.picking_plugin(app)
    }),
  )
  .add_typed(
    named_default_plugin("mgstudio.ui.UiPlugin", fn(
      app : @app.App[@ecs.World],
    ) -> @app.App[@ecs.World] {
      @ui.ui_plugin(app)
    }),
  )
  .add_typed(
    named_default_plugin("mgstudio.ui_render.UiRenderPlugin", fn(
      app : @app.App[@ecs.World],
    ) -> @app.App[@ecs.World] {
      @ui_render.ui_render_plugin(app)
    }),
  )
  .add_typed(@gltf_loader.GltfPlugin::default())
  .add_typed(
    named_default_plugin("mgstudio.text.TextPlugin", fn(
      app : @app.App[@ecs.World],
    ) -> @app.App[@ecs.World] {
      @text.text_plugin(app)
    }),
  )
  .add_typed(
    named_default_plugin("mgstudio.pbr.PbrPlugin", fn(
      app : @app.App[@ecs.World],
    ) -> @app.App[@ecs.World] {
      @pbr.pbr_plugin(app)
    }),
  )
  .add_typed(
    named_default_plugin("mgstudio.anti_alias.AntiAliasPlugin", fn(
      app : @app.App[@ecs.World],
    ) -> @app.App[@ecs.World] {
      @anti_alias.anti_alias_plugin(app)
    }),
  )
  .add_typed(
    named_default_plugin("mgstudio.sprite.SpritePlugin", fn(
      app : @app.App[@ecs.World],
    ) -> @app.App[@ecs.World] {
      @sprite.sprite_plugin(app)
    }),
  )
  .add_typed(
    named_default_plugin("mgstudio.sprite_render.SpriteRenderPlugin", fn(
      app : @app.App[@ecs.World],
    ) -> @app.App[@ecs.World] {
      @sprite_render.sprite_render_plugin_ecs(app)
    }),
  )
  .add_typed(
    named_default_plugin("mgstudio.physics2d.Physics2dPlugin", fn(
      app : @app.App[@ecs.World],
    ) -> @app.App[@ecs.World] {
      @physics2d.physics2d_plugin(app)
    }),
  )
  .add_typed(
    named_default_plugin("mgstudio.physics3d.Physics3dPlugin", fn(
      app : @app.App[@ecs.World],
    ) -> @app.App[@ecs.World] {
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
  .add_typed(@diagnostic.FrameCountPlugin::default())
  .add_typed(
    named_default_plugin("mgstudio.app.StatesPlugin", fn(
      app : @app.App[@ecs.World],
    ) -> @app.App[@ecs.World] {
      @app.states_plugin(@app.StatesPlugin::default())(app)
    }),
  )
  .add_typed(
    named_default_plugin("mgstudio.time.TimePlugin", fn(
      app : @app.App[@ecs.World],
    ) -> @app.App[@ecs.World] {
      @time.time_plugin(app)
    }),
  )
  .add_typed(
    named_default_plugin("mgstudio.app.ScheduleRunnerPlugin", fn(
      app : @app.App[@ecs.World],
    ) -> @app.App[@ecs.World] {
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
