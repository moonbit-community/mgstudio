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
fn test_prepare_render_asset(
  extracted : Int,
  _id : Int,
  previous : Int?,
) -> Result[Int, PrepareAssetError] {
  if extracted < 0 {
    return Err(RetryNextUpdate("not ready"))
  }
  Ok(extracted + previous.unwrap_or(0))
}

///|
test "render asset prepare: retries queued assets and drops stale queued updates" {
  let extracted : ExtractedAssets[Int] = ExtractedAssets::new()
  extracted.extracted.push((1, 8))
  extracted.added.add(1)
  let render_assets : RenderAssets[Int] = RenderAssets::new()
  render_assets.insert(1, 20)
  let next_frame : PrepareNextFrameAssets[Int] = PrepareNextFrameAssets::new()
  next_frame.push(1, 5)
  next_frame.push(2, -3)
  prepare_render_assets_with(
    extracted,
    render_assets,
    next_frame,
    test_prepare_render_asset,
    fn(_id, _previous) { () },
  )
  debug_inspect(render_assets.get(1).unwrap(), content="8")
  debug_inspect(render_assets.contains(2), content="false")
  debug_inspect(next_frame.len(), content="1")
}

///|
test "render asset prepare: removed assets unload and extracted retry hides previous asset" {
  let extracted : ExtractedAssets[Int] = ExtractedAssets::new()
  extracted.removed.add(4)
  extracted.extracted.push((5, -1))
  extracted.added.add(5)
  let render_assets : RenderAssets[Int] = RenderAssets::new()
  render_assets.insert(4, 40)
  render_assets.insert(5, 50)
  let next_frame : PrepareNextFrameAssets[Int] = PrepareNextFrameAssets::new()
  let unloaded : Array[Int] = []
  prepare_render_assets_with(
    extracted,
    render_assets,
    next_frame,
    test_prepare_render_asset,
    fn(id, previous) {
      unloaded.push(id)
      unloaded.push(previous.unwrap_or(-1))
    },
  )
  debug_inspect(render_assets.contains(4), content="false")
  debug_inspect(render_assets.contains(5), content="false")
  debug_inspect(next_frame.len(), content="1")
  debug_inspect(unloaded, content="[4, 40]")
}

///|
fn test_prepare_erased_render_asset(
  extracted : Int,
  _id : UntypedRenderAssetId,
  previous : Int?,
) -> Result[Int, ErasedPrepareAssetError] {
  if extracted < 0 {
    return Err(RetryNextUpdate("not ready"))
  }
  Ok(extracted + previous.unwrap_or(0))
}

///|
test "erased render asset prepare: mirrors non-erased retry semantics" {
  let extracted : ExtractedAssets[Int] = ExtractedAssets::new()
  extracted.extracted.push((7, -1))
  extracted.added.add(7)
  let render_assets : ErasedRenderAssets[Int] = ErasedRenderAssets::new()
  render_assets.insert(7, 70)
  let next_frame : ErasedPrepareNextFrameAssets[Int] = ErasedPrepareNextFrameAssets::new()
  prepare_erased_render_assets_with(
    extracted,
    render_assets,
    next_frame,
    test_prepare_erased_render_asset,
    fn(_id, _previous) { () },
  )
  debug_inspect(render_assets.contains(7), content="false")
  debug_inspect(next_frame.len(), content="1")
}
