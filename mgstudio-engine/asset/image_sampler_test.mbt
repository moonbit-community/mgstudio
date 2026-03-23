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
  inspect(descriptor.address_mode_u == ImageAddressMode::Repeat, content="true")
  inspect(descriptor.address_mode_v == ImageAddressMode::Repeat, content="true")
  inspect(descriptor.address_mode_w == ImageAddressMode::Repeat, content="true")
  inspect(descriptor.mag_filter == ImageFilterMode::Nearest, content="true")
  inspect(descriptor.min_filter == ImageFilterMode::Nearest, content="true")
  inspect(descriptor.mipmap_filter == ImageFilterMode::Nearest, content="true")
  inspect(descriptor.lod_min_clamp, content="0")
  inspect(descriptor.lod_max_clamp, content="32")
  inspect(descriptor.compare is None, content="true")
  inspect(descriptor.anisotropy_clamp, content="1")
  inspect(descriptor.border_color is None, content="true")
}

///|
test "image sampler descriptor: anisotropic filter matches Bevy helper semantics" {
  let descriptor = ImageSamplerDescriptor::default().set_anisotropic_filter(8)
  inspect(descriptor.mag_filter == ImageFilterMode::Linear, content="true")
  inspect(descriptor.min_filter == ImageFilterMode::Linear, content="true")
  inspect(descriptor.mipmap_filter == ImageFilterMode::Linear, content="true")
  inspect(descriptor.anisotropy_clamp, content="8")
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
  inspect(
    descriptor.address_mode_u == ImageAddressMode::MirrorRepeat,
    content="true",
  )
  inspect(descriptor.address_mode_v == ImageAddressMode::Repeat, content="true")
  inspect(
    descriptor.address_mode_w == ImageAddressMode::ClampToEdge,
    content="true",
  )
  inspect(descriptor.mag_filter == ImageFilterMode::Linear, content="true")
  inspect(descriptor.min_filter == ImageFilterMode::Linear, content="true")
  inspect(descriptor.mipmap_filter == ImageFilterMode::Linear, content="true")
  inspect(descriptor.lod_min_clamp, content="1.5")
  inspect(descriptor.lod_max_clamp, content="7.25")
  inspect(
    descriptor.compare == Some(ImageCompareFunction::GreaterEqual),
    content="true",
  )
  inspect(descriptor.anisotropy_clamp, content="4")
  inspect(descriptor.border_color is None, content="true")
}

///|
test "image loader settings: closure-style mutation updates public fields" {
  let settings = ImageLoaderSettings::default()
  settings.sampler = ImageSampler::Descriptor(
    ImageSamplerDescriptor::default().set_address_mode(ImageAddressMode::Repeat),
  )
  settings.is_srgb = false
  settings.array_layout = Some(RowCount(4))

  inspect(settings.is_srgb, content="false")
  inspect(settings.array_layout is Some(RowCount(_)), content="true")
  if settings.array_layout is Some(RowCount(count)) {
    inspect(count, content="4")
  }
  inspect(settings.sampler is Descriptor(_), content="true")
  if settings.sampler is Descriptor(descriptor) {
    inspect(
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
  inspect(configured.val, content="true")
  inspect(handle.id() >= 0, content="true")
}
