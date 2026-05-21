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
test "render uniform: prepares dense dynamic uniform indices" {
  let plugin = UniformComponentPluginState::new("TestUniform")
  let indices = uniform_component_prepare_indices(2)
  debug_inspect(plugin.component_debug_name(), content="\"TestUniform\"")
  debug_inspect(plugin.prepared_count(), content="0")
  debug_inspect(indices, content="[0, 1]")
}
