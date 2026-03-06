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
test "linear volume round trips through decibels" {
  let volume = Volume::Linear(0.5F)
  let db = volume.to_decibels()
  let linear = Volume::Decibels(db).to_linear()
  inspect(linear > 0.49F && linear < 0.51F, content="true")
}

///|
test "volume multiplication uses linear domain" {
  let combined = Volume::Linear(0.5F).mul(Volume::Linear(0.25F)).to_linear()
  inspect(combined > 0.12F && combined < 0.13F, content="true")
}
