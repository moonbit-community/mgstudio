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
  defer world.close()
  let morph_indices = @pbr_render.morph_indices_mut_or_abort(world)
  let morph_uniforms = @pbr_render.morph_uniforms_mut_or_abort(world)
  let prev_contains = Ref(false)
  let current_missing = Ref(false)
  let prev_len = Ref(0)
  let current_len = Ref(0)
  morph_indices.modify(fn(morph_indices_value) {
    morph_uniforms.modify(fn(morph_uniforms_value) {
      morph_indices_value.current.set(7UL, 4U)
      morph_uniforms_value.current_buffer.push(1.0F)
      render3d_extract_morphs(world, morph_indices_value, morph_uniforms_value)
      prev_contains.val = morph_indices_value.prev.get(7UL) is Some(_)
      current_missing.val = morph_indices_value.current.get(7UL) is None
      prev_len.val = morph_uniforms_value.prev_buffer.length()
      current_len.val = morph_uniforms_value.current_buffer.length()
    })
  })
  debug_inspect(prev_contains.val, content="true")
  debug_inspect(current_missing.val, content="true")
  debug_inspect(prev_len.val, content="1")
  debug_inspect(current_len.val, content="0")
}

///|
test "render3d morph runtime: extract writes 256-byte aligned morph weight slab per entity" {
  let world = @ecs.World::new()
  defer world.close()
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    @mesh.Mesh3d::component(),
    @mesh.Mesh3d::new(@asset.Handle::new(11)),
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
  let morph_indices = @pbr_render.morph_indices_mut_or_abort(world)
  let morph_uniforms = @pbr_render.morph_uniforms_mut_or_abort(world)
  let offset_value = Ref(-1)
  let current_len = Ref(0)
  let first_weight_matches = Ref(false)
  let second_weight_matches = Ref(false)
  morph_indices.modify(fn(morph_indices_value) {
    morph_uniforms.modify(fn(morph_uniforms_value) {
      render3d_extract_morphs(world, morph_indices_value, morph_uniforms_value)
      let key_hi = entity.id.reinterpret_as_uint().to_uint64()
      let key_lo = entity.generation.reinterpret_as_uint().to_uint64() &
        0xFFFF_FFFFUL
      let key = (key_hi << 32) | key_lo
      let offset = morph_indices_value.current.get(key).unwrap()
      offset_value.val = offset.reinterpret_as_int()
      current_len.val = morph_uniforms_value.current_buffer.length()
      first_weight_matches.val = morph_runtime_approx_eq(
        morph_uniforms_value.current_buffer[0],
        1.0F / 3.0F,
      )
      second_weight_matches.val = morph_runtime_approx_eq(
        morph_uniforms_value.current_buffer[1],
        2.0F / 3.0F,
      )
    })
  })
  debug_inspect(offset_value.val, content="0")
  debug_inspect(current_len.val, content="64")
  debug_inspect(first_weight_matches.val, content="true")
  debug_inspect(second_weight_matches.val, content="true")
}
