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
struct Spin {
  speed : Float
}

///|
let spin_key : @ecs.ComponentKey[Spin] = @ecs.register_component(
  debug_name="examples.tools.scene_viewer.animation_plugin.Spin",
)

///|
pub impl @ecs.Component for Spin with component() {
  spin_key
}

///|
fn setup(world : @ecs.World) -> Unit {
  let mesh = @pbr.add_mesh(
    @pbr.mesh_assets_mut_or_abort().val,
    @math.Cuboid::new(1.3F, 1.3F, 1.3F),
  )
  let material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.45F, 0.78F, 0.95F)),
  )
  ignore(
    try! world
    .entity_mut(world.spawn_empty())
    .insert(
      (
        @pbr.Mesh3d::new(mesh),
        @pbr.MeshMaterial3d::new(material),
        @transform.Transform::identity(),
        Spin::{ speed: 0.8F },
      ),
    ),
  )
  ignore(
    @pbr.Camera3dBundle::new(
      @sprite.Camera::default(),
      @transform.Transform::from_xyz(5.0F, 4.0F, 7.0F).looking_at(
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ).spawn(world),
  )
  let light = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(light)
    .insert(
      (
        @pbr.DirectionalLight::new(@sprite.Color::white(), 8000.0F, true),
        @transform.Transform::from_xyz(3.0F, 8.0F, 3.0F).looking_at(
          @math.Vec3::new(0.0F, 0.0F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
}

///|
fn rotate_preview(
  time : @app.Res[@time.Time[Unit]],
  previews : @ecs.Query[
    (@ecs.Comp[Spin], @ecs.Mut[@transform.Transform]),
    @ecs.All,
  ],
) -> Unit {
  let t = time.get().elapsed_secs()
  try! previews.for_each(fn(_entity, data) {
    let (spin, transform) = data
    transform.get_ref().val.rotation = @math.Quat::from_euler(
      @math.EulerRot::ZYX,
      0.0F,
      t * spin.value().speed,
      t * spin.value().speed * 0.35F,
    )
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(@app.system_param2(rotate_preview)))
  .run()
}
