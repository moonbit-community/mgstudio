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
test "pbr light probe: view probe container enforces max probe count" {
  let probes = RenderViewLightProbes::default()
  for i in 0..<16 {
    ignore(probes.push_texture(None))
    probes.push_probe(RenderLightProbe::default())
    i |> ignore
  }
  inspect(probes.texture_count(), content="8")
  inspect(probes.probe_count(), content="8")
}
