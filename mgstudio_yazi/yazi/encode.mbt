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
/// - `CompressionLevel::NoCompression` emits Stored blocks (BTYPE=00).
/// - Other levels emit Static Huffman blocks (BTYPE=01) with basic LZ77 match finding.

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
  match self.encoder.level {
    NoCompression => {
      // Stored blocks streaming. Flush full blocks eagerly (BFINAL=0).
      for i in 0..<buf.length() {
        self.block_buf.push(buf[i])
        if self.block_buf.length() == 65535 {
          self.flush_stored_block(false)
        }
      }
    }
    _ => {
      // Buffer until finish (simpler than upstream's streaming compressor, but
      // still supports streaming writes at the API level).
      for i in 0..<buf.length() {
        self.block_buf.push(buf[i])
      }
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
  match self.encoder.level {
    NoCompression => {
      if self.block_buf.length() > 0 {
        self.flush_stored_block(true)
      } else if self.last_header_pos != -1 {
        // Mark the last block as final (BFINAL=1).
        self.out[self.last_header_pos] = b'\x01'
      } else {
        // No blocks were emitted; emit a single empty final block.
        self.flush_empty_final_block()
      }
    }
    _ => {
      write_deflate_static_huffman(Bytes::from_array(self.block_buf), self.out)
      self.block_buf.clear()
    }
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

// ---- Static Huffman + LZ77 (P1) -------------------------------------------

priv enum Token {
  Lit(Byte)
  Match(Int, Int) // (len, dist)
}

const MIN_MATCH_LEN : Int = 3
const MAX_MATCH_LEN : Int = 258
const DICT_SIZE : Int = 32768
const HASH_BITS : Int = 15
const HASH_SIZE : Int = 1 << HASH_BITS

fn reverse_bits(v0 : UInt, n : Int) -> UInt {
  let mut v = v0
  let mut out : UInt = 0
  for _ in 0..<n {
    out = (out << 1) | (v & 1)
    v = v >> 1
  }
  out
}

fn fixed_litlen(sym : Int) -> (UInt, Int) {
  // Returns (reversed_code, bit_len).
  if sym <= 143 {
    (reverse_bits((sym + 48).reinterpret_as_uint(), 8), 8)
  } else if sym <= 255 {
    (reverse_bits((sym + 256).reinterpret_as_uint(), 9), 9)
  } else if sym <= 279 {
    (reverse_bits((sym - 256).reinterpret_as_uint(), 7), 7)
  } else {
    (reverse_bits((sym - 88).reinterpret_as_uint(), 8), 8)
  }
}

fn fixed_dist(sym : Int) -> (UInt, Int) {
  (reverse_bits(sym.reinterpret_as_uint(), 5), 5)
}

priv struct BitWriter {
  out : Array[Byte]
  mut bitbuf : UInt
  mut bits : Int
}

fn BitWriter::new(out : Array[Byte]) -> BitWriter {
  BitWriter::{ out, bitbuf: 0, bits: 0 }
}

fn BitWriter::write_bits(self : BitWriter, mut v : UInt, mut n : Int) -> Unit {
  while n > 0 {
    self.bitbuf = self.bitbuf | ((v & 1) << self.bits.reinterpret_as_uint())
    self.bits = self.bits + 1
    if self.bits == 8 {
      self.out.push(byte_of_u(self.bitbuf & 0xFF))
      self.bitbuf = 0
      self.bits = 0
    }
    v = v >> 1
    n = n - 1
  }
}

fn BitWriter::write_code(self : BitWriter, code : UInt, n : Int) -> Unit {
  self.write_bits(code, n)
}

fn BitWriter::align_to_byte(self : BitWriter) -> Unit {
  if self.bits != 0 {
    self.out.push(byte_of_u(self.bitbuf & 0xFF))
    self.bitbuf = 0
    self.bits = 0
  }
}

fn hash3(b : Bytes, i : Int) -> Int {
  // Simple 3-byte hash, compatible with HASH_BITS=15.
  let b0 = b[i].to_int()
  let b1 = b[i + 1].to_int()
  let b2 = b[i + 2].to_int()
  (((b0 << 10) ^ (b1 << 5) ^ b2) & (HASH_SIZE - 1))
}

fn find_match(
  input : Bytes,
  pos : Int,
  head : Array[Int],
  prev : Array[Int],
  max_probes : Int,
) -> (Int, Int) {
  let end = input.length()
  if pos + MIN_MATCH_LEN > end {
    return (0, 0)
  }
  let h = hash3(input, pos)
  let mut p = head[h]
  let mut best_len = 0
  let mut best_dist = 0
  let mut probes = 0
  while p != -1 && probes < max_probes {
    let dist = pos - p
    if dist <= 0 || dist > DICT_SIZE {
      break
    }
    let mut l = 0
    while l < MAX_MATCH_LEN && pos + l < end && input[p + l] == input[pos + l] {
      l = l + 1
    }
    if l > best_len {
      best_len = l
      best_dist = dist
      if l == MAX_MATCH_LEN {
        break
      }
    }
    probes = probes + 1
    p = prev[p & (DICT_SIZE - 1)]
  }
  if best_len >= MIN_MATCH_LEN {
    (best_len, best_dist)
  } else {
    (0, 0)
  }
}

fn max_probes_for_level(level : CompressionLevel) -> Int {
  // Approximate upstream `NUM_PROBES` mapping. Higher levels probe more.
  match level {
    BestSpeed => 32
    Default => 128
    BestSize => 512
    Specific(n) => {
      let x = n.reinterpret_as_int()
      if x <= 1 { 6 } else if x <= 3 { 32 } else if x <= 6 { 128 } else if x <= 8 { 512 } else { 1500 }
    }
    _ => 0
  }
}

fn tokenize_lz77(input : Bytes, level : CompressionLevel) -> Array[Token] {
  let out : Array[Token] = []
  let n = input.length()
  let head : Array[Int] = []
  for _ in 0..<HASH_SIZE {
    head.push(-1)
  }
  let prev : Array[Int] = []
  for _ in 0..<DICT_SIZE {
    prev.push(-1)
  }
  let max_probes = max_probes_for_level(level)
  let mut i = 0
  while i < n {
    if i + 2 < n {
      let h = hash3(input, i)
      prev[i & (DICT_SIZE - 1)] = head[h]
      head[h] = i
    }
    let (mlen, mdist) = find_match(input, i, head, prev, max_probes)
    if mlen >= MIN_MATCH_LEN {
      out.push(Token::Match(mlen, mdist))
      // Insert the rest of the match for better compression.
      let mut j = 1
      while j < mlen && i + j + 2 < n {
        let h = hash3(input, i + j)
        prev[(i + j) & (DICT_SIZE - 1)] = head[h]
        head[h] = i + j
        j = j + 1
      }
      i = i + mlen
    } else {
      out.push(Token::Lit(input[i]))
      i = i + 1
    }
  }
  out
}

fn len_code(len : Int) -> (Int, UInt, Int) {
  // Returns (symbol, extra_value, extra_bits).
  if len == 258 {
    return (285, 0, 0)
  }
  let l = len
  if l <= 10 {
    (257 + (l - 3), 0, 0)
  } else if l <= 18 {
    let base = 11 + (((l - 11) / 2) * 2)
    let sym = 265 + ((l - 11) / 2)
    (sym, (l - base).reinterpret_as_uint(), 1)
  } else if l <= 34 {
    let base = 19 + (((l - 19) / 4) * 4)
    let sym = 269 + ((l - 19) / 4)
    (sym, (l - base).reinterpret_as_uint(), 2)
  } else if l <= 66 {
    let base = 35 + (((l - 35) / 8) * 8)
    let sym = 273 + ((l - 35) / 8)
    (sym, (l - base).reinterpret_as_uint(), 3)
  } else if l <= 130 {
    let base = 67 + (((l - 67) / 16) * 16)
    let sym = 277 + ((l - 67) / 16)
    (sym, (l - base).reinterpret_as_uint(), 4)
  } else {
    let base = 131 + (((l - 131) / 32) * 32)
    let sym = 281 + ((l - 131) / 32)
    (sym, (l - base).reinterpret_as_uint(), 5)
  }
}

fn dist_code(dist : Int) -> (Int, UInt, Int) {
  // Returns (symbol, extra_value, extra_bits).
  let d = dist
  if d <= 4 {
    (d - 1, 0, 0)
  } else {
    let mut sym = 0
    let mut extra_bits = 0
    let mut base = 1
    // Build ranges doubling every two symbols.
    for eb in 1..<14 {
      let step = 1 << eb
      // two symbols per extra bit size
      for k in 0..<2 {
        let b = base + k * step
        let e = b + step - 1
        sym = 2 * eb + k + 2
        extra_bits = eb
        if d >= b && d <= e {
          return (sym, (d - b).reinterpret_as_uint(), extra_bits)
        }
      }
      base = base + 2 * step
    }
    (0, 0, 0)
  }
}

fn write_deflate_static_huffman(input : Bytes, out : Array[Byte]) -> Unit {
  let tokens = tokenize_lz77(input, Default)
  let bw = BitWriter::new(out)
  // BFINAL=1, BTYPE=01 (static Huffman)
  bw.write_bits(1, 1)
  bw.write_bits(1, 2)
  for t in tokens {
    match t {
      Token::Lit(b) => {
        let (code, n) = fixed_litlen(b.to_int())
        bw.write_code(code, n)
      }
      Token::Match(len, dist) => {
        let (lsym, lextra, lextra_bits) = len_code(len)
        let (lcode, ln) = fixed_litlen(lsym)
        bw.write_code(lcode, ln)
        if lextra_bits != 0 {
          bw.write_bits(lextra, lextra_bits)
        }
        let (dsym, dextra, dextra_bits) = dist_code(dist)
        let (dcode, dn) = fixed_dist(dsym)
        bw.write_code(dcode, dn)
        if dextra_bits != 0 {
          bw.write_bits(dextra, dextra_bits)
        }
      }
    }
  }
  // End-of-block (256)
  let (eob, eobn) = fixed_litlen(256)
  bw.write_code(eob, eobn)
  bw.align_to_byte()
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
    stream.write(try! input[pos:end])
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
