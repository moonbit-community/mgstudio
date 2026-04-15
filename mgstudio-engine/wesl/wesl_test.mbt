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
test "wesl: module path from filesystem path follows Bevy semantics" {
  let absolute = ModulePath::from_path("/shaders/custom_material.wesl")
  let relative = ModulePath::from_path("../util.wesl")
  let package_path = ModulePath::from_path("mgstudio/shaders/util.wesl")

  debug_inspect(
    absolute.to_string(),
    content="\"package::shaders::custom_material\"",
  )
  debug_inspect(relative.to_string(), content="\"super::util\"")
  debug_inspect(package_path.to_string(), content="\"mgstudio::shaders::util\"")
}

///|
test "wesl: module path join matches relative import semantics" {
  let parent = try! parse_module_path("package::shaders")
  let child = try! parse_module_path("super::util")

  debug_inspect(
    parent.join_path(child).to_string(),
    content="\"package::util\"",
  )
}

///|
test "wesl: escape mangler matches Bevy naming" {
  let mangler = EscapeMangler::default()
  let package_path = try! parse_module_path("package::bevy_pbr::lighting")
  let slash_path = try! parse_module_path("bevy/pbr::lighting")

  debug_inspect(
    EscapeMangler::mangle(mangler, package_path, "item"),
    content="\"package__1bevy_pbr_lighting_item\"",
  )
  debug_inspect(
    EscapeMangler::mangle(mangler, slash_path, "item"),
    content="\"import_2_bevy_pbr_lighting_item\"",
  )
}

///|
test "wesl: compile resolves imports and conditional translation" {
  let resolver = VirtualResolver::new()
  let util_path = ModulePath::from_path("/shaders/util")
  let root_path = ModulePath::from_path("/shaders/custom_material")
  resolver.add_module(
    util_path, "fn make_polka_dots(v: f32) -> f32 {\n  @if(PARTY_MODE) {\n    return v * 2.0;\n  } @else {\n    return v;\n  }\n}\n",
  )
  resolver.add_module(
    root_path, "import super::util::make_polka_dots;\nfn fragment(v: f32) -> f32 {\n  return make_polka_dots(v);\n}\n",
  )
  let options = CompileOptions::default()
    .with_lower(true)
    .with_feature("PARTY_MODE", true)
  let compiled = compile(root_path, resolver, EscapeMangler::default(), options)

  debug_inspect(
    compiled.to_string(),
    content="\"fn package_shaders_util__2make_polka_dots(v: f32) -> f32 {\\n  \\n    return v * 2.0;\\n  \\n}\\n\\nfn fragment(v: f32) -> f32 {\\n  return package_shaders_util__2make_polka_dots(v);\\n}\"",
  )
}

///|
test "wesl: missing imported module stays resolver-backed" {
  let resolver = VirtualResolver::new()
  let root_path = ModulePath::from_path("/shaders/root")
  resolver.add_module(
    root_path, "import super::missing::make_it;\nfn fragment() {}\n",
  )
  let result = try? compile(
    root_path,
    resolver,
    EscapeMangler::default(),
    CompileOptions::default(),
  )

  match result {
    Err(WeslCompileError::Resolve(ResolveError::ModuleNotFound(path, context))) => {
      debug_inspect(path.to_string(), content="\"package::shaders::missing\"")
      debug_inspect(context, content="\"virtual module\"")
    }
    _ => fail("expected resolver-backed missing module error")
  }
}
