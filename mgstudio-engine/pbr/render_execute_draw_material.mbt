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
priv struct Render3dMeshDrawMaterialFields {
  draw_material_input : @pbr_render.Render3dDrawMaterialInput
  draw_alpha : Float
  base_color_r : Float
  base_color_g : Float
  base_color_b : Float
  texture_id : Int
  normal_texture_id : Int
  emissive_texture_id : Int
  metallic_roughness_texture_id : Int
  occlusion_texture_id : Int
  depth_texture_id : Int
  anisotropy_texture_id : Int
  specular_texture_id : Int
  specular_tint_texture_id : Int
  clearcoat_texture_id : Int
  clearcoat_roughness_texture_id : Int
  clearcoat_normal_texture_id : Int
  surface_roughness : Float
  reflectance : Float
  diffuse_transmission : Float
  specular_transmission : Float
  thickness : Float
  ior : Float
  specular_tint : @color.Color
  anisotropy_strength : Float
  max_relief_mapping_search_steps : Float
  forward_decal_inv_depth_fade_factor : Float
  lightmap_texture_id : Int
  lightmap_slab_index : Int
  lightmap_slot_index : Int
  lightmap_slab_texture_ids : Array[Int]
  lightmap_uv_min_x : Float
  lightmap_uv_min_y : Float
  lightmap_uv_max_x : Float
  lightmap_uv_max_y : Float
}

///|
priv struct Render3dMeshLightmapDrawFields {
  lightmap_texture_id : Int
  lightmap_slab_index : Int
  lightmap_slot_index : Int
  lightmap_slab_texture_ids : Array[Int]
  lightmap_uv_min_x : Float
  lightmap_uv_min_y : Float
  lightmap_uv_max_x : Float
  lightmap_uv_max_y : Float
}

///|
fn render3d_resolve_mesh_lightmap_draw_fields(
  world : @ecs.World,
  extracted_mesh : ExtractedMesh3d,
) -> Render3dMeshLightmapDrawFields {
  let no_lightmap : Render3dMeshLightmapDrawFields = {
    lightmap_texture_id: -1,
    lightmap_slab_index: -1,
    lightmap_slot_index: -1,
    lightmap_slab_texture_ids: [],
    lightmap_uv_min_x: 0.0F,
    lightmap_uv_min_y: 0.0F,
    lightmap_uv_max_x: 0.0F,
    lightmap_uv_max_y: 0.0F,
  }
  let mesh = extracted_mesh.payload
  match mesh.lightmap {
    Some(lightmap) if lightmap.image.id() >= 0 =>
      // The draw payload reads the persistent `RenderLightmaps` table that
      // `extract_lightmaps_system` maintains; it no longer allocates slots,
      // so pipeline specialization and the draw stay coherent (ISS-488). An
      // entity absent from the table draws without a lightmap, matching its
      // non-`LIGHTMAP` pipeline.
      match world.get_resource(@lightmap.RenderLightmaps::resource()) {
        Some(render_lightmaps) =>
          match render_lightmaps.get(extracted_mesh.entity.main_entity) {
            Some(render_lightmap) => {
              let uv_min = render_lightmap.uv_rect.min()
              let uv_max = render_lightmap.uv_rect.max()
              {
                lightmap_texture_id: lightmap.image.id(),
                lightmap_slab_index: render_lightmap.slab_index.to_int(),
                lightmap_slot_index: render_lightmap.slot_index.to_int(),
                lightmap_slab_texture_ids: render_lightmaps.slab_texture_ids(
                  render_lightmap.slab_index,
                ),
                lightmap_uv_min_x: uv_min.x,
                lightmap_uv_min_y: uv_min.y,
                lightmap_uv_max_x: uv_max.x,
                lightmap_uv_max_y: uv_max.y,
              }
            }
            None => no_lightmap
          }
        None => no_lightmap
      }
    _ => no_lightmap
  }
}

///|
fn render3d_forward_decal_inv_depth_fade_factor(
  mesh : Mesh3dExtractedPayload,
) -> Float {
  if mesh.is_forward_decal {
    let depth_fade_factor = match mesh.forward_decal_material_ext {
      Some(extension) => extension.depth_fade_factor
      None => 8.0F
    }
    let safe_depth_fade_factor = if depth_fade_factor < 0.001F {
      0.001F
    } else {
      depth_fade_factor
    }
    1.0F / safe_depth_fade_factor
  } else {
    1.0F / 8.0F
  }
}

///|
fn render3d_resolve_mesh_draw_material_fields(
  world : @ecs.World,
  extracted_mesh : ExtractedMesh3d,
  draw_alpha : Float,
) -> Render3dMeshDrawMaterialFields {
  let mesh = extracted_mesh.payload
  let lightmap_fields = render3d_resolve_mesh_lightmap_draw_fields(
    world, extracted_mesh,
  )
  guard mesh.material_draw_data.standard_material() is Some(material) else {
    return {
      draw_material_input: @pbr_render.Render3dDrawMaterialInput::from_material_properties(
        mesh.material_properties,
      ),
      draw_alpha,
      base_color_r: 1.0F,
      base_color_g: 1.0F,
      base_color_b: 1.0F,
      texture_id: -1,
      normal_texture_id: -1,
      emissive_texture_id: -1,
      metallic_roughness_texture_id: -1,
      occlusion_texture_id: -1,
      depth_texture_id: -1,
      anisotropy_texture_id: -1,
      specular_texture_id: -1,
      specular_tint_texture_id: -1,
      clearcoat_texture_id: -1,
      clearcoat_roughness_texture_id: -1,
      clearcoat_normal_texture_id: -1,
      surface_roughness: 0.5F,
      reflectance: 0.5F,
      diffuse_transmission: 0.0F,
      specular_transmission: 0.0F,
      thickness: 0.0F,
      ior: 1.5F,
      specular_tint: @color.Color::white(),
      anisotropy_strength: 0.0F,
      max_relief_mapping_search_steps: 0.0F,
      forward_decal_inv_depth_fade_factor: render3d_forward_decal_inv_depth_fade_factor(
        mesh,
      ),
      lightmap_texture_id: lightmap_fields.lightmap_texture_id,
      lightmap_slab_index: lightmap_fields.lightmap_slab_index,
      lightmap_slot_index: lightmap_fields.lightmap_slot_index,
      lightmap_slab_texture_ids: lightmap_fields.lightmap_slab_texture_ids,
      lightmap_uv_min_x: lightmap_fields.lightmap_uv_min_x,
      lightmap_uv_min_y: lightmap_fields.lightmap_uv_min_y,
      lightmap_uv_max_x: lightmap_fields.lightmap_uv_max_x,
      lightmap_uv_max_y: lightmap_fields.lightmap_uv_max_y,
    }
  }
  let mut texture_id = match material.base_color_texture {
    Some(texture) => texture.id()
    None => -1
  }
  let mut normal_texture_id = match material.normal_map_texture {
    Some(texture) => texture.id()
    None => -1
  }
  let mut emissive_texture_id = match material.emissive_texture {
    Some(texture) => texture.id()
    None => -1
  }
  let mut metallic_roughness_texture_id = match
    material.metallic_roughness_texture {
    Some(texture) => texture.id()
    None => -1
  }
  let occlusion_texture_id = match material.occlusion_texture {
    Some(texture) => texture.id()
    None => -1
  }
  let depth_texture_id = match material.depth_map {
    Some(texture) => texture.id()
    None => -1
  }
  let anisotropy_texture_id = match material.anisotropy_texture {
    Some(texture) => texture.id()
    None => -1
  }
  let specular_texture_id = match material.specular_texture {
    Some(texture) => texture.id()
    None => -1
  }
  let specular_tint_texture_id = match material.specular_tint_texture {
    Some(texture) => texture.id()
    None => -1
  }
  let clearcoat_texture_id = match material.clearcoat_texture {
    Some(texture) => texture.id()
    None => -1
  }
  let clearcoat_roughness_texture_id = match
    material.clearcoat_roughness_texture {
    Some(texture) => texture.id()
    None => -1
  }
  let clearcoat_normal_texture_id = match material.clearcoat_normal_texture {
    Some(texture) => texture.id()
    None => -1
  }
  if mesh.clustered_decal is Some(clustered_decal) {
    if clustered_decal.base_color_texture is Some(texture) {
      texture_id = texture.id()
    }
    if clustered_decal.normal_map_texture is Some(texture) {
      normal_texture_id = texture.id()
    }
    if clustered_decal.metallic_roughness_texture is Some(texture) {
      metallic_roughness_texture_id = texture.id()
    }
    if clustered_decal.emissive_texture is Some(texture) {
      emissive_texture_id = texture.id()
    }
  }
  let clearcoat_reflectance = @pbr_render.maxf(
    0.0F,
    material.reflectance + material.clearcoat * 0.5F,
  )
  let clearcoat_roughness = @pbr_render.minf(
    material.perceptual_roughness,
    material.clearcoat_perceptual_roughness,
  )
  let surface_roughness = if material.clearcoat > 0.0F {
    clearcoat_roughness
  } else {
    material.perceptual_roughness
  }
  let forward_decal_inv_depth_fade_factor = render3d_forward_decal_inv_depth_fade_factor(
    mesh,
  )
  {
    draw_material_input: @pbr_render.Render3dDrawMaterialInput::from_standard_material(
      material,
      texture_id,
      normal_texture_id,
      emissive_texture_id,
      metallic_roughness_texture_id,
      occlusion_texture_id,
      depth_texture_id,
      anisotropy_texture_id,
      specular_tint_texture_id,
      specular_texture_id~,
      forward_decal=mesh.is_forward_decal,
    ),
    draw_alpha,
    base_color_r: material.base_color.r,
    base_color_g: material.base_color.g,
    base_color_b: material.base_color.b,
    texture_id,
    normal_texture_id,
    emissive_texture_id,
    metallic_roughness_texture_id,
    occlusion_texture_id,
    depth_texture_id,
    anisotropy_texture_id,
    specular_texture_id,
    specular_tint_texture_id,
    clearcoat_texture_id,
    clearcoat_roughness_texture_id,
    clearcoat_normal_texture_id,
    surface_roughness,
    reflectance: clearcoat_reflectance,
    diffuse_transmission: @pbr_render.clamp01(material.diffuse_transmission),
    specular_transmission: @pbr_render.clamp01(material.specular_transmission),
    thickness: @pbr_render.maxf(0.0F, material.thickness),
    ior: @pbr_render.maxf(1.0F, material.ior),
    specular_tint: material.specular_tint,
    anisotropy_strength: @pbr_render.maxf(
      0.0F,
      @pbr_render.minf(1.0F, material.anisotropy_strength),
    ),
    max_relief_mapping_search_steps: Float::from_double(
      material.parallax_mapping_method.max_steps().to_double(),
    ),
    forward_decal_inv_depth_fade_factor,
    lightmap_texture_id: lightmap_fields.lightmap_texture_id,
    lightmap_slab_index: lightmap_fields.lightmap_slab_index,
    lightmap_slot_index: lightmap_fields.lightmap_slot_index,
    lightmap_slab_texture_ids: lightmap_fields.lightmap_slab_texture_ids,
    lightmap_uv_min_x: lightmap_fields.lightmap_uv_min_x,
    lightmap_uv_min_y: lightmap_fields.lightmap_uv_min_y,
    lightmap_uv_max_x: lightmap_fields.lightmap_uv_max_x,
    lightmap_uv_max_y: lightmap_fields.lightmap_uv_max_y,
  }
}
