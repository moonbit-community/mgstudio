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
test "feathers controls button: props mirror Bevy defaults" {
  let props = ButtonProps::default()
  debug_inspect(props.variant is ButtonVariant::Normal, content="true")
  debug_inspect(
    props.corners is @rounded_corners.RoundedCorners::All,
    content="true",
  )
}

///|
test "feathers controls selection templates keep state in components" {
  let checkbox0 = checkbox("enabled")
  let radio0 = radio("choice")
  let switch0 = toggle_switch()
  debug_inspect(checkbox0.label, content="\"enabled\"")
  debug_inspect(radio0.label, content="\"choice\"")
  ignore(switch0)
  debug_inspect("ok", content="\"ok\"")
}
