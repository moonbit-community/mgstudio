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
test "mip generation compiles pass shader defs through value defines" {
  let source = mip_generation_compile_pipeline_source(
    "rgba8unorm", "FIRST_PASS",
  )
  debug_inspect(source is Some(_), content="true")
  guard source is Some(compiled) else { return }
  debug_inspect(compiled.contains("#ifdef FIRST_PASS"), content="false")
  debug_inspect(compiled.contains("textureSampleLevel(mip_0"), content="true")
  debug_inspect(compiled.contains("textureSampleLevel(mip_6"), content="false")
  debug_inspect(compiled.contains("return result;"), content="true")
}
