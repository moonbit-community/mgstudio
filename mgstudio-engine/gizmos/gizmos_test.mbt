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
  let seen_width = Ref(-1.0F)
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

///|
test "retained gizmo asset delegates Bevy rect and cube helpers" {
  let asset = @gizmos.GizmoAsset::default()
  asset.rect_2d(
    @sprite.Isometry2d::identity(),
    @math.Vec2::new(2.0F, 2.0F),
    @color.Color::white(),
  )
  debug_inspect(asset.buffer().strip_positions().length(), content="7")
  asset.clear()
  asset.rect(
    @math.Isometry3d::identity(),
    @math.Vec2::new(2.0F, 2.0F),
    @color.Color::white(),
  )
  debug_inspect(asset.buffer().strip_positions().length(), content="7")
  asset.clear()
  asset.cube(@transform.Transform::identity(), @color.Color::white())
  debug_inspect(asset.buffer().strip_positions().length(), content="11")
  debug_inspect(asset.buffer().list_positions().length(), content="6")
  asset.ray_2d(
    @math.Vec2::zero(),
    @math.Vec2::new(1.0F, 0.0F),
    @color.Color::white(),
  )
  asset.ray_gradient_2d(
    @math.Vec2::zero(),
    @math.Vec2::new(0.0F, 1.0F),
    @color.Color::white(),
    @color.Color::black(),
  )
  debug_inspect(asset.buffer().list_positions().length(), content="10")
}

///|
test "retained gizmo asset delegates Bevy cross helpers" {
  let asset = @gizmos.GizmoAsset::default()
  asset.cross(@math.Isometry3d::identity(), 0.5F, @color.Color::white())
  debug_inspect(asset.buffer().list_positions().length(), content="6")
  asset.cross_2d(@sprite.Isometry2d::identity(), 0.5F, @color.Color::white())
  debug_inspect(asset.buffer().list_positions().length(), content="10")
}

///|
test "retained gizmo circle builder flushes with Bevy resolution semantics" {
  let asset = @gizmos.GizmoAsset::default()
  ignore(
    asset
    .circle_2d(@sprite.Isometry2d::identity(), 1.0F, @color.Color::white())
    .resolution(8),
  )
  debug_inspect(asset.buffer().strip_positions().length(), content="10")
  asset.clear()
  ignore(
    asset.ellipse(
      @math.Isometry3d::identity(),
      @math.Vec2::new(2.0F, 1.0F),
      @color.Color::white(),
    ),
  )
  asset.line(
    @math.Vec3::zero(),
    @math.Vec3::new(1.0F, 0.0F, 0.0F),
    @color.Color::white(),
  )
  debug_inspect(asset.buffer().strip_positions().length(), content="34")
  debug_inspect(asset.buffer().list_positions().length(), content="2")
}

///|
test "retained gizmo arc builders flush in Bevy call order" {
  let asset = @gizmos.GizmoAsset::default()
  ignore(
    asset
    .arc_2d(
      @sprite.Isometry2d::identity(),
      3.141592653589793F,
      1.0F,
      @color.Color::white(),
    )
    .resolution(4),
  )
  ignore(
    asset
    .circle_2d(@sprite.Isometry2d::identity(), 1.0F, @color.Color::white())
    .resolution(3),
  )
  let strip = asset.buffer().strip_positions()
  debug_inspect(strip.length(), content="11")
  debug_inspect(strip[0].y, content="1")
  asset.clear()
  ignore(
    asset
    .arc_3d(
      3.141592653589793F,
      1.0F,
      @math.Isometry3d::identity(),
      @color.Color::white(),
    )
    .resolution(4),
  )
  debug_inspect(asset.buffer().strip_positions().length(), content="6")
}

///|
test "retained gizmo short and long arc helpers mirror Bevy builders" {
  let asset = @gizmos.GizmoAsset::default()
  ignore(
    asset
    .short_arc_2d_between(
      @math.Vec2::zero(),
      @math.Vec2::new(1.0F, 0.0F),
      @math.Vec2::new(0.0F, 1.0F),
      @color.Color::white(),
    )
    .resolution(4),
  )
  let short_2d = asset.buffer().strip_positions()
  debug_inspect(short_2d.length(), content="6")
  debug_inspect(short_2d[0].x, content="1")
  debug_inspect(
    short_2d[0].y > -0.0001F && short_2d[0].y < 0.0001F,
    content="true",
  )

  asset.clear()
  ignore(
    asset
    .long_arc_2d_between(
      @math.Vec2::zero(),
      @math.Vec2::new(1.0F, 0.0F),
      @math.Vec2::new(0.0F, 1.0F),
      @color.Color::white(),
    )
    .resolution(4),
  )
  debug_inspect(asset.buffer().strip_positions().length(), content="6")

  asset.clear()
  ignore(
    asset
    .short_arc_3d_between(
      @math.Vec3::zero(),
      @math.Vec3::new(1.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
      @color.Color::white(),
    )
    .resolution(4),
  )
  debug_inspect(asset.buffer().strip_positions().length(), content="6")

  asset.clear()
  ignore(
    asset
    .long_arc_3d_between(
      @math.Vec3::zero(),
      @math.Vec3::new(1.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
      @color.Color::white(),
    )
    .resolution(4),
  )
  debug_inspect(asset.buffer().strip_positions().length(), content="6")
}

///|
test "retained gizmo sphere builder draws three Bevy great circles" {
  let asset = @gizmos.GizmoAsset::default()
  ignore(
    asset
    .sphere(@math.Isometry3d::identity(), 1.0F, @color.Color::white())
    .resolution(4),
  )
  debug_inspect(asset.buffer().strip_positions().length(), content="18")
  asset.clear()
  ignore(
    asset
    .circle(@math.Isometry3d::identity(), 1.0F, @color.Color::white())
    .resolution(4),
  )
  ignore(
    asset
    .sphere(@math.Isometry3d::identity(), 1.0F, @color.Color::white())
    .resolution(3),
  )
  let strip = asset.buffer().strip_positions()
  debug_inspect(strip.length(), content="21")
  debug_inspect(strip[0].x, content="1")
  debug_inspect(strip[0].y > -0.0001F && strip[0].y < 0.0001F, content="true")
}

///|
test "retained gizmo arrow builders mirror Bevy tips and axes helpers" {
  let asset = @gizmos.GizmoAsset::default()
  ignore(
    asset.arrow(
      @math.Vec3::zero(),
      @math.Vec3::new(1.0F, 0.0F, 0.0F),
      @color.Color::white(),
    ),
  )
  debug_inspect(asset.buffer().list_positions().length(), content="10")

  asset.clear()
  ignore(
    asset
    .arrow(
      @math.Vec3::zero(),
      @math.Vec3::new(1.0F, 0.0F, 0.0F),
      @color.Color::white(),
    )
    .with_tip_length(0.25F)
    .with_double_end(),
  )
  debug_inspect(asset.buffer().list_positions().length(), content="18")

  asset.clear()
  ignore(
    asset.arrow_2d(
      @math.Vec2::zero(),
      @math.Vec2::new(1.0F, 0.0F),
      @color.Color::white(),
    ),
  )
  debug_inspect(asset.buffer().list_positions().length(), content="10")

  asset.clear()
  asset.axes(@math.Isometry3d::identity(), 1.0F)
  debug_inspect(asset.buffer().list_positions().length(), content="30")

  asset.clear()
  asset.axes_2d(@math.Isometry3d::identity(), 1.0F)
  debug_inspect(asset.buffer().list_positions().length(), content="20")
}
