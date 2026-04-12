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
test "pbr ssao: quality sample counts follow bevy presets" {
  inspect(ssao_quality_sample_counts(Low), content="(1, 2)")
  inspect(ssao_quality_sample_counts(Medium), content="(2, 2)")
  inspect(ssao_quality_sample_counts(High), content="(3, 3)")
  inspect(ssao_quality_sample_counts(Ultra), content="(9, 3)")
}
