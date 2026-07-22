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
fn file_drag_and_drop_system(
  reader : @ecs.MessageReader[@window.FileDragAndDrop],
) -> Unit {
  for event in reader.read() {
    match event {
      DroppedFile(window, path) =>
        println("DroppedFile(window=\{window.id}, \"\{path}\")")
      HoveredFile(window, path) =>
        println("HoveredFile(window=\{window.id}, \"\{path}\")")
      HoveredFileCanceled(window) =>
        println("HoveredFileCanceled(window=\{window.id})")
    }
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_param(Update, file_drag_and_drop_system)
  .run()
}
