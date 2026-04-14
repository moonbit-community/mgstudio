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

// Bevy source: `bevy/crates/bevy_pbr/src/render/fog.rs`.

///|
pub const RENDER3D_GPU_FOG_MODE_OFF : UInt = 0U

///|
pub const RENDER3D_GPU_FOG_MODE_LINEAR : UInt = 1U

///|
pub const RENDER3D_GPU_FOG_MODE_EXPONENTIAL : UInt = 2U

///|
pub const RENDER3D_GPU_FOG_MODE_EXPONENTIAL_SQUARED : UInt = 3U

///|
pub const RENDER3D_GPU_FOG_MODE_ATMOSPHERIC : UInt = 4U

///|
pub struct GpuFog3d {
  base_color : @math.Vec4
  directional_light_color : @math.Vec4
  be : @math.Vec3
  directional_light_exponent : Float
  bi : @math.Vec3
  mode : UInt
} derive(ToJson, FromJson)

///|
pub fn GpuFog3d::default() -> GpuFog3d {
  GpuFog3d::{
    base_color: @math.Vec4::new(0.0F, 0.0F, 0.0F, 0.0F),
    directional_light_color: @math.Vec4::new(0.0F, 0.0F, 0.0F, 0.0F),
    be: @math.Vec3::new(0.0F, 0.0F, 0.0F),
    directional_light_exponent: 0.0F,
    bi: @math.Vec3::new(0.0F, 0.0F, 0.0F),
    mode: RENDER3D_GPU_FOG_MODE_OFF,
  }
}

///|
pub fn GpuFog3d::off() -> GpuFog3d {
  GpuFog3d::default()
}

///|
pub fn GpuFog3d::mode(self : GpuFog3d) -> UInt {
  self.mode
}

///|
pub fn GpuFog3d::base_color(self : GpuFog3d) -> @math.Vec4 {
  self.base_color
}

///|
pub fn GpuFog3d::directional_light_color(self : GpuFog3d) -> @math.Vec4 {
  self.directional_light_color
}

///|
pub fn GpuFog3d::be(self : GpuFog3d) -> @math.Vec3 {
  self.be
}

///|
pub fn GpuFog3d::bi(self : GpuFog3d) -> @math.Vec3 {
  self.bi
}

///|
pub fn GpuFog3d::directional_light_exponent(self : GpuFog3d) -> Float {
  self.directional_light_exponent
}

///|
pub struct ViewFogUniformOffset {
  offset : UInt
} derive(ToJson, FromJson)

///|
pub let ecs_key_view_fog_uniform_offset : @ecs.ComponentKey[
  ViewFogUniformOffset,
] = @ecs.register_component(
  debug_name="mgstudio.pbr.render.view_fog_uniform_offset",
)

///|
pub fn ViewFogUniformOffset::new(offset : UInt) -> ViewFogUniformOffset {
  ViewFogUniformOffset::{ offset, }
}

///|
pub fn ViewFogUniformOffset::offset(self : ViewFogUniformOffset) -> UInt {
  self.offset
}

///|
pub impl @ecs.Component for ViewFogUniformOffset with component() {
  ecs_key_view_fog_uniform_offset
}

///|
pub struct FogMeta {
  fogs : Array[GpuFog3d]
}

///|
let fog_meta_resource_key : @ecs.ResourceKey[FogMeta] = @ecs.register_resource(
  debug_name="mgstudio.pbr.render.FogMeta",
)

///|
pub impl @app.Resource for FogMeta with resource() {
  fog_meta_resource_key
}

///|
pub fn FogMeta::default() -> FogMeta {
  FogMeta::{ fogs: [] }
}

///|
pub fn FogMeta::clear(self : FogMeta) -> Unit {
  self.fogs.clear()
}

///|
pub fn FogMeta::push(self : FogMeta, fog : GpuFog3d) -> UInt {
  let offset = self.fogs.length().reinterpret_as_uint()
  self.fogs.push(fog)
  offset
}

///|
pub fn FogMeta::len(self : FogMeta) -> Int {
  self.fogs.length()
}

///|
pub fn FogMeta::fog_at(self : FogMeta, offset : UInt) -> GpuFog3d? {
  let index = offset.reinterpret_as_int()
  if index < 0 || index >= self.fogs.length() {
    None
  } else {
    Some(self.fogs[index])
  }
}

///|
fn render3d_color_to_vec4(color : @sprite.Color) -> @math.Vec4 {
  @math.Vec4::new(color.r, color.g, color.b, color.a)
}

///|
pub enum Render3dFogFalloff {
  Linear(Float, Float)
  Exponential(Float)
  ExponentialSquared(Float)
  Atmospheric(@math.Vec3, @math.Vec3)
} derive(ToJson, FromJson)

///|
pub fn Render3dFogFalloff::linear(
  start : Float,
  end_ : Float,
) -> Render3dFogFalloff {
  Render3dFogFalloff::Linear(start, end_)
}

///|
pub fn Render3dFogFalloff::exponential(density : Float) -> Render3dFogFalloff {
  Render3dFogFalloff::Exponential(density)
}

///|
pub fn Render3dFogFalloff::exponential_squared(
  density : Float,
) -> Render3dFogFalloff {
  Render3dFogFalloff::ExponentialSquared(density)
}

///|
pub fn Render3dFogFalloff::atmospheric(
  extinction : @math.Vec3,
  inscattering : @math.Vec3,
) -> Render3dFogFalloff {
  Render3dFogFalloff::Atmospheric(extinction, inscattering)
}

///|
pub struct Render3dViewFogData {
  color : @sprite.Color
  directional_light_color : @sprite.Color
  directional_light_exponent : Float
  falloff : Render3dFogFalloff
} derive(ToJson, FromJson)

///|
pub fn Render3dViewFogData::new(
  color : @sprite.Color,
  directional_light_color : @sprite.Color,
  directional_light_exponent : Float,
  falloff : Render3dFogFalloff,
) -> Render3dViewFogData {
  Render3dViewFogData::{
    color,
    directional_light_color,
    directional_light_exponent,
    falloff,
  }
}

///|
pub fn render3d_gpu_fog_from_view_fog(fog : Render3dViewFogData) -> GpuFog3d {
  let base_color = render3d_color_to_vec4(fog.color)
  let directional_light_color = render3d_color_to_vec4(
    fog.directional_light_color,
  )
  match fog.falloff {
    Render3dFogFalloff::Linear(start, end_) =>
      GpuFog3d::{
        ..GpuFog3d::default(),
        mode: RENDER3D_GPU_FOG_MODE_LINEAR,
        base_color,
        directional_light_color,
        directional_light_exponent: fog.directional_light_exponent,
        be: @math.Vec3::new(start, end_, 0.0F),
      }
    Render3dFogFalloff::Exponential(density) =>
      GpuFog3d::{
        ..GpuFog3d::default(),
        mode: RENDER3D_GPU_FOG_MODE_EXPONENTIAL,
        base_color,
        directional_light_color,
        directional_light_exponent: fog.directional_light_exponent,
        be: @math.Vec3::new(density, 0.0F, 0.0F),
      }
    Render3dFogFalloff::ExponentialSquared(density) =>
      GpuFog3d::{
        ..GpuFog3d::default(),
        mode: RENDER3D_GPU_FOG_MODE_EXPONENTIAL_SQUARED,
        base_color,
        directional_light_color,
        directional_light_exponent: fog.directional_light_exponent,
        be: @math.Vec3::new(density, 0.0F, 0.0F),
      }
    Render3dFogFalloff::Atmospheric(extinction, inscattering) =>
      GpuFog3d::{
        mode: RENDER3D_GPU_FOG_MODE_ATMOSPHERIC,
        base_color,
        directional_light_color,
        be: extinction,
        directional_light_exponent: fog.directional_light_exponent,
        bi: inscattering,
      }
  }
}

///|
pub fn render3d_prepare_fog_uniforms(
  view_fogs : Array[(@core.Entity, Render3dViewFogData?)],
  fog_meta : FogMeta,
) -> Array[(@core.Entity, ViewFogUniformOffset)] {
  fog_meta.clear()
  let offsets = []
  for item in view_fogs {
    let (entity, fog) = item
    let gpu_fog = match fog {
      Some(value) => render3d_gpu_fog_from_view_fog(value)
      None => GpuFog3d::off()
    }
    let offset = fog_meta.push(gpu_fog)
    offsets.push((entity, ViewFogUniformOffset::new(offset)))
  }
  offsets
}

///|
pub fn render3d_fog_meta_ref_or_init(world : @ecs.World) -> Ref[FogMeta] {
  if (try! world.get_resource(FogMeta::resource())) is None {
    world.insert_resource(FogMeta::resource(), FogMeta::default())
  }
  match (try! world.get_resource_ref_mut(FogMeta::resource())) {
    Some(value) => value
    None => abort("missing FogMeta resource")
  }
}

///|
pub fn render3d_apply_view_fog_uniform_offsets(
  world : @ecs.World,
  offsets : Array[(@core.Entity, ViewFogUniformOffset)],
) -> Unit {
  for item in offsets {
    let (entity, offset) = item
    if !world.is_alive(entity) {
      continue
    }
    try
      world.set_by_key(entity, ecs_key_view_fog_uniform_offset, offset)
    catch {
      _ => ()
    } noraise {
      _ => ()
    }
  }
}

///|
const FOG_FALLOFF_E : Float = 2.718281828459045F

///|
fn render3d_fog_sanitize_distance(distance : Float) -> Float {
  if distance < 0.0F {
    0.0F
  } else {
    distance
  }
}

///|
fn render3d_fog_sanitize_density(density : Float) -> Float {
  if density < 0.0F {
    0.0F
  } else {
    density
  }
}

///|
pub fn render3d_fog_pow_e(value : Float) -> Float {
  @math.pow(FOG_FALLOFF_E, value)
}

///|
pub fn render3d_fog_channel_factor(density : Float, distance : Float) -> Float {
  let safe_density = render3d_fog_sanitize_density(density)
  let safe_distance = render3d_fog_sanitize_distance(distance)
  1.0F - render3d_fog_pow_e(-(safe_density * safe_distance))
}

///|
pub fn render3d_fog_linear_factor(
  start : Float,
  end_ : Float,
  distance : Float,
) -> Float {
  let safe_distance = render3d_fog_sanitize_distance(distance)
  let safe_start = if start < 0.0F { 0.0F } else { start }
  let safe_end = if end_ < safe_start { safe_start } else { end_ }
  if safe_end <= safe_start {
    if safe_distance >= safe_end {
      1.0F
    } else {
      0.0F
    }
  } else if safe_distance <= safe_start {
    0.0F
  } else if safe_distance >= safe_end {
    1.0F
  } else {
    (safe_distance - safe_start) / (safe_end - safe_start)
  }
}

///|
pub fn render3d_fog_exponential_factor(
  density : Float,
  distance : Float,
) -> Float {
  render3d_fog_channel_factor(density, distance)
}

///|
pub fn render3d_fog_exponential_squared_factor(
  density : Float,
  distance : Float,
) -> Float {
  let safe_density = render3d_fog_sanitize_density(density)
  let safe_distance = render3d_fog_sanitize_distance(distance)
  let d = safe_density * safe_distance
  1.0F - render3d_fog_pow_e(-(d * d))
}

///|
pub fn render3d_fog_atmospheric_presence(
  extinction : @math.Vec3,
  inscattering : @math.Vec3,
  distance : Float,
) -> Float {
  let extinction_max = maxf(maxf(extinction.x, extinction.y), extinction.z)
  let inscattering_max = maxf(
    maxf(inscattering.x, inscattering.y),
    inscattering.z,
  )
  let extinction_factor = render3d_fog_channel_factor(extinction_max, distance)
  let inscattering_factor = render3d_fog_channel_factor(
    inscattering_max, distance,
  )
  clamp01((extinction_factor + inscattering_factor) * 0.5F)
}

///|
pub fn render3d_fog_directional_mix(
  directional_light_alpha : Float,
  directional_light_exponent : Float,
  directional_dir : @math.Vec3,
  directional_illuminance : Float,
  fog_presence : Float,
  camera_position : @math.Vec3,
  mesh_position : @math.Vec3,
) -> Float {
  let safe_alpha = clamp01(directional_light_alpha)
  if safe_alpha <= 0.0F {
    return 0.0F
  }
  if directional_light_exponent <= 0.0F {
    return 0.0F
  }
  if directional_illuminance <= 0.0F {
    return 0.0F
  }

  let view_direction = mesh_position.sub(camera_position).normalize_or_zero()
  let light_direction = directional_dir.neg().normalize_or_zero()
  let alignment = clamp01(light_direction.dot(view_direction) * 0.5F + 0.5F)
  let phase = @math.pow(alignment, directional_light_exponent)
  let illuminance_mix = clamp01(directional_illuminance / 50_000.0F)
  clamp01(phase * safe_alpha * illuminance_mix * fog_presence)
}
