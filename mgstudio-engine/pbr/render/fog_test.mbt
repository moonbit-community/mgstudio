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
test "pbr render fog: gpu fog mode follows fog falloff variant" {
  let linear = render3d_gpu_fog_from_view_fog(
    Render3dViewFogData::new(
      @sprite.Color::white(),
      @sprite.Color::new(0.0F, 0.0F, 0.0F, 0.0F),
      8.0F,
      Render3dFogFalloff::linear(2.0F, 30.0F),
    ),
  )
  let exponential = render3d_gpu_fog_from_view_fog(
    Render3dViewFogData::new(
      @sprite.Color::white(),
      @sprite.Color::new(0.0F, 0.0F, 0.0F, 0.0F),
      8.0F,
      Render3dFogFalloff::exponential(0.2F),
    ),
  )
  let atmospheric = render3d_gpu_fog_from_view_fog(
    Render3dViewFogData::new(
      @sprite.Color::white(),
      @sprite.Color::new(0.0F, 0.0F, 0.0F, 0.0F),
      8.0F,
      Render3dFogFalloff::atmospheric(
        @math.Vec3::new(0.1F, 0.2F, 0.3F),
        @math.Vec3::new(0.4F, 0.5F, 0.6F),
      ),
    ),
  )

  inspect(linear.mode(), content="1")
  inspect(exponential.mode(), content="2")
  inspect(atmospheric.mode(), content="4")
}

///|
test "pbr render fog: prepare writes offsets and off mode for missing fog" {
  let with_fog = @core.Entity::new(7, 0)
  let without_fog = @core.Entity::new(8, 0)
  let meta = FogMeta::default()
  let offsets = render3d_prepare_fog_uniforms(
    [
      (
        with_fog,
        Some(
          Render3dViewFogData::new(
            @sprite.Color::white(),
            @sprite.Color::new(0.0F, 0.0F, 0.0F, 0.0F),
            8.0F,
            Render3dFogFalloff::exponential_squared(0.05F),
          ),
        ),
      ),
      (without_fog, None),
    ],
    meta,
  )
  inspect(offsets.length(), content="2")
  inspect(meta.len(), content="2")

  let (_, first_offset) = offsets[0]
  let (_, second_offset) = offsets[1]
  let first_fog = match meta.fog_at(first_offset.offset()) {
    Some(v) => v
    None => abort("missing first fog uniform")
  }
  let second_fog = match meta.fog_at(second_offset.offset()) {
    Some(v) => v
    None => abort("missing second fog uniform")
  }
  inspect(first_fog.mode(), content="3")
  inspect(second_fog.mode(), content="0")
}

///|
test "pbr render fog: apply offsets writes component and meta resource initializes" {
  let world = @ecs.World::new()
  let fog_meta_ref = render3d_fog_meta_ref_or_init(world)
  inspect(fog_meta_ref.val.len(), content="0")

  let entity = world.spawn_empty()
  let offsets = render3d_prepare_fog_uniforms(
    [
      (
        entity,
        Some(
          Render3dViewFogData::new(
            @sprite.Color::white(),
            @sprite.Color::new(0.0F, 0.0F, 0.0F, 0.0F),
            8.0F,
            Render3dFogFalloff::exponential(0.25F),
          ),
        ),
      ),
    ],
    fog_meta_ref.val,
  )
  render3d_apply_view_fog_uniform_offsets(world, offsets)
  let inserted = match
    (try! world.get_by_key(entity, ecs_key_view_fog_uniform_offset)) {
    Some(v) => v
    None => abort("missing view fog uniform offset component")
  }
  inspect(inserted.offset(), content="0")
  inspect(fog_meta_ref.val.len(), content="1")
}
