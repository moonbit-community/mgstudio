name = "Milky2018/mgstudio"

version = "0.2.0"

import {
  "Milky2018/moon_cosmic@0.3.3",
  "Milky2018/moon_rapier@0.5.1",
  "Milky2018/moon_swash@0.1.10",
  "Milky2018/moon_zeno@0.1.3",
  "Milky2018/moon_taffy@0.5.2",
  "Milky2018/moon_accesskit@0.3.0",
  "Milky2018/moon_skrifa@0.1.8",
  "Milky2018/gamepad@0.4.6",
  "Milky2018/moon_cpal@0.11.7",
  "Milky2018/moon_rodio@0.3.3",
  "Milky2018/moon_wesl@0.17.0",
  "Milky2018/moon_wgsl@0.17.0",
  "Milky2018/wgpu_mbt@0.15.0",
  "moonbitlang/x@0.4.45",
  "Milky2018/window@0.6.0",
  "gmlewis/image@0.17.9",
  "gmlewis/io@0.23.12",
  "Milky2018/sysinfo@0.1.2",
  "Milky2018/zstd@0.1.1",
  "gmlewis/gzip@0.34.9",
  "gmlewis/flate@0.36.9",
  "Milky2018/metis@0.1.1",
  "Milky2018/meshopt_mbt@0.1.1",
  "Milky2018/wgsl@0.17.0",
  "Milky2018/moon_wgsl_naga@0.17.0",
  "Milky2018/moon_wgsl_naga_oil@0.17.0",
  "Milky2018/windowing@0.1.0",
}

readme = "README.mbt.md"

repository = "https://github.com/moonbit-community/mgstudio"

license = "Apache-2.0"

keywords = [ ]

description = ""

preferred_target = "native"

options(
  exclude: [ "examples", "assets" ],
  "--moonbit-unstable-prebuild": "build.js",
)
