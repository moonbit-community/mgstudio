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
test "core_pipeline boundary re-exports prepass markers and msaa" {
  let depth = @core_pipeline.DepthPrepass::default()
  let normal = @core_pipeline.NormalPrepass::default()
  let motion = @core_pipeline.MotionVectorPrepass::default()
  let deferred = @core_pipeline.DeferredPrepass::default()
  let hdr = @core_pipeline.Hdr::default()
  debug_inspect(depth.to_json().to_string(), content="\"Object({})\"")
  debug_inspect(normal.to_json().to_string(), content="\"Object({})\"")
  debug_inspect(motion.to_json().to_string(), content="\"Object({})\"")
  debug_inspect(deferred.to_json().to_string(), content="\"Object({})\"")
  debug_inspect(hdr.to_json().to_string(), content="\"Object({})\"")
  debug_inspect(@core_pipeline.Msaa::from_samples(4).samples(), content="4")
}

///|
test "mip_generation plugin initializes downsample shader registry resource" {
  let app = @app.App::new(@ecs.World::new()).add_plugin(
    @mip_generation.mip_generation_plugin,
  )
  let render_world = app.get_sub_app(@app.RenderApp).unwrap().world()
  let shaders = try! render_world
    .get_resource(@mip_generation.ecs_key_downsample_shaders)
    .unwrap()
  debug_inspect(
    shaders.depth_shader_path(),
    content="\"core_pipeline/mip_generation/experimental/downsample_depth.wgsl\"",
  )
  debug_inspect(shaders.general_shader_count(), content="40")
}

///|
test "mip_generation texture format table follows bevy list shape" {
  let formats = @mip_generation.downsample_texture_formats()
  debug_inspect(formats.length(), content="40")
  debug_inspect(formats[0], content="(\"Rgba8Unorm\", \"rgba8unorm\")")
  debug_inspect(
    formats[formats.length() - 1],
    content="(\"Rg11b10Ufloat\", \"rg11b10ufloat\")",
  )
}

///|
test "mip_generation plugin initializes finish-stage resources in render sub-app" {
  let app = @app.App::new(@ecs.World::new())
    .add_plugin_typed(@mip_generation.MipGenerationPlugin::default())
    .finish()
  let render_world = app.get_sub_app(@app.RenderApp).unwrap().world()
  let resources = try! render_world
    .get_resource(@mip_generation.ecs_key_mip_generation_resources)
    .unwrap()
  debug_inspect(resources.sampler_label(), content="\"mip generation sampler\"")
  debug_inspect(resources.mag_filter(), content="\"Linear\"")
  debug_inspect(resources.min_filter(), content="\"Linear\"")
  debug_inspect(resources.mipmap_filter(), content="\"Nearest\"")
}

///|
priv struct CameraDriverScheduleProbe {
  mut run_count : Int
}

///|
let camera_driver_schedule_probe_key : @ecs.ResourceKey[
  CameraDriverScheduleProbe,
] = @ecs.register_resource(
  debug_name="core_pipeline.test.camera_driver_schedule_probe",
)

///|
fn camera_driver_probe_tick(world : @ecs.World) -> Unit {
  if world.resource(camera_driver_schedule_probe_key).get() is Some(probe) {
    probe.run_count = probe.run_count + 1
  }
}

///|
test "camera_driver runs core pipeline camera schedules" {
  let app = @app.App::new(@ecs.World::new()).add_plugin(
    @core_pipeline.core_pipeline_plugin,
  )
  if app.get_sub_app_mut(@app.RenderApp) is Some(render_sub_app_ref) {
    let render_sub_app = render_sub_app_ref.val
    render_sub_app
    .world()
    .insert_resource(camera_driver_schedule_probe_key, CameraDriverScheduleProbe::{
      run_count: 0,
    })
    render_sub_app_ref.val = render_sub_app.add_systems(
      @app.schedule_label(@core_pipeline.CORE_2D_SCHEDULE_LABEL),
      @app.system(camera_driver_probe_tick),
    )
  }
  let app = app.update()
  let render_world = app.get_sub_app(@app.RenderApp).unwrap().world()
  let probe = try! render_world
    .get_resource(camera_driver_schedule_probe_key)
    .unwrap()
  debug_inspect(probe.run_count, content="1")
}
