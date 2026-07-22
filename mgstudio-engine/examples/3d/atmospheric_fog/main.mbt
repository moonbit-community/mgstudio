// Copyright 2026 International Digital Economy Academy
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
fn fog_center() -> @math.Vec3 {
  @math.Vec3::new(0.0F, 0.0F, 0.0F)
}

///|
fn make_fog() -> @pbr.DistanceFog {
  @pbr.DistanceFog::DistanceFog()
  .with_color(@color.Color::srgba(0.35F, 0.48F, 0.66F, 1.0F))
  .with_directional_light_color(@color.Color::srgba(1.0F, 0.95F, 0.85F, 0.5F))
  .with_directional_light_exponent(30.0F)
  .with_falloff(
    @pbr.FogFalloff3d::from_visibility_colors(
      15.0F,
      @color.Color::srgb(0.35F, 0.5F, 0.66F),
      @color.Color::srgb(0.8F, 0.844F, 1.0F),
    ),
  )
}

///|
fn setup_camera_fog(commands : @app.Commands) -> Unit {
  ignore(
    commands.spawn(
      (
        @camera.Camera3d::Camera3d(),
        @transform.Transform::from_xyz(-1.0F, 0.1F, 1.0F).looking_at(
          fog_center(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
        make_fog(),
      ),
    ),
  )
}

///|
fn setup_terrain_scene(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let cascade_shadow_config = @pbr.CascadeShadowConfigBuilder::CascadeShadowConfigBuilder()
    .with_first_cascade_far_bound(0.3F)
    .with_maximum_distance(3.0F)
    .build()

  ignore(
    commands.spawn(
      (
        @pbr.DirectionalLight::new(
          @color.Color::srgb(0.98F, 0.95F, 0.82F),
          100_000.0F,
          true,
        ),
        cascade_shadow_config,
        @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F).looking_at(
          @math.Vec3::new(-0.15F, -0.05F, 0.25F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )

  let terrain = commands.spawn_empty()
  commands
  .entity(terrain)
  .insert_component(
    @scene.SceneRoot::new(
      @scene.scene_load_gltf_scene(
        asset_server.get(),
        @gltf.GltfAssetLabel::Scene(0).from_asset(
          "models/terrain/Mountains.gltf",
        ),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(
          meshes.modify(fn(mesh_assets) {
            mesh_assets |> @pbr.add_mesh(@math.Cuboid::new(2.0F, 1.0F, 1.0F))
          }),
        ),
        @pbr.MeshMaterial3dTyped::new(
          materials.modify(fn(material_assets) {
            material_assets
            |> @pbr.add_material(
              @pbr.StandardMaterial::from_color(
                @color.Color::new(0.53333336F, 0.53333336F, 0.53333336F, 1.0F),
              )
              .with_unlit(true)
              .with_cull_mode(None),
            )
          }),
        ),
        @transform.Transform::identity().with_scale(@math.Vec3::splat(20.0F)),
        @pbr.NotShadowCaster::NotShadowCaster(),
      ),
    ),
  )
}

///|
fn setup_instructions(commands : @app.Commands) -> Unit {
  ignore(
    commands.spawn(
      (
        @text.Text::new(
          "Press Spacebar to Toggle Atmospheric Fog.\nPress S to Toggle Directional Light Fog Influence.",
        ),
        @ui.Node::Node()
        .with_position_type(Absolute)
        .with_bottom(@ui.px(12.0F))
        .with_left(@ui.px(12.0F)),
      ),
    ),
  )
}

///|
fn toggle_system(
  keycode : @input.ButtonInput[@window.KeyCode],
  fog : @app.Single[@ecs.Write[@pbr.DistanceFog], @ecs.All],
) -> Unit {
  let fog = fog.get()
  if keycode.just_pressed(Space) {
    let value = fog.value()
    fog.set(
      value.with_color(value.color.with_alpha(1.0F - value.color.alpha())),
    )
  }

  if keycode.just_pressed(KeyS) {
    let value = fog.value()
    fog.set(
      value.with_directional_light_color(
        value.directional_light_color.with_alpha(
          0.5F - value.directional_light_color.alpha(),
        ),
      ),
    )
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_param(Startup, setup_camera_fog)
  .add_systems_param4(Startup, setup_terrain_scene)
  .add_systems_param(Startup, setup_instructions)
  .add_systems_param2(Update, toggle_system)
  .run()
}
