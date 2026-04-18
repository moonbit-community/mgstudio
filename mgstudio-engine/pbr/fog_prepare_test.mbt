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
test "pbr fog: bridge prepares view fog uniforms from DistanceFog component" {
  let world = @ecs.World::new()
  let with_fog = world.spawn()
  let without_fog = world.spawn()
  try! (world.set_by_key(
    with_fog,
    ecs_key_distance_fog,
    DistanceFog::new(@sprite.Color::white(), FogFalloff3d::exponential(0.1F)),
  )
  |> ignore)

  let fog_meta = @pbr_render.FogMeta::default()
  let offsets = render3d_prepare_camera_fog_uniforms(
    world,
    [with_fog, without_fog],
    fog_meta,
  )
  inspect(offsets.length(), content="2")
  inspect(fog_meta.len(), content="2")

  let (_, with_offset) = offsets[0]
  let (_, without_offset) = offsets[1]
  let with_gpu_fog = match fog_meta.fog_at(with_offset.offset()) {
    Some(v) => v
    None => abort("missing fog entry for first camera")
  }
  let without_gpu_fog = match fog_meta.fog_at(without_offset.offset()) {
    Some(v) => v
    None => abort("missing fog entry for second camera")
  }
  inspect(with_gpu_fog.mode(), content="2")
  inspect(without_gpu_fog.mode(), content="0")
}
