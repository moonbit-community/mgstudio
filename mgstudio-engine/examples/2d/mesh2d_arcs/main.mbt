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
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(mesh2d_arcs_setup))
  .add_systems(@app.Update, @app.system(mesh2d_arcs_draw_bounds))
  .run()
}

///|
const NUM_SLICES : Int = 8

///|
const SPACING_X : Float = 100.0F

///|
const OFFSET_X : Float = 350.0F

///|
const SECTOR_Y : Float = 50.0F

///|
const SEGMENT_Y : Float = -50.0F

///|
const ARC_RADIUS : Float = 40.0F

///|
const BOUNDS_SAMPLES : Int = 96

///|
priv enum ArcShapeKind {
  Sector
  Segment
}

///|
priv struct ArcBoundsSample {
  center : @math.Vec2
  half_angle : Float
  kind : ArcShapeKind
  radius : Float
  rotation : Float
}

///|
priv struct Mesh2dArcsState {
  bounds_samples : Array[ArcBoundsSample]
}

///|
priv struct Aabb2dLite {
  center : @math.Vec2
  size : @math.Vec2
}

///|
let mesh2d_arcs_state : Ref[Mesh2dArcsState] = Ref::new({ bounds_samples: [] })

///|
fn int_to_float(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn spawn_arc_shape(
  world : @ecs.World,
  mesh : @sprite.Mesh2d,
  material : @sprite.MeshMaterial2d[@sprite.ColorMaterialAsset],
  position : @math.Vec2,
  rotation : Float,
) -> Unit {
  let transform = @transform.Transform::from_xy_rotation_scale(
    position,
    rotation,
    @math.Vec2::new(1.0F, 1.0F),
  )
  @sprite.Mesh2dBundle::new_with_mesh_material(mesh, material, transform).spawn(
    world,
  )
  |> ignore
}

///|
fn mesh2d_arcs_setup(world : @ecs.World) -> Unit {
  let camera = @sprite.Camera::new(
    @sprite.Color::new(0.5019608F, 0.5019608F, 0.5019608F, 1.0F),
  )
  @sprite.Camera2dBundle::new(camera, @transform.Transform::identity()).spawn(
    world,
  )
  |> ignore

  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/icon.png")
  let material = @sprite.MeshMaterial2d::new(
    @sprite.color_material_assets_mut_or_abort().val.add(
      @sprite.ColorMaterialAsset::from_image(texture),
    ),
  )

  mesh2d_arcs_state.val.bounds_samples.clear()
  for i in 0..<NUM_SLICES {
    let fraction = int_to_float(i + 1) / int_to_float(NUM_SLICES)
    let x = SPACING_X * int_to_float(i) - OFFSET_X

    let sector = @sprite.CircularSector::from_turns(ARC_RADIUS, fraction).with_vertices(
      BOUNDS_SAMPLES,
    )
    let sector_rotation = -sector.half_angle()
    spawn_arc_shape(
      world,
      @sprite.Mesh2d::new(
        @sprite.mesh_assets_mut_or_abort().val.add(
          @sprite.mesh2d_geometry_circular_sector(
            sector.with_uv_mask_angle(sector_rotation),
          ).to_mesh(),
        ),
      ),
      material,
      @math.Vec2::new(x, SECTOR_Y),
      sector_rotation,
    )
    mesh2d_arcs_state.val.bounds_samples.push({
      center: @math.Vec2::new(x, SECTOR_Y),
      half_angle: sector.half_angle(),
      kind: ArcShapeKind::Sector,
      radius: ARC_RADIUS,
      rotation: sector_rotation,
    })

    let segment = @sprite.CircularSegment::from_turns(ARC_RADIUS, fraction).with_vertices(
      BOUNDS_SAMPLES,
    )
    let segment_rotation = -@math.pi_half()
    spawn_arc_shape(
      world,
      @sprite.Mesh2d::new(
        @sprite.mesh_assets_mut_or_abort().val.add(
          @sprite.mesh2d_geometry_circular_segment(
            segment.with_uv_mask_angle(-segment_rotation),
          ).to_mesh(),
        ),
      ),
      material,
      @math.Vec2::new(x, SEGMENT_Y),
      segment_rotation,
    )
    mesh2d_arcs_state.val.bounds_samples.push({
      center: @math.Vec2::new(x, SEGMENT_Y),
      half_angle: segment.half_angle(),
      kind: ArcShapeKind::Segment,
      radius: ARC_RADIUS,
      rotation: segment_rotation,
    })
  }
}

///|
fn rotate_2d(point : @math.Vec2, angle : Float) -> @math.Vec2 {
  let s = @math.sin(angle)
  let c = @math.cos(angle)
  @math.Vec2::new(point.x * c - point.y * s, point.x * s + point.y * c)
}

///|
fn world_point(
  sample : ArcBoundsSample,
  point_local : @math.Vec2,
) -> @math.Vec2 {
  let rotated = rotate_2d(point_local, sample.rotation)
  @math.Vec2::new(rotated.x + sample.center.x, rotated.y + sample.center.y)
}

///|
fn sample_arc_points(radius : Float, half_angle : Float) -> Array[@math.Vec2] {
  let points : Array[@math.Vec2] = []
  let start = -half_angle
  let angle_span = half_angle * 2.0F
  for i in 0..<(BOUNDS_SAMPLES + 1) {
    let t = int_to_float(i) / int_to_float(BOUNDS_SAMPLES)
    let angle = start + angle_span * t
    points.push(
      @math.Vec2::new(radius * @math.sin(angle), radius * @math.cos(angle)),
    )
  }
  points
}

///|
fn bounds_points_local(sample : ArcBoundsSample) -> Array[@math.Vec2] {
  let points : Array[@math.Vec2] = []
  match sample.kind {
    ArcShapeKind::Sector => points.push(@math.Vec2::new(0.0F, 0.0F))
    ArcShapeKind::Segment => ()
  }
  let arc_points = sample_arc_points(sample.radius, sample.half_angle)
  for point in arc_points {
    points.push(point)
  }
  points
}

///|
fn compute_world_aabb(sample : ArcBoundsSample) -> Aabb2dLite {
  let points = bounds_points_local(sample)
  guard points.length() > 0 else {
    return { center: sample.center, size: @math.Vec2::new(0.0F, 0.0F) }
  }

  let first = world_point(sample, points[0])
  let mut min_x = first.x
  let mut min_y = first.y
  let mut max_x = first.x
  let mut max_y = first.y

  for i in 1..<points.length() {
    let point = world_point(sample, points[i])
    if point.x < min_x {
      min_x = point.x
    }
    if point.y < min_y {
      min_y = point.y
    }
    if point.x > max_x {
      max_x = point.x
    }
    if point.y > max_y {
      max_y = point.y
    }
  }

  {
    center: @math.Vec2::new((min_x + max_x) * 0.5F, (min_y + max_y) * 0.5F),
    size: @math.Vec2::new(max_x - min_x, max_y - min_y),
  }
}

///|
fn mesh2d_arcs_draw_bounds(_world : @ecs.World) -> Unit {
  let red = @sprite.Color::new(1.0F, 0.0F, 0.0F, 1.0F)
  let blue = @sprite.Color::new(0.0F, 0.0F, 1.0F, 1.0F)
  let gizmos = @sprite.Gizmos::new()
  for sample in mesh2d_arcs_state.val.bounds_samples {
    let aabb = compute_world_aabb(sample)
    gizmos.rect_2d(@sprite.Isometry2d::new(aabb.center, 0.0F), aabb.size, red)
    gizmos.circle_2d(
      @sprite.Isometry2d::new(sample.center, 0.0F),
      sample.radius,
      blue,
    )
    |> ignore
  }
}
