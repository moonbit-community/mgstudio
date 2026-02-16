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
fn bytes_ascii(input : String) -> Bytes {
  let out : Array[Byte] = []
  for c in input {
    out.push((c.to_int() & 0xFF).to_byte())
  }
  Bytes::from_array(out)
}

///|
fn push_u32_le(out : Array[Byte], value : UInt) -> Unit {
  out.push((value & 0xFFU).reinterpret_as_int().to_byte())
  out.push(((value >> 8) & 0xFFU).reinterpret_as_int().to_byte())
  out.push(((value >> 16) & 0xFFU).reinterpret_as_int().to_byte())
  out.push(((value >> 24) & 0xFFU).reinterpret_as_int().to_byte())
}

///|
fn push_f32_le(out : Array[Byte], value : Float) -> Unit {
  push_u32_le(out, value.reinterpret_as_uint())
}

///|
fn sampler_tag(sampler : @asset.ImageSampler) -> Int {
  match sampler {
    @asset.ImageSampler::Linear => 0
    @asset.ImageSampler::LinearRepeat => 1
    @asset.ImageSampler::Nearest => 2
    @asset.ImageSampler::NearestRepeat => 3
  }
}

///|
test "scene gltf wb: decode data uri base64" {
  let decoded = data_uri_decode_bytes(
    "data:application/octet-stream;base64,AAEC/w==",
  ).unwrap()
  inspect(decoded.length(), content="4")
  inspect(decoded[0].to_int() & 0xFF, content="0")
  inspect(decoded[1].to_int() & 0xFF, content="1")
  inspect(decoded[2].to_int() & 0xFF, content="2")
  inspect(decoded[3].to_int() & 0xFF, content="255")
}

///|
test "scene gltf wb: decode data uri percent encoding" {
  let decoded = data_uri_decode_bytes("data:text/plain,AB%20C").unwrap()
  inspect(decoded.length(), content="4")
  inspect(decoded[0].to_int() & 0xFF, content="65")
  inspect(decoded[1].to_int() & 0xFF, content="66")
  inspect(decoded[2].to_int() & 0xFF, content="32")
  inspect(decoded[3].to_int() & 0xFF, content="67")
}

///|
test "scene gltf wb: parse glb container" {
  let json = "{" +
    "\"asset\":{\"version\":\"2.0\"}," +
    "\"scene\":0," +
    "\"scenes\":[{\"nodes\":[]}]," +
    "\"nodes\":[]," +
    "\"meshes\":[]," +
    "\"buffers\":[{\"byteLength\":0}]" +
    "}"
  let payload : Array[Byte] = bytes_ascii(json).to_array()
  let space : Int = 0x20
  while payload.length() % 4 != 0 {
    payload.push(space.to_byte())
  }

  let glb : Array[Byte] = []
  let total = 12 + 8 + payload.length()
  push_u32_le(glb, 0x46546C67U)
  push_u32_le(glb, 2U)
  push_u32_le(glb, total.reinterpret_as_uint())
  push_u32_le(glb, payload.length().reinterpret_as_uint())
  push_u32_le(glb, 0x4E4F534AU)
  for b in payload {
    glb.push(b)
  }

  let parsed = gltf_parse_glb(Bytes::from_array(glb)).unwrap()
  inspect(parsed.0.contains("\"asset\""), content="true")
  inspect(parsed.1 == None, content="true")

  let doc = gltf_parse_document(parsed.0).unwrap()
  inspect(doc.buffers.length(), content="1")
}

///|
test "scene gltf wb: read vec3 from second buffer" {
  let source = "{" +
    "\"asset\":{\"version\":\"2.0\"}," +
    "\"scene\":0," +
    "\"scenes\":[{\"nodes\":[0]}]," +
    "\"nodes\":[{\"mesh\":0}]," +
    "\"meshes\":[{\"primitives\":[{\"attributes\":{\"POSITION\":0}}]}]," +
    "\"buffers\":[{\"byteLength\":0},{\"byteLength\":12}]," +
    "\"bufferViews\":[{\"buffer\":1,\"byteOffset\":0,\"byteLength\":12}]," +
    "\"accessors\":[{\"bufferView\":0,\"componentType\":5126,\"count\":1,\"type\":\"VEC3\"}]" +
    "}"
  let doc = gltf_parse_document(source).unwrap()

  let raw : Array[Byte] = []
  push_f32_le(raw, 1.0F)
  push_f32_le(raw, 2.0F)
  push_f32_le(raw, 3.0F)

  let vecs = gltf_read_accessor_vec3(
    doc,
    [Bytes::new(0), Bytes::from_array(raw)],
    0,
  ).unwrap()
  inspect(vecs.length(), content="1")
  inspect(vecs[0].x.to_double(), content="1")
  inspect(vecs[0].y.to_double(), content="2")
  inspect(vecs[0].z.to_double(), content="3")
}

///|
test "scene gltf wb: image bufferView bytes" {
  let source = "{" +
    "\"asset\":{\"version\":\"2.0\"}," +
    "\"scene\":0," +
    "\"scenes\":[{\"nodes\":[]}]," +
    "\"nodes\":[]," +
    "\"meshes\":[]," +
    "\"buffers\":[{\"byteLength\":4}]," +
    "\"bufferViews\":[{\"buffer\":0,\"byteOffset\":1,\"byteLength\":2}]," +
    "\"images\":[{\"bufferView\":0,\"mimeType\":\"image/png\"}]" +
    "}"
  let doc = gltf_parse_document(source).unwrap()
  inspect(doc.images.length(), content="1")
  inspect(doc.images[0].buffer_view, content="Some(0)")
  inspect(doc.images[0].mime_type, content="Some(\"image/png\")")

  let bytes = gltf_buffer_view_bytes(
    doc,
    [
      Bytes::from_array([
        (10).to_byte(),
        (20).to_byte(),
        (30).to_byte(),
        (40).to_byte(),
      ]),
    ],
    0,
  ).unwrap()
  inspect(bytes.length(), content="2")
  inspect(bytes[0].to_int() & 0xFF, content="20")
  inspect(bytes[1].to_int() & 0xFF, content="30")
}

///|
test "scene gltf wb: parse sampler and texture mapping" {
  let source = "{" +
    "\"asset\":{\"version\":\"2.0\"}," +
    "\"scene\":0," +
    "\"scenes\":[{\"nodes\":[]}]," +
    "\"nodes\":[]," +
    "\"meshes\":[]," +
    "\"samplers\":[" +
    "{\"magFilter\":9728,\"wrapS\":10497,\"wrapT\":10497}," +
    "{\"minFilter\":9984,\"wrapS\":33071,\"wrapT\":33071}" +
    "]," +
    "\"textures\":[" +
    "{\"sampler\":0}," +
    "{\"sampler\":1}," +
    "{}" +
    "]" +
    "}"
  let doc = gltf_parse_document(source).unwrap()
  inspect(doc.samplers.length(), content="2")
  inspect(doc.samplers[0].nearest, content="true")
  inspect(doc.samplers[0].repeat, content="true")
  inspect(doc.samplers[1].nearest, content="true")
  inspect(doc.samplers[1].repeat, content="false")
  inspect(sampler_tag(gltf_texture_image_sampler(doc, 0)), content="3")
  inspect(sampler_tag(gltf_texture_image_sampler(doc, 1)), content="2")
  inspect(sampler_tag(gltf_texture_image_sampler(doc, 2)), content="1")
}
