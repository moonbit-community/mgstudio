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
test "gizmos boundary re-exports configuration and plugin surface" {
  let app = @gizmos.init_gizmo_group(
    @app.App::new(@ecs.World::new()),
    @gizmos.DefaultGizmoConfigGroup::default(),
  )
  let _ = @gizmos.gizmo_plugin(app)
  debug_inspect(
    app.contains_resource(@gizmos.GizmoConfigStore::resource()),
    content="true",
  )
  debug_inspect("ok", content="\"ok\"")
}

///|
struct TestRoundGizmos {}

///|
impl Default for TestRoundGizmos with default() {
  TestRoundGizmos::{  }
}

///|
impl @sprite.GizmoConfigGroup for TestRoundGizmos with gizmo_config_group_marker(
  _self,
) {

}

///|
test "custom gizmo groups expose config through store and system param" {
  let seen_width = Ref::new(-1.0F)
  let app = @gizmos.init_gizmo_group(
    @app.App::new(@ecs.World::new()),
    TestRoundGizmos::default(),
  ).add_systems(
    @app.Update,
    @app.system(
      @app.system_param(fn(gizmos : @gizmos.Gizmos[TestRoundGizmos]) {
        seen_width.val = gizmos.config().line.width
      }),
    ),
  )

  match app.world().get_resource_ref_mut(@gizmos.GizmoConfigStore::resource()) {
    Some(store_ref) => {
      let (config_ref, _group_ref) = store_ref.val.config_mut(
        TestRoundGizmos::default(),
      )
      let current = config_ref.val
      config_ref.val = { ..current, line: { ..current.line, width: 7.0F } }
    }
    None => abort("Missing GizmoConfigStore resource in test")
  }

  ignore(app.update())
  debug_inspect(seen_width.val, content="7")
}

///|
test "retained gizmo component installs Bevy required Transform and asset store" {
  let app = @gizmos.gizmo_plugin(@app.App::new(@ecs.World::new()))
  let world = app.world()
  let entity = world.spawn()
  try! (world.entity_mut(entity).insert_component(@gizmos.Gizmo::default())
  |> ignore)
  debug_inspect(
    try! world.contains_by_key(entity, @transform.Transform::component()),
    content="true",
  )
  let assets_key : @ecs.ResourceKey[@asset.Assets[@gizmos.GizmoAsset]] = @asset.assets_resource_key()
  debug_inspect(world.get_resource(assets_key) is Some(_), content="true")
}

///|
test "retained gizmo asset stores Bevy line-list and line-strip buffers" {
  let asset = @gizmos.GizmoAsset::default()
  asset.line(
    @math.Vec3::zero(),
    @math.Vec3::new(1.0F, 0.0F, 0.0F),
    @color.Color::white(),
  )
  debug_inspect(asset.buffer().list_positions().length(), content="2")
  debug_inspect(asset.buffer().list_colors().length(), content="2")
  asset
  .buffer()
  .linestrip(
    [
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
      @math.Vec3::new(0.0F, 2.0F, 0.0F),
    ],
    @color.Color::white(),
  )
  debug_inspect(asset.buffer().strip_positions().length(), content="4")
  debug_inspect(asset.buffer().strip_colors().length(), content="4")
  asset.buffer().clear()
  debug_inspect(asset.buffer().list_positions().length(), content="0")
  debug_inspect(asset.buffer().strip_positions().length(), content="0")
}

///|
test "retained gizmo asset delegates Bevy buffer helpers" {
  let asset = @gizmos.GizmoAsset::default()
  asset.ray(
    @math.Vec3::zero(),
    @math.Vec3::new(1.0F, 0.0F, 0.0F),
    @color.Color::white(),
  )
  asset.line_gradient_2d(
    @math.Vec2::zero(),
    @math.Vec2::new(1.0F, 1.0F),
    @color.Color::white(),
    @color.Color::black(),
  )
  debug_inspect(asset.buffer().list_positions().length(), content="4")
  debug_inspect(asset.buffer().list_colors().length(), content="4")
  asset.linestrip_gradient([
    (@math.Vec3::zero(), @color.Color::white()),
    (@math.Vec3::new(0.0F, 1.0F, 0.0F), @color.Color::black()),
  ])
  debug_inspect(asset.buffer().strip_positions().length(), content="3")
  debug_inspect(asset.buffer().strip_colors().length(), content="3")
  asset.clear()
  asset.lineloop_2d(
    [
      @math.Vec2::zero(),
      @math.Vec2::new(1.0F, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
    ],
    @color.Color::white(),
  )
  debug_inspect(asset.buffer().strip_positions().length(), content="6")
}
