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
test "reflect boundary maps to any-based runtime reflection" {
  let value = @reflect.reflect(42)
  let as_int : Int? = @reflect.try_to(value)
  let exact : Int = @reflect.to(value)
  inspect((as_int is Some(_)).to_string(), content="true")
  inspect(exact.to_string(), content="42")
}
