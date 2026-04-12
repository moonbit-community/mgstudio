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
test "pbr meshlet: conversion reports runtime unavailable first" {
  let error = meshlet_conversion_error_for_counts(
    10,
    10,
    MeshToMeshletMeshConversionConfig::default(),
  )
  inspect(
    error is Some(MeshToMeshletMeshConversionError::RuntimeUnavailable),
    content="true",
  )
}
