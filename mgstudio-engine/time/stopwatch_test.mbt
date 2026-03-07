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
test "stopwatch pause and reset semantics" {
  let sw0 = Stopwatch::new().tick(@core.Duration::from_secs_f32(1.5F))
  inspect(sw0.elapsed().as_millis(), content="1500")
  inspect(sw0.elapsed_secs(), content="1.5")

  let sw1 = sw0.pause().tick(@core.Duration::from_secs(2L))
  inspect(sw1.elapsed().as_millis(), content="1500")
  inspect(sw1.is_paused(), content="true")

  let sw2 = sw1.unpause().tick(@core.Duration::from_millis(500L))
  inspect(sw2.elapsed().as_millis(), content="2000")
  inspect(sw2.elapsed_secs_f64(), content="2")
  inspect(sw2.is_paused(), content="false")

  let sw3 = sw2.reset()
  inspect(sw3.elapsed().as_nanos(), content="0")
}
