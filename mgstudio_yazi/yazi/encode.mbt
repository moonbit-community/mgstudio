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
/// Implementation note:
/// - Uses an upstream-aligned streaming encoder core (`EncDeflateContext`),
///   including raw/static/dynamic block selection heuristics.

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
  ctx : Ref[EncDeflateContext]
}

///|
pub fn Encoder::new() -> Encoder {
  let ctx = EncDeflateContext::new(
    Format::Raw,
    CompressionLevel::Default,
    CompressionStrategy::Default,
  )
  Encoder::{ ctx: Ref::new(ctx) }
}

///|
/// Sets the format of the output bitstream for the next usage of the encoder.
pub fn Encoder::set_format(self : Encoder, format : Format) -> Unit {
  let zlib = match format {
    Format::Zlib => true
    _ => false
  }
  self.ctx.val.reset(zlib)
}

///|
/// Sets the compression level for the next usage of the encoder.
pub fn Encoder::set_level(self : Encoder, level : CompressionLevel) -> Unit {
  let flags = enc_make_flags(self.ctx.val.zlib, level, self.ctx.val.strategy)
  let (p0, p1) = probes_from_flags(flags)
  self.ctx.val.flags = flags
  self.ctx.val.level = level
  self.ctx.val.greedy_parsing = (flags & ENC_GREEDY_PARSING) != 0
  self.ctx.val.dict.max_probes0 = p0
  self.ctx.val.dict.max_probes1 = p1
}

///|
/// Sets the compression strategy for the next usage of the encoder.
pub fn Encoder::set_strategy(
  self : Encoder,
  strategy : CompressionStrategy,
) -> Unit {
  let flags = enc_make_flags(self.ctx.val.zlib, self.ctx.val.level, strategy)
  let (p0, p1) = probes_from_flags(flags)
  self.ctx.val.flags = flags
  self.ctx.val.strategy = strategy
  self.ctx.val.greedy_parsing = (flags & ENC_GREEDY_PARSING) != 0
  self.ctx.val.dict.max_probes0 = p0
  self.ctx.val.dict.max_probes1 = p1
}

///|
/// Compression stream combining an encoder context with an output.
struct EncoderStream {
  ctx : Ref[EncDeflateContext]
  sink : Sink
  mut finished : Bool
}

///|
/// Compression stream that writes into a fixed-size buffer.
///
/// The buffer must be pre-sized; if it's not large enough to hold the
/// compressed output, `YaziError::Overflow` is raised.
struct EncoderBufStream {
  inner : EncoderStream
}

///|
/// Creates an encoder stream that will append into the specified vector.
pub fn Encoder::stream_into_vec(
  self : Encoder,
  vec : Array[Byte],
) -> EncoderStream {
  // Mimic upstream: creating a stream resets transient state for reuse.
  let zlib = self.ctx.val.zlib
  self.ctx.val.reset(zlib)
  EncoderStream::{ ctx: self.ctx, sink: Sink::new_vec(vec), finished: false }
}

///|
/// Creates an encoder stream that will write into the specified buffer.
pub fn Encoder::stream_into_buf(
  self : Encoder,
  buf : Array[Byte],
) -> EncoderBufStream {
  let zlib = self.ctx.val.zlib
  self.ctx.val.reset(zlib)
  let inner = EncoderStream::{
    ctx: self.ctx,
    sink: Sink::new_buf(buf),
    finished: false,
  }
  EncoderBufStream::{ inner, }
}

///|
/// Writes the specified buffer to the stream, producing compressed data
/// in the output.
pub fn EncoderStream::write(
  self : EncoderStream,
  buf : Bytes,
) -> Unit raise YaziError {
  if self.finished {
    raise YaziError::Finished
  }
  self.ctx.val.deflate(buf, self.sink, false)
}

///|
/// Returns the number of compressed bytes that have been written to the output.
pub fn EncoderStream::compressed_size(self : EncoderStream) -> UInt64 {
  self.sink.written()
}

///|
/// Consumes the stream, flushing any input that may be buffered and any
/// remaining output. Returns the total number of compressed bytes written.
pub fn EncoderStream::finish(self : EncoderStream) -> UInt64 raise YaziError {
  if self.finished {
    raise YaziError::Finished
  }
  self.finished = true
  self.ctx.val.deflate(b"", self.sink, true)
  self.ctx.val.flush_block(self.sink, true)
  self.sink.written()
}

///|
pub fn EncoderBufStream::write(
  self : EncoderBufStream,
  buf : Bytes,
) -> Unit raise YaziError {
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
  self.inner.finish()
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
test "compress/decompress (raw) roundtrip" {
  let input = generate_bytes()
  let compressed = compress(input, Format::Raw, CompressionLevel::Default)
  let (decompressed, _) = decompress(Bytes::from_array(compressed), Format::Raw)
  inspect(bytes_eq(input, decompressed), content="true")
}

///|
test "compress/decompress (raw) roundtrip (NoCompression)" {
  let input = generate_bytes()
  let encoder = Encoder::new()
  encoder.set_format(Format::Raw)
  encoder.set_level(CompressionLevel::NoCompression)
  let out : Array[Byte] = []
  let stream = encoder.stream_into_vec(out)
  stream.write(input)
  stream.finish() |> ignore
  let (decompressed, _) = decompress(Bytes::from_array(out), Format::Raw)
  inspect(bytes_eq(input, decompressed), content="true")
}

///|
test "compress/decompress (raw) roundtrip (Static strategy)" {
  let input = generate_bytes()
  let encoder = Encoder::new()
  encoder.set_format(Format::Raw)
  encoder.set_level(CompressionLevel::Default)
  encoder.set_strategy(CompressionStrategy::Static)
  let out : Array[Byte] = []
  let stream = encoder.stream_into_vec(out)
  stream.write(input)
  stream.finish() |> ignore
  let (decompressed, _) = decompress(Bytes::from_array(out), Format::Raw)
  inspect(bytes_eq(input, decompressed), content="true")
}

///|
test "compress/decompress (raw) roundtrip (no matches expected)" {
  let a : Array[Byte] = []
  for i in 0..<256 {
    a.push(i.to_byte())
  }
  let input = Bytes::from_array(a)
  let compressed = compress(input, Format::Raw, CompressionLevel::Default)
  let (decompressed, _) = decompress(Bytes::from_array(compressed), Format::Raw)
  inspect(bytes_eq(input, decompressed), content="true")
}

///|
test "compression reduces size for Default level (usually)" {
  let input = generate_bytes()
  let compressed = compress(input, Format::Raw, CompressionLevel::Default)
  inspect(compressed.length() < input.length(), content="true")
}

///|
test "compress/decompress streaming (1 byte chunks)" {
  let input = generate_bytes()
  let out : Array[Byte] = []
  let encoder = Encoder::new()
  let stream = encoder.stream_into_vec(out)
  for i in 0..<input.length() {
    stream.write(Bytes::from_array([input[i]]))
  }
  stream.finish() |> ignore
  let (decompressed, _) = decompress(Bytes::from_array(out), Format::Raw)
  inspect(bytes_eq(input, decompressed), content="true")
}

///|
test "compress/decompress streaming (64 byte chunks)" {
  let input = generate_bytes()
  let out : Array[Byte] = []
  let encoder = Encoder::new()
  let stream = encoder.stream_into_vec(out)
  let mut pos = 0
  while pos < input.length() {
    let end = if pos + 64 <= input.length() { pos + 64 } else { input.length() }
    stream.write(input[pos:end].to_bytes())
    pos = end
  }
  stream.finish() |> ignore
  let (decompressed, _) = decompress(Bytes::from_array(out), Format::Raw)
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
