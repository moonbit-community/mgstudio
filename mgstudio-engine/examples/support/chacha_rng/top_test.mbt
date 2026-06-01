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
test "chacha8 seed_from_u64 matches tilemap source random ranges" {
  let rng = @chacha_rng.ChaCha8Rng::seed_from_u64(42UL)
  let expected = [
    1, 3, 0, 4, 3, 2, 1, 3, 3, 1, 3, 0, 1, 1, 0, 4, 3, 3, 4, 1, 2, 2, 1, 4, 2, 4,
    3, 2, 4, 3, 1, 0,
  ]
  for i in 0..<expected.length() {
    assert_eq(rng.random_range(5), expected[i])
  }
}

///|
test "chacha8 seed_from_u64 matches source u64 stream" {
  let rng = @chacha_rng.ChaCha8Rng::seed_from_u64(42UL)
  let expected = [
    12578764544318200737UL, 17529487244874322312UL, 7886285670807131020UL, 11572758976476374866UL,
    5323617429756461744UL, 2766252901828231838UL, 5682345367224914708UL, 14828835203913492612UL,
  ]
  for i in 0..<expected.length() {
    assert_eq(rng.next_u64(), expected[i])
  }
}
