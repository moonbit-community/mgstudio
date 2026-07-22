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
// Bevy source: `bevy/crates/bevy_light/src/lib.rs::SimulationLightSystems`.

///|
/// System sets used to run light-related systems.
pub(all) enum SimulationLightSystems {
  /// The set that adds AABBs and bounding spheres to clustered objects.
  UpdateBounds
  /// After this set, all lights have been clustered.
  AssignLightsToClusters
  /// After this set, all directional light cascades are up to date.
  UpdateDirectionalLightCascades
  /// After this set, the frusta of shadow-casting point lights, spot lights,
  /// and directional lights are up to date.
  UpdateLightFrusta
  /// System order ambiguities between systems in this set are ignored in Bevy.
  CheckLightVisibility
} derive(Eq, Debug)

///|
pub fn simulation_light_system_set_name(
  stage_set : SimulationLightSystems,
) -> @app.SystemSet {
  match stage_set {
    UpdateBounds =>
      @app.system_set("mgstudio.light.SimulationLightSystems.UpdateBounds")
    AssignLightsToClusters =>
      @app.system_set(
        "mgstudio.light.SimulationLightSystems.AssignLightsToClusters",
      )
    UpdateDirectionalLightCascades =>
      @app.system_set(
        "mgstudio.light.SimulationLightSystems.UpdateDirectionalLightCascades",
      )
    UpdateLightFrusta =>
      @app.system_set("mgstudio.light.SimulationLightSystems.UpdateLightFrusta")
    CheckLightVisibility =>
      @app.system_set(
        "mgstudio.light.SimulationLightSystems.CheckLightVisibility",
      )
  }
}

///|
pub let simulation_light_set_update_bounds : @app.SystemSet = simulation_light_system_set_name(
  UpdateBounds,
)

///|
pub let simulation_light_set_assign_lights_to_clusters : @app.SystemSet = simulation_light_system_set_name(
  AssignLightsToClusters,
)

///|
pub let simulation_light_set_update_directional_light_cascades : @app.SystemSet = simulation_light_system_set_name(
  UpdateDirectionalLightCascades,
)

///|
pub let simulation_light_set_update_light_frusta : @app.SystemSet = simulation_light_system_set_name(
  UpdateLightFrusta,
)

///|
pub let simulation_light_set_check_light_visibility : @app.SystemSet = simulation_light_system_set_name(
  CheckLightVisibility,
)
