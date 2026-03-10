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
test "anti_alias boundary re-exports msaa/fxaa/taa components" {
  let msaa = @anti_alias.Msaa::from_samples(4)
  let fxaa = @anti_alias.Fxaa::default().with_enabled(false)
  let taa = @anti_alias.TemporalAntiAliasing::new(true)
  let jitter = @anti_alias.TemporalJitter::default()
  inspect(msaa.samples(), content="4")
  inspect(fxaa.enabled, content="false")
  inspect(taa.reset, content="true")
  inspect(jitter.offset.x.to_double(), content="0")
  inspect(jitter.offset.y.to_double(), content="0")
}
