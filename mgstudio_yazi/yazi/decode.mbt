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
/// RFC 1951 decompression (subset; WIP).
///
/// Ported from `yazi/src/decode.rs` (Apache-2.0 OR MIT).
pub struct Decoder {
  mut zlib : Bool
  mut finished : Bool
}

///|
pub fn Decoder::new() -> Decoder {
  Decoder::{ zlib: false, finished: false }
}

///|
pub fn Decoder::set_format(self : Decoder, format : Format) -> Unit {
  self.zlib = match format {
    Format::Zlib => true
    _ => false
  }
  self.finished = false
}

///|
pub struct DecoderStream {
  decoder : Decoder
  out : Array[Byte]
  mut finished : Bool
}

///|
pub fn Decoder::stream_into_vec(
  self : Decoder,
  out : Array[Byte],
) -> DecoderStream {
  DecoderStream::{ decoder: self, out, finished: false }
}

///|
fn read_u16_be(data : Bytes, offset : Int) -> UInt? {
  if offset < 0 || offset + 2 > data.length() {
    return None
  }
  match (data.get(offset), data.get(offset + 1)) {
    (Some(b0), Some(b1)) =>
      Some(
        (b0.to_int().reinterpret_as_uint() << 8) |
        b1.to_int().reinterpret_as_uint(),
      )
    _ => None
  }
}

///|
fn adler32(_data : Bytes) -> UInt {
  // TODO: full port
  1
}

///|
fn verify_zlib_header(data : Bytes) -> Unit raise YaziError {
  // CMF/FLG: big endian u16
  let hdr = match read_u16_be(data, 0) {
    None => raise YaziError::Underflow
    Some(v) => v
  }
  // Check mod 31 (RFC 1950)
  if hdr % 31 != 0 {
    raise YaziError::InvalidBitstream
  }
  // CM=8 DEFLATE
  let cm : UInt = hdr & 0x0F00
  if cm != 0x0800 {
    raise YaziError::InvalidBitstream
  }
}

///|
fn decompress_stored_block(
  data : Bytes,
  start : Int,
  out : Array[Byte],
) -> Int raise YaziError {
  // Stored block: align to next byte boundary; header already consumed outside.
  let len = match read_u16_be(data, start) {
    None => raise YaziError::Underflow
    Some(v) => v
  }
  let nlen = match read_u16_be(data, start + 2) {
    None => raise YaziError::Underflow
    Some(v) => v
  }
  if (len ^ 0xFFFF) != nlen {
    raise YaziError::InvalidBitstream
  }
  let length = len.reinterpret_as_int()
  let payload_off = start + 4
  if payload_off + length > data.length() {
    raise YaziError::Underflow
  }
  for i in 0..<length {
    out.push(data[payload_off + i])
  }
  payload_off + length
}

///|
pub fn DecoderStream::write(
  self : DecoderStream,
  data : Bytes,
) -> Unit raise YaziError {
  if self.finished {
    raise YaziError::Finished
  }
  let mut offset = 0
  if self.decoder.zlib {
    // Minimal zlib wrapper: header + single stored block + adler32.
    if data.length() < 2 {
      raise YaziError::Underflow
    }
    verify_zlib_header(data)
    offset = 2
  }

  // Minimal DEFLATE support: only BTYPE=00 stored blocks, single block.
  if offset >= data.length() {
    raise YaziError::Underflow
  }
  let bfinal_btype = data[offset].to_int().reinterpret_as_uint()
  let bfinal = bfinal_btype & 1
  let btype = (bfinal_btype >> 1) & 3
  offset = offset + 1
  if btype != 0 {
    // TODO: implement fixed/dynamic Huffman blocks.
    raise YaziError::InvalidBitstream
  }
  offset = decompress_stored_block(data, offset, self.out)
  if bfinal == 1 {
    self.decoder.finished = true
    if self.decoder.zlib {
      // Expect checksum trailer.
      if offset + 4 > data.length() {
        raise YaziError::Underflow
      }
      let _checksum = read_u16_be(data, offset).unwrap_or(0)
      let _checksum2 = read_u16_be(data, offset + 2).unwrap_or(0)
      // TODO: verify full Adler32.
      let _ = adler32(b"")

    }
  }
}

///|
pub fn DecoderStream::finish(
  self : DecoderStream,
) -> (UInt64, UInt?) raise YaziError {
  if self.finished {
    raise YaziError::Finished
  }
  self.finished = true
  (self.out.length().to_uint64(), None)
}

///|
/// Decompresses a buffer of the specified format into a new vector.
pub fn decompress(
  buf : Bytes,
  format : Format,
) -> (Array[Byte], UInt?) raise YaziError {
  let dec = Decoder::new()
  dec.set_format(format)
  let out = []
  let stream = dec.stream_into_vec(out)
  stream.write(buf)
  let (_n, checksum) = stream.finish()
  (out, checksum)
}

///|
test "decompress stored block (raw)" {
  // BFINAL=1,BTYPE=00 byte 0x01; LEN=3, NLEN=0xFFFC; payload 'abc'
  let data = b"\x01\x00\x03\xFF\xFCabc"
  let (out, _) = decompress(data, Format::Raw)
  inspect(out, content="[b'\\x61', b'\\x62', b'\\x63']")
}
