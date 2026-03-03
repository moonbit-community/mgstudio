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
/// Port of `bevy/examples/app/drag_and_drop.rs`.

///|
fn file_drag_and_drop_system(
  reader : @core.MessageReader[@input.FileDragAndDrop],
) -> Unit {
  for event in reader.read() {
    match event {
      @input.FileDragAndDrop::DroppedFile(path) =>
        println("DroppedFile(\"" + path + "\")")
      @input.FileDragAndDrop::HoveredFile(path) =>
        println("HoveredFile(\"" + path + "\")")
      @input.FileDragAndDrop::HoveredFileCanceled =>
        println("HoveredFileCanceled")
    }
  }
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_system_param(file_drag_and_drop_system)
  .run()
}
