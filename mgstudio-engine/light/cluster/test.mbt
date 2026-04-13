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
// Bevy source: `bevy/crates/bevy_light/src/cluster/assign.rs`.

///|
fn cluster_approx_eq(a : Float, b : Float, eps : Float) -> Bool {
  (a - b).abs() <= eps
}

///|
test "light cluster: calculate_cluster_factors matches bevy perspective formula shape" {
  let factors = calculate_cluster_factors(0.1F, 1000.0F, 24.0F, false)
  inspect(cluster_approx_eq(factors.x, 2.4971933F, 1.0e-5F), content="true")
  inspect(cluster_approx_eq(factors.y, -5.75F, 1.0e-5F), content="true")
}

///|
test "light cluster: calculate_cluster_factors matches bevy orthographic formula shape" {
  let factors = calculate_cluster_factors(0.1F, 1000.0F, 24.0F, true)
  inspect(cluster_approx_eq(factors.x, -0.1F, 1.0e-6F), content="true")
  inspect(cluster_approx_eq(factors.y, -0.0240024F, 1.0e-6F), content="true")
}

///|
test "light cluster: default cluster config uses bevy fixed-z shape" {
  let config = ClusterConfig::default()
  let ok = match config {
    FixedZ(total, z_slices, _, dynamic_resizing) =>
      total == 4096 && z_slices == 24 && dynamic_resizing
    _ => false
  }
  inspect(ok, content="true")
}

///|
test "light cluster: dimensions_for_screen_size matches bevy fixed-z rounding shape" {
  let config = ClusterConfig::default()
  let dimensions = cluster_config_dimensions_for_screen_size(config, 1920, 1080)
  inspect(dimensions.0, content="16")
  inspect(dimensions.1, content="9")
  inspect(dimensions.2, content="24")
}
