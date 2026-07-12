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
priv enum WorldStatus {
  Active
  Closing
  Closed
}

///|
priv struct WorldLifecycle {
  world_id : Int
  mut epoch : Int
  mut status : WorldStatus
}

///|
fn WorldLifecycle::new(world_id : Int) -> WorldLifecycle {
  { world_id, epoch: 0, status: Active }
}

///|
fn WorldLifecycle::is_closed(self : WorldLifecycle) -> Bool {
  self.status is Closed
}

///|
fn WorldLifecycle::close(self : WorldLifecycle) -> Unit {
  guard self.status is Active else { return }
  self.status = Closing
  self.epoch = self.epoch + 1
  self.status = Closed
}
