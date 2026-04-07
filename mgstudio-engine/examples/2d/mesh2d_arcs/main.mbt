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
const NUM_SLICES : Int = 8

///|
const SPACING_X : Float = 100.0F

///|
const SECTOR_Y : Float = 50.0F

///|
const SEGMENT_Y : Float = -50.0F

///|
const ARC_RADIUS : Float = 40.0F

///|
let draw_bounds_component_registry : Ref[@hashmap.HashMap[String, @any.Any]] = Ref::new(
  @hashmap.HashMap::new(),
)

///|
struct DrawBounds[T] {
  shape : T
}

///|
fn[T] draw_bounds_component_key() -> @ecs.ComponentKey[DrawBounds[T]] {
  let probe : T? = None
  let type_name = @any.of(probe).type_name()
  match draw_bounds_component_registry.val.get(type_name) {
    Some(existing_key) =>
      match existing_key.try_to() {
        Some(key) => key
        None =>
          abort("draw bounds component registry mismatch for \{type_name}")
      }
    None => {
      let key : @ecs.ComponentKey[DrawBounds[T]] = @ecs.register_component(
        debug_name="examples.2d.mesh2d_arcs.\{type_name}",
      )
      draw_bounds_component_registry.val.set(type_name, @any.of(key))
      key
    }
  }
}

///|
pub impl[T] @ecs.Component for DrawBounds[T] with component() {
  draw_bounds_component_key()
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  let setup_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param4(setup),
  )
  let draw_sector_bounds_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param2(draw_sector_bounds),
  )
  let draw_segment_bounds_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param2(draw_segment_bounds),
  )

  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, setup_system)
  .add_systems(
    @app.Update,
    (draw_sector_bounds_system, draw_segment_bounds_system) |> @app.chain(),
  )
  .run()
}

///|
fn int_to_float(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  meshes : @app.ResMut[@asset.Assets[@sprite.Mesh]],
  materials : @app.ResMut[@asset.Assets[@sprite.ColorMaterialAsset]],
) -> Unit {
  let material = @sprite.MeshMaterial2d::new(
    materials.get_ref().val.add(
      @sprite.ColorMaterialAsset::from_image(
        asset_server.get().load("branding/icon.png"),
      ),
    ),
  )
  let offset_x = SPACING_X * int_to_float(NUM_SLICES - 1) / 2.0F

  ignore(
    commands.spawn(
      (
        @sprite.Camera2d::default(),
        @sprite.Camera::new(
          @sprite.Color::new(0.5019608F, 0.5019608F, 0.5019608F, 1.0F),
        ),
      ),
    ),
  )

  for i in 0..<NUM_SLICES {
    let fraction = int_to_float(i + 1) / int_to_float(NUM_SLICES)
    let x = SPACING_X * int_to_float(i) - offset_x

    let sector = @sprite.CircularSector::from_turns(ARC_RADIUS, fraction)
    let sector_angle = -sector.half_angle()
    ignore(
      commands.spawn(
        (
          @sprite.Mesh2d::new(
            meshes.get_ref().val.add(
              @sprite.mesh2d_geometry_circular_sector(
                sector.with_uv_mask_angle(sector_angle),
              ).to_mesh(),
            ),
          ),
          material,
          @transform.Transform::from_xy_rotation_scale(
            @math.Vec2::new(x, SECTOR_Y),
            sector_angle,
            @math.Vec2::new(1.0F, 1.0F),
          ),
          DrawBounds::{ shape: sector },
        ),
      ),
    )

    let segment = @sprite.CircularSegment::from_turns(ARC_RADIUS, fraction)
    let segment_angle = -@math.pi_half()
    ignore(
      commands.spawn(
        (
          @sprite.Mesh2d::new(
            meshes.get_ref().val.add(
              @sprite.mesh2d_geometry_circular_segment(
                segment.with_uv_mask_angle(-segment_angle),
              ).to_mesh(),
            ),
          ),
          material,
          @transform.Transform::from_xy_rotation_scale(
            @math.Vec2::new(x, SEGMENT_Y),
            segment_angle,
            @math.Vec2::new(1.0F, 1.0F),
          ),
          DrawBounds::{ shape: segment },
        ),
      ),
    )
  }
}

///|
fn[T : @math.Bounded2d] draw_bounds(
  query : @ecs.Query[
    (@ecs.Comp[DrawBounds[T]], @ecs.Comp[@transform.GlobalTransform]),
    @ecs.All,
  ],
  gizmos : @sprite.Gizmos[@sprite.DefaultGizmoConfigGroup],
) -> Unit {
  let red = @sprite.Color::new(1.0F, 0.0F, 0.0F, 1.0F)
  let blue = @sprite.Color::new(0.0F, 0.0F, 1.0F, 1.0F)

  try! query.for_each(fn(_entity, data) {
    let (shape, transform) = data
    let world_transform = transform.value().to_transform_approx()
    let translation = @math.Vec2::new(
      world_transform.translation.x,
      world_transform.translation.y,
    )
    let rotation = @math.Rot2::radians(world_transform.rotation_z())
    let isometry = @math.Isometry2d::new(translation, rotation)

    let aabb = shape.value().shape.aabb_2d(isometry)
    gizmos.rect_2d(
      @sprite.Isometry2d::new(aabb.center(), 0.0F),
      aabb.half_size().mul_scalar(2.0F),
      red,
    )

    let bounding_circle = shape.value().shape.bounding_circle(isometry)
    ignore(
      gizmos.circle_2d(
        @sprite.Isometry2d::new(bounding_circle.center, 0.0F),
        bounding_circle.radius(),
        blue,
      ),
    )
  })
}

///|
fn draw_sector_bounds(
  query : @ecs.Query[
    (
      @ecs.Comp[DrawBounds[@sprite.CircularSector]],
      @ecs.Comp[@transform.GlobalTransform],
    ),
    @ecs.All,
  ],
  gizmos : @sprite.Gizmos[@sprite.DefaultGizmoConfigGroup],
) -> Unit {
  draw_bounds(query, gizmos)
}

///|
fn draw_segment_bounds(
  query : @ecs.Query[
    (
      @ecs.Comp[DrawBounds[@sprite.CircularSegment]],
      @ecs.Comp[@transform.GlobalTransform],
    ),
    @ecs.All,
  ],
  gizmos : @sprite.Gizmos[@sprite.DefaultGizmoConfigGroup],
) -> Unit {
  draw_bounds(query, gizmos)
}
