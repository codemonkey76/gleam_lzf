import gleam/bit_array
import gleam/io
import gleam/result
import gleeunit
import gleeunit/should
import lzf

pub fn main() {
  gleeunit.main()
}

pub fn compress_simple_test() {
  bit_array.to_string(<<
    100, 101, 102, 103, 104, 105, 100, 101, 102, 103, 104, 105,
  >>)
  |> result.unwrap("")
  |> lzf.compress
  |> should.equal(<<6, 100, 101, 102, 103, 104, 105, 224, 6>>)
}

pub fn decompress_simple_test() {
  <<6, 100, 101, 102, 103, 104, 105, 224, 6>>
  |> lzf.decompress
  |> should.be_ok
  |> bit_array.from_string
  |> should.equal(<<100, 101, 102, 103, 104, 105, 100, 101, 102, 103, 104, 105>>)
}

const poem = "I do not like green eggs and ham,
I do not like them, Sam-I-am.
I do not like them here or there,
I do not like them anywhere.

I do not like them in a house,
I do not like them with a mouse.
I do not like them in a box,
I do not like them with a fox.
I do not like them in a car,
I do not like them in a bar.
I do not like them in the rain,
I do not like them on a train.

I do not like them, Sam-I-am,
I do not like green eggs and ham.
"

pub fn roundtrip_complex_test() {
  poem
  |> lzf.compress
  |> io.debug
  |> lzf.decompress
  |> should.be_ok
  |> should.equal(poem)
}
