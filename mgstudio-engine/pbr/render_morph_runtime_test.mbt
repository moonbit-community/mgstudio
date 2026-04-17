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
fn morph_runtime_approx_eq(lhs : Float, rhs : Float) -> Bool {
  let delta = lhs - rhs
  if delta < 0.0F {
    -delta < 0.0001F
  } else {
    delta < 0.0001F
  }
}

///|
test "render3d morph runtime: extract swaps previous state and clears current when no morph entities" {
  let world = @ecs.World::new()
  let morph_indices_ref = @pbr_render.morph_indices_ref_or_abort(world)
  let morph_uniforms_ref = @pbr_render.morph_uniforms_ref_or_abort(world)
  morph_indices_ref.val.current.set(7UL, 4U)
  morph_uniforms_ref.val.current_buffer.push(1.0F)
  render3d_extract_morphs(world, morph_indices_ref, morph_uniforms_ref)
  debug_inspect(morph_indices_ref.val.prev.get(7UL) is Some(_), content="true")
  debug_inspect(morph_indices_ref.val.current.get(7UL) is None, content="true")
  debug_inspect(morph_uniforms_ref.val.prev_buffer.length(), content="1")
  debug_inspect(morph_uniforms_ref.val.current_buffer.length(), content="0")
}

///|
test "render3d morph runtime: extract writes 256-byte aligned morph weight slab per entity" {
  let world = @ecs.World::new()
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    Mesh3d::component(),
    Mesh3d::new(@asset.Handle::new(11)),
  )
  try! world.set_by_key(
    entity,
    @mesh.MorphTargetMesh::component(),
    @mesh.MorphTargetMesh::new(@asset.Handle::new(12)),
  )
  try! world.set_by_key(
    entity,
    @animation.AnimationWeights::component(),
    @animation.AnimationWeights::new([1.0F, 2.0F]),
  )
  let morph_indices_ref = @pbr_render.morph_indices_ref_or_abort(world)
  let morph_uniforms_ref = @pbr_render.morph_uniforms_ref_or_abort(world)
  render3d_extract_morphs(world, morph_indices_ref, morph_uniforms_ref)
  let key_hi = entity.id.reinterpret_as_uint().to_uint64()
  let key_lo = entity.generation.reinterpret_as_uint().to_uint64() &
    0xFFFF_FFFFUL
  let key = (key_hi << 32) | key_lo
  let offset = morph_indices_ref.val.current.get(key).unwrap()
  debug_inspect(offset.reinterpret_as_int(), content="0")
  debug_inspect(morph_uniforms_ref.val.current_buffer.length(), content="64")
  debug_inspect(
    morph_runtime_approx_eq(
      morph_uniforms_ref.val.current_buffer[0],
      1.0F / 3.0F,
    ),
    content="true",
  )
  debug_inspect(
    morph_runtime_approx_eq(
      morph_uniforms_ref.val.current_buffer[1],
      2.0F / 3.0F,
    ),
    content="true",
  )
}
