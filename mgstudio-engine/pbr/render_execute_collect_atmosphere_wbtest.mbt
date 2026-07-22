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
fn atmosphere_collect_approx_eq(a : Float, b : Float) -> Bool {
  let delta = if a > b { a - b } else { b - a }
  delta <= 0.0001F
}

///|
#warnings("-unnecessary_annotation")
fn atmosphere_collect_insert_primary_window(
  world : @ecs.World,
  width : Int,
  height : Int,
) -> Unit {
  let window = @window.Window::Window()
  window.resolution.set_physical_resolution(width, height)
  window.resolution.set_scale_factor(1.0F)
  let entity = world.spawn()
  try! (world.set_by_key(entity, @window.ecs_key_window, window) |> ignore)
  try! (world.set_by_key(entity, @window.ecs_key_primary_window, @window.PrimaryWindow::{

  })
  |> ignore)
}

///|
fn atmosphere_collect_attach_render_atmosphere_payload(
  source_world : @ecs.World,
  render_world : @ecs.World,
  camera_entity : @core.Entity,
  atmosphere : Atmosphere,
  atmosphere_global_transform : @transform.GlobalTransform,
  settings : AtmosphereSettings,
) -> @core.Entity {
  let render_entity = render_world.spawn()
  try! (source_world.set_by_key(
    camera_entity,
    @render.ecs_key_render_entity,
    @render.RenderEntity::new(render_entity),
  )
  |> ignore)
  try! (render_world.set_by_key(
    render_entity,
    @pbr_atmosphere.ecs_key_extracted_atmosphere,
    ExtractedAtmosphere(
      atmosphere.inner_radius,
      atmosphere.outer_radius,
      atmosphere.ground_albedo,
      atmosphere.medium,
      atmosphere_global_transform.affine().inverse(),
    ),
  )
  |> ignore)
  try! (render_world.set_by_key(
    render_entity,
    @pbr_atmosphere.GpuAtmosphereSettings::component(),
    @pbr_atmosphere.pbr_gpu_atmosphere_settings(settings),
  )
  |> ignore)
  render_entity
}

///|
test "render3d collect cameras: volumetric fog depth usage is prepared from render world without source mutation" {
  let source_world = @ecs.World::new()
  defer source_world.close()
  atmosphere_collect_insert_primary_window(source_world, 1280, 720)
  let camera_entity = source_world.spawn()
  try! (source_world.set_by_key(camera_entity, ecs_key_camera3d, Camera3d())
  |> ignore)
  try! (source_world.set_by_key(
    camera_entity,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera().with_is_active(true),
  )
  |> ignore)
  try! (source_world.set_by_key(
    camera_entity,
    ecs_key_projection,
    Projection::default(),
  )
  |> ignore)
  try! (source_world.set_by_key(
    camera_entity,
    @transform.ecs_key_transform,
    @transform.Transform::identity(),
  )
  |> ignore)
  try! (source_world.set_by_key(
    camera_entity,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(@transform.Transform::identity()),
  )
  |> ignore)

  let render_world = @ecs.World::new()
  defer render_world.close()
  let render_view = render_world.spawn()
  try! (render_world.set_by_key(
    render_view,
    ecs_key_volumetric_fog,
    VolumetricFog(),
  )
  |> ignore)
  let cameras = @pbr_render.render3d_world_transform_cache_mut(render_world).modify(fn(
      cache,
    ) {
      @pbr_render.render3d_world_transform_cache_begin_frame(cache)
      render3d_execute_collect_cameras(
        source_world,
        render_world,
        cache,
        false,
        false,
        true,
        Forward,
      )
    },
  )

  inspect(cameras.length(), content="1")
  assert_true(cameras[0].payload.depth_texture_usages.has_texture_binding())
  assert_false(
    (try! source_world.get_by_key(camera_entity, ecs_key_camera3d))
    .unwrap()
    .depth_texture_usages()
    .has_texture_binding(),
  )
}

///|
test "render3d collect cameras: atmosphere example keeps Bevy camera and planet transforms" {
  let source_world = @ecs.World::new()
  defer source_world.close()
  atmosphere_collect_insert_primary_window(source_world, 2048, 1024)

  let atmosphere = Atmosphere::earth(@asset.Handle::new(6))
  let atmosphere_entity = source_world.spawn()
  let atmosphere_transform = @transform.Transform::from_xyz(
    0.0F,
    -atmosphere.inner_radius,
    0.0F,
  )
  try! (source_world.set_by_key(
    atmosphere_entity, ecs_key_atmosphere, atmosphere,
  )
  |> ignore)
  try! (source_world.set_by_key(
    atmosphere_entity,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(atmosphere_transform),
  )
  |> ignore)

  let camera_entity = source_world.spawn()
  let camera_transform = @transform.Transform::from_xyz(-2.8F, 0.045F, 0.0F).looking_at(
    @math.Vec3::zero(),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  )
  try! (source_world.set_by_key(camera_entity, ecs_key_camera3d, Camera3d())
  |> ignore)
  try! (source_world.set_by_key(
    camera_entity,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera().with_is_active(true),
  )
  |> ignore)
  try! (source_world.set_by_key(
    camera_entity,
    ecs_key_projection,
    Projection::default(),
  )
  |> ignore)
  try! (source_world.set_by_key(
    camera_entity, @transform.ecs_key_transform, camera_transform,
  )
  |> ignore)
  try! (source_world.set_by_key(
    camera_entity,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(camera_transform),
  )
  |> ignore)
  try! (source_world.set_by_key(
    camera_entity,
    ecs_key_atmosphere_settings,
    AtmosphereSettings(),
  )
  |> ignore)

  let render_world = @ecs.World::new()
  defer render_world.close()
  ignore(
    atmosphere_collect_attach_render_atmosphere_payload(
      source_world,
      render_world,
      camera_entity,
      atmosphere,
      @transform.GlobalTransform::from_transform(atmosphere_transform),
      AtmosphereSettings(),
    ),
  )
  let cameras = @pbr_render.render3d_world_transform_cache_mut(render_world).modify(fn(
      cache,
    ) {
      @pbr_render.render3d_world_transform_cache_begin_frame(cache)
      render3d_execute_collect_cameras(
        source_world,
        render_world,
        cache,
        false,
        false,
        true,
        Forward,
      )
    },
  )

  inspect(cameras.length(), content="1")
  let payload = cameras[0].payload
  inspect(payload.target_size.x, content="2048")
  inspect(payload.target_size.y, content="1024")
  inspect(
    atmosphere_collect_approx_eq(
      payload.transform.translation.x,
      camera_transform.translation.x,
    ),
    content="true",
  )
  inspect(
    atmosphere_collect_approx_eq(
      payload.transform.translation.y,
      camera_transform.translation.y,
    ),
    content="true",
  )
  inspect(
    atmosphere_collect_approx_eq(
      payload.transform.translation.z,
      camera_transform.translation.z,
    ),
    content="true",
  )
  match payload.atmosphere {
    Some(extracted) => {
      let (_scale, _rotation, translation) = extracted.world_to_atmosphere.to_scale_rotation_translation()
      inspect(atmosphere_collect_approx_eq(translation.x, 0.0F), content="true")
      inspect(
        atmosphere_collect_approx_eq(translation.y, atmosphere.inner_radius),
        content="true",
      )
      inspect(atmosphere_collect_approx_eq(translation.z, 0.0F), content="true")
    }
    None => inspect(false, content="true")
  }
}

///|
test "render3d collect cameras: atmosphere default transform follows Bevy on_add hook" {
  let lifecycle_world_278_0 = @ecs.World::new()
  defer lifecycle_world_278_0.close()
  let app = @app.App::new(lifecycle_world_278_0)
    .add_plugins(@transform.TransformPlugin::TransformPlugin())
    .add_plugins(@light.LightPlugin::LightPlugin())
  let source_world = app.world()
  atmosphere_collect_insert_primary_window(source_world, 2048, 1024)

  let atmosphere = Atmosphere::earth(@asset.Handle::new(7))
  let atmosphere_entity = source_world.spawn()
  try! (source_world.set_by_key(
    atmosphere_entity, ecs_key_atmosphere, atmosphere,
  )
  |> ignore)

  let camera_entity = source_world.spawn()
  let camera_transform = @transform.Transform::from_xyz(-2.8F, 0.045F, 0.0F).looking_at(
    @math.Vec3::zero(),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  )
  try! (source_world.set_by_key(camera_entity, ecs_key_camera3d, Camera3d())
  |> ignore)
  try! (source_world.set_by_key(
    camera_entity,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera().with_is_active(true),
  )
  |> ignore)
  try! (source_world.set_by_key(
    camera_entity,
    ecs_key_projection,
    Projection::default(),
  )
  |> ignore)
  try! (source_world.set_by_key(
    camera_entity, @transform.ecs_key_transform, camera_transform,
  )
  |> ignore)
  try! (source_world.set_by_key(
    camera_entity,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(camera_transform),
  )
  |> ignore)
  try! (source_world.set_by_key(
    camera_entity,
    ecs_key_atmosphere_settings,
    AtmosphereSettings(),
  )
  |> ignore)

  let render_world = @ecs.World::new()
  defer render_world.close()
  let atmosphere_global_transform = (try! source_world.get_by_key(
    atmosphere_entity, @transform.ecs_key_global_transform,
  )).unwrap()
  ignore(
    atmosphere_collect_attach_render_atmosphere_payload(
      source_world,
      render_world,
      camera_entity,
      atmosphere,
      atmosphere_global_transform,
      AtmosphereSettings(),
    ),
  )
  let cameras = @pbr_render.render3d_world_transform_cache_mut(render_world).modify(fn(
      cache,
    ) {
      @pbr_render.render3d_world_transform_cache_begin_frame(cache)
      render3d_execute_collect_cameras(
        source_world,
        render_world,
        cache,
        false,
        false,
        true,
        Forward,
      )
    },
  )

  inspect(cameras.length(), content="1")
  match cameras[0].payload.atmosphere {
    Some(extracted) => {
      let (_scale, _rotation, translation) = extracted.world_to_atmosphere.to_scale_rotation_translation()
      inspect(
        atmosphere_collect_approx_eq(translation.y, atmosphere.inner_radius),
        content="true",
      )
    }
    None => inspect(false, content="true")
  }
}

///|
test "render3d collect cameras: default deferred method enables deferred prepass view" {
  let source_world = @ecs.World::new()
  defer source_world.close()
  atmosphere_collect_insert_primary_window(source_world, 1280, 720)

  let camera_entity = source_world.spawn()
  try! (source_world.set_by_key(camera_entity, ecs_key_camera3d, Camera3d())
  |> ignore)
  try! (source_world.set_by_key(
    camera_entity,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera().with_is_active(true),
  )
  |> ignore)
  try! (source_world.set_by_key(
    camera_entity,
    ecs_key_projection,
    Projection::default(),
  )
  |> ignore)
  let camera_transform = @transform.Transform::from_xyz(-2.8F, 0.045F, 0.0F).looking_at(
    @math.Vec3::zero(),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  )
  try! (source_world.set_by_key(
    camera_entity, @transform.ecs_key_transform, camera_transform,
  )
  |> ignore)
  try! (source_world.set_by_key(
    camera_entity,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(camera_transform),
  )
  |> ignore)

  let render_world = @ecs.World::new()
  defer render_world.close()
  let cameras = @pbr_render.render3d_world_transform_cache_mut(render_world).modify(fn(
      cache,
    ) {
      @pbr_render.render3d_world_transform_cache_begin_frame(cache)
      render3d_execute_collect_cameras(
        source_world,
        render_world,
        cache,
        false,
        false,
        true,
        Deferred,
      )
    },
  )

  inspect(cameras.length(), content="1")
  inspect(cameras[0].payload.depth_prepass_enabled, content="true")
  inspect(cameras[0].payload.deferred_prepass_enabled, content="true")
}

///|
test "render3d collect cameras: Bevy component requirements enable prepass views" {
  let source_world = @ecs.World::new()
  defer source_world.close()
  atmosphere_collect_insert_primary_window(source_world, 1280, 720)

  let camera_entity = source_world.spawn()
  try! (source_world.set_by_key(camera_entity, ecs_key_camera3d, Camera3d())
  |> ignore)
  try! (source_world.set_by_key(
    camera_entity,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera().with_is_active(true),
  )
  |> ignore)
  try! (source_world.set_by_key(
    camera_entity,
    ecs_key_projection,
    Projection::default(),
  )
  |> ignore)
  try! (source_world.set_by_key(
    camera_entity,
    @post_process.ScreenSpaceReflections::component(),
    ScreenSpaceReflections(),
  )
  |> ignore)
  try! (source_world.set_by_key(
    camera_entity,
    @post_process.ScreenSpaceAmbientOcclusion::component(),
    ScreenSpaceAmbientOcclusion(),
  )
  |> ignore)
  try! (source_world.set_by_key(camera_entity, ecs_key_msaa, Off) |> ignore)
  try! (source_world.set_by_key(
    camera_entity,
    ecs_key_contact_shadows,
    ContactShadows(),
  )
  |> ignore)
  let camera_transform = @transform.Transform::from_xyz(0.0F, 0.0F, 5.0F).looking_at(
    @math.Vec3::zero(),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  )
  try! (source_world.set_by_key(
    camera_entity, @transform.ecs_key_transform, camera_transform,
  )
  |> ignore)
  try! (source_world.set_by_key(
    camera_entity,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(camera_transform),
  )
  |> ignore)

  let render_world = @ecs.World::new()
  defer render_world.close()
  let cameras = @pbr_render.render3d_world_transform_cache_mut(render_world).modify(fn(
      cache,
    ) {
      @pbr_render.render3d_world_transform_cache_begin_frame(cache)
      render3d_execute_collect_cameras(
        source_world,
        render_world,
        cache,
        false,
        false,
        true,
        Forward,
      )
    },
  )

  inspect(cameras.length(), content="1")
  inspect(cameras[0].payload.depth_prepass_enabled, content="true")
  inspect(cameras[0].payload.normal_prepass_enabled, content="true")
  inspect(cameras[0].payload.deferred_prepass_enabled, content="true")
}
