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
test "image sampler descriptor: repeat keeps Bevy default nearest filters" {
  let descriptor = ImageSamplerDescriptor::default().set_address_mode(
    ImageAddressMode::Repeat,
  )
  debug_inspect(
    descriptor.address_mode_u == ImageAddressMode::Repeat,
    content="true",
  )
  debug_inspect(
    descriptor.address_mode_v == ImageAddressMode::Repeat,
    content="true",
  )
  debug_inspect(
    descriptor.address_mode_w == ImageAddressMode::Repeat,
    content="true",
  )
  debug_inspect(
    descriptor.mag_filter == ImageFilterMode::Nearest,
    content="true",
  )
  debug_inspect(
    descriptor.min_filter == ImageFilterMode::Nearest,
    content="true",
  )
  debug_inspect(
    descriptor.mipmap_filter == ImageFilterMode::Nearest,
    content="true",
  )
  debug_inspect(descriptor.lod_min_clamp, content="0")
  debug_inspect(descriptor.lod_max_clamp, content="32")
  debug_inspect(descriptor.compare is None, content="true")
  debug_inspect(descriptor.anisotropy_clamp, content="1")
  debug_inspect(descriptor.border_color is None, content="true")
}

///|
test "image sampler descriptor: anisotropic filter matches Bevy helper semantics" {
  let descriptor = ImageSamplerDescriptor::default().set_anisotropic_filter(8)
  debug_inspect(
    descriptor.mag_filter == ImageFilterMode::Linear,
    content="true",
  )
  debug_inspect(
    descriptor.min_filter == ImageFilterMode::Linear,
    content="true",
  )
  debug_inspect(
    descriptor.mipmap_filter == ImageFilterMode::Linear,
    content="true",
  )
  debug_inspect(descriptor.anisotropy_clamp, content="8")
}

///|
test "image sampler descriptor: public fields preserve compare lod and mirror repeat" {
  let descriptor = ImageSamplerDescriptor::linear()
  descriptor.address_mode_u = ImageAddressMode::MirrorRepeat
  descriptor.address_mode_v = ImageAddressMode::Repeat
  descriptor.address_mode_w = ImageAddressMode::ClampToEdge
  descriptor.lod_min_clamp = 1.5F
  descriptor.lod_max_clamp = 7.25F
  descriptor.compare = Some(ImageCompareFunction::GreaterEqual)
  descriptor.anisotropy_clamp = 4
  debug_inspect(
    descriptor.address_mode_u == ImageAddressMode::MirrorRepeat,
    content="true",
  )
  debug_inspect(
    descriptor.address_mode_v == ImageAddressMode::Repeat,
    content="true",
  )
  debug_inspect(
    descriptor.address_mode_w == ImageAddressMode::ClampToEdge,
    content="true",
  )
  debug_inspect(
    descriptor.mag_filter == ImageFilterMode::Linear,
    content="true",
  )
  debug_inspect(
    descriptor.min_filter == ImageFilterMode::Linear,
    content="true",
  )
  debug_inspect(
    descriptor.mipmap_filter == ImageFilterMode::Linear,
    content="true",
  )
  debug_inspect(descriptor.lod_min_clamp, content="1.5")
  debug_inspect(descriptor.lod_max_clamp, content="7.25")
  debug_inspect(
    descriptor.compare == Some(ImageCompareFunction::GreaterEqual),
    content="true",
  )
  debug_inspect(descriptor.anisotropy_clamp, content="4")
  debug_inspect(descriptor.border_color is None, content="true")
}

///|
test "image loader settings: closure-style mutation updates public fields" {
  let settings = ImageLoaderSettings::default()
  settings.sampler = ImageSampler::Descriptor(
    ImageSamplerDescriptor::default().set_address_mode(ImageAddressMode::Repeat),
  )
  settings.is_srgb = false
  settings.array_layout = Some(RowCount(4))

  debug_inspect(settings.is_srgb, content="false")
  debug_inspect(settings.array_layout is Some(RowCount(_)), content="true")
  if settings.array_layout is Some(RowCount(count)) {
    debug_inspect(count, content="4")
  }
  debug_inspect(settings.sampler is Descriptor(_), content="true")
  if settings.sampler is Descriptor(descriptor) {
    debug_inspect(
      descriptor.address_mode_u == ImageAddressMode::Repeat,
      content="true",
    )
  }
}

///|
test "asset server load_with_settings invokes configuration closure" {
  let asset_server = AssetServer::new()
  let configured = Ref::new(false)
  let handle : Handle[Image] = asset_server.load_with_settings(
    "textures/fantasy_ui_borders/panel-border-010-repeated.png",
    fn(settings) {
      configured.val = true
      settings.sampler = ImageSampler::Descriptor(
        ImageSamplerDescriptor::default().set_address_mode(
          ImageAddressMode::Repeat,
        ),
      )
      settings.is_srgb = false
    },
  )
  debug_inspect(configured.val, content="true")
  debug_inspect(handle.id() >= 0, content="true")
}
