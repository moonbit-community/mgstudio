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
/// RFC 1950/1951 compression implementation (zlib wrapper + DEFLATE).
///
/// Ported from `yazi/src/encode.rs` (Apache-2.0 OR MIT).
///
/// P0 implementation note:
/// - We only emit Stored blocks (BTYPE=00, no compression). This is fully valid
///   DEFLATE, and is enough for roundtrip tests and for swash PNG decode.

// ---- Public API ------------------------------------------------------------

///|
/// The level of compression-- a compromise between speed and size.
pub(all) enum CompressionLevel {
  // NOTE: upstream uses the name `None`, but that would shadow `Option::None` in MoonBit.
  NoCompression
  BestSpeed
  Default
  BestSize
  Specific(UInt)
}

///|
/// Selects between various specialized compressor modes.
pub(all) enum CompressionStrategy {
  Default
  RLE
  Filtered
  Static
  Huffman
}

///|
/// Stateful context for compression.
struct Encoder {
  // P0: Keep configuration fields for API parity, but ignore them in output.
  mut zlib : Bool
  mut level : CompressionLevel
  mut strategy : CompressionStrategy
}

///|
pub fn Encoder::new() -> Encoder {
  Encoder::{
    zlib: false,
    level: CompressionLevel::Default,
    strategy: CompressionStrategy::Default,
  }
}

///|
pub fn Encoder::set_format(self : Encoder, format : Format) -> Unit {
  self.zlib = match format {
    Format::Zlib => true
    _ => false
  }
}

///|
pub fn Encoder::set_level(self : Encoder, level : CompressionLevel) -> Unit {
  self.level = level
}

///|
pub fn Encoder::set_strategy(
  self : Encoder,
  strategy : CompressionStrategy,
) -> Unit {
  self.strategy = strategy
}

///|
/// Compression stream combining an encoder context with an output.
struct EncoderStream {
  encoder : Encoder
  out : Array[Byte]
  out_start : Int
  block_buf : Array[Byte]
  mut header_written : Bool
  mut last_header_pos : Int
  mut finished : Bool
  adler : Adler32
}

///|
/// Compression stream that writes into a fixed-size buffer.
///
/// The buffer must be pre-sized; if it's not large enough to hold the
/// compressed output, `YaziError::Overflow` is raised on `finish`.
struct EncoderBufStream {
  inner : EncoderStream
  buf : Array[Byte]
  mut finished : Bool
}

///|
/// Creates an encoder stream that will append into the specified vector.
pub fn Encoder::stream_into_vec(
  self : Encoder,
  vec : Array[Byte],
) -> EncoderStream {
  let adler = Adler32::new()
  EncoderStream::{
    encoder: self,
    out: vec,
    out_start: vec.length(),
    block_buf: [],
    header_written: false,
    last_header_pos: -1,
    finished: false,
    adler,
  }
}

///|
/// Creates an encoder stream that will write into the specified buffer.
pub fn Encoder::stream_into_buf(
  self : Encoder,
  buf : Array[Byte],
) -> EncoderBufStream {
  let tmp = []
  let inner = self.stream_into_vec(tmp)
  EncoderBufStream::{ inner, buf, finished: false }
}

///|
pub fn EncoderStream::write(
  self : EncoderStream,
  buf : Bytes,
) -> Unit raise YaziError {
  if self.finished {
    raise YaziError::Finished
  }
  if self.encoder.zlib && !self.header_written {
    self.write_zlib_header()
    self.header_written = true
  }
  if self.encoder.zlib {
    self.adler.update(buf)
  }
  // P0: emit Stored blocks. Flush full blocks eagerly (BFINAL=0).
  for i in 0..<buf.length() {
    self.block_buf.push(buf[i])
    if self.block_buf.length() == 65535 {
      self.flush_stored_block(false)
    }
  }
}

///|
/// Consumes the stream, emitting a complete compressed bitstream.
pub fn EncoderStream::finish(self : EncoderStream) -> UInt64 raise YaziError {
  if self.finished {
    raise YaziError::Finished
  }
  self.finished = true
  if self.encoder.zlib && !self.header_written {
    self.write_zlib_header()
    self.header_written = true
  }
  if self.block_buf.length() > 0 {
    self.flush_stored_block(true)
  } else if self.last_header_pos != -1 {
    // Mark the last block as final (BFINAL=1).
    self.out[self.last_header_pos] = b'\x01'
  } else {
    // No blocks were emitted; emit a single empty final block.
    self.flush_empty_final_block()
  }
  if self.encoder.zlib {
    let checksum = self.adler.finish()
    // Adler-32 big-endian footer.
    self.out.push(byte_of_u((checksum >> 24) & 0xFF))
    self.out.push(byte_of_u((checksum >> 16) & 0xFF))
    self.out.push(byte_of_u((checksum >> 8) & 0xFF))
    self.out.push(byte_of_u(checksum & 0xFF))
  }
  (self.out.length() - self.out_start).to_uint64()
}

///|
/// Returns the number of compressed bytes that have been written to the output.
pub fn EncoderStream::compressed_size(self : EncoderStream) -> UInt64 {
  (self.out.length() - self.out_start).to_uint64()
}

///|
pub fn EncoderBufStream::write(
  self : EncoderBufStream,
  buf : Bytes,
) -> Unit raise YaziError {
  if self.finished {
    raise YaziError::Finished
  }
  self.inner.write(buf)
}

///|
pub fn EncoderBufStream::compressed_size(self : EncoderBufStream) -> UInt64 {
  self.inner.compressed_size()
}

///|
pub fn EncoderBufStream::finish(
  self : EncoderBufStream,
) -> UInt64 raise YaziError {
  if self.finished {
    raise YaziError::Finished
  }
  self.finished = true
  let written = self.inner.finish()
  let n = self.inner.out.length()
  if n > self.buf.length() {
    raise YaziError::Overflow
  }
  for i in 0..<n {
    self.buf[i] = self.inner.out[i]
  }
  written
}

///|
fn EncoderStream::write_zlib_header(self : EncoderStream) -> Unit {
  let cmf : UInt = 0x78
  let flevel = match self.encoder.level {
    NoCompression => 0
    BestSpeed => 0
    Default => 2
    BestSize => 3
    Specific(_) => 2
  }
  // Read strategy for now (keeps it in the data model without warnings).
  let _ = self.encoder.strategy
  let flg0 : UInt = flevel.reinterpret_as_uint() << 6
  let base = cmf * 256 + flg0
  let m : UInt = 31
  let fcheck = (m - base % m) % m
  let flg = flg0 | fcheck
  // zlib header (no dictionary).
  self.out.push(byte_of_u(cmf))
  self.out.push(byte_of_u(flg))
}

///|
fn EncoderStream::flush_stored_block(
  self : EncoderStream,
  is_final : Bool,
) -> Unit {
  let header_pos = self.out.length()
  self.last_header_pos = header_pos
  self.out.push(if is_final { b'\x01' } else { b'\x00' })
  let len_u = self.block_buf.length().reinterpret_as_uint()
  write_u16_le(self.out, len_u)
  write_u16_le(self.out, (0xFFFF).reinterpret_as_uint() - len_u)
  for b in self.block_buf {
    self.out.push(b)
  }
  self.block_buf.clear()
}

///|
fn EncoderStream::flush_empty_final_block(self : EncoderStream) -> Unit {
  self.last_header_pos = self.out.length()
  self.out.push(b'\x01')
  write_u16_le(self.out, 0)
  write_u16_le(self.out, 0xFFFF)
}

///|
/// Compresses a buffer into a vector with the specified format and compression level.
pub fn compress(
  buf : Bytes,
  format : Format,
  level : CompressionLevel,
) -> Array[Byte] raise YaziError {
  let encoder = Encoder::new()
  encoder.set_format(format)
  encoder.set_level(level)
  let out = []
  let stream = encoder.stream_into_vec(out)
  stream.write(buf)
  stream.finish() |> ignore
  out
}

// ---- Stored block deflate --------------------------------------------------

///|
fn write_u16_le(out : Array[Byte], v : UInt) -> Unit {
  out.push((v & 0xFF).reinterpret_as_int().to_byte())
  out.push(((v >> 8) & 0xFF).reinterpret_as_int().to_byte())
}

///|
// Stored blocks are byte-aligned; we encode the 3-bit header as a whole byte
// (`bfinal` in bit0, `btype=00` in bit1..2, rest zeros).

// ---- Tests -----------------------------------------------------------------

///|
fn generate_bytes() -> Bytes {
  let letters = b"abcdefghijklmnopqrstuvwxyz"
  let out : Array[Byte] = []
  for i in 0..<4096 {
    if i % 3 == 0 {
      // "nopqrstuvwxyz"
      for j in 13..<26 {
        out.push(letters[j])
      }
    } else if (i & 1) != 0 {
      for j in 0..<26 {
        out.push(letters[j])
      }
    } else {
      for j in 0..<26 {
        out.push(letters[25 - j])
      }
    }
  }
  Bytes::from_array(out)
}

///|
test "compress/decompress (raw) roundtrip via stored blocks" {
  let input = generate_bytes()
  let compressed = compress(input, Format::Raw, CompressionLevel::Default)
  let (decompressed, _) = decompress(Bytes::from_array(compressed), Format::Raw)
  inspect(bytes_eq(input, decompressed), content="true")
}

///|
test "compress/decompress (zlib) roundtrip + checksum" {
  let input = generate_bytes()
  let compressed = compress(input, Format::Zlib, CompressionLevel::Default)
  let (decompressed, checksum) = decompress(
    Bytes::from_array(compressed),
    Format::Zlib,
  )
  inspect(bytes_eq(input, decompressed), content="true")
  let got = Adler32::from_buf(Bytes::from_array(decompressed)).finish()
  inspect(checksum == Some(got), content="true")
}

///|
test "compress/decompress empty (raw)" {
  let input = b""
  let compressed = compress(input, Format::Raw, CompressionLevel::Default)
  let (decompressed, checksum) = decompress(
    Bytes::from_array(compressed),
    Format::Raw,
  )
  inspect(decompressed.length(), content="0")
  inspect(checksum, content="None")
}

///|
test "compress/decompress empty (zlib)" {
  let input = b""
  let compressed = compress(input, Format::Zlib, CompressionLevel::Default)
  let (decompressed, checksum) = decompress(
    Bytes::from_array(compressed),
    Format::Zlib,
  )
  inspect(decompressed.length(), content="0")
  inspect(checksum == Some(1), content="true")
}

///|
test "EncoderStream appends into vec (does not clear prefix)" {
  let out = [b'\xAA', b'\xBB']
  let encoder = Encoder::new()
  encoder.set_format(Format::Raw)
  let stream = encoder.stream_into_vec(out)
  stream.write(b"hi")
  let written = stream.finish()
  inspect(out[0], content="b'\\xAA'")
  inspect(out[1], content="b'\\xBB'")
  inspect((out.length() - 2).to_uint64() == written, content="true")
}

///|
test "EncoderBufStream overflows when buffer is too small" {
  let buf = [b'\x00']
  let encoder = Encoder::new()
  encoder.set_format(Format::Raw)
  let stream = encoder.stream_into_buf(buf)
  stream.write(b"hello")
  let ok = try {
    stream.finish() |> ignore
    false
  } catch {
    YaziError::Overflow => true
    _ => false
  }
  inspect(ok, content="true")
}

///|
fn bytes_eq(expected : Bytes, actual : Array[Byte]) -> Bool {
  if actual.length() != expected.length() {
    return false
  }
  for i in 0..<actual.length() {
    if actual[i] != expected[i] {
      return false
    }
  }
  true
}
