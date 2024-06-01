# lzf_gleam

Compress and decompress using LZF algorithm

[![Package Version](https://img.shields.io/hexpm/v/lzf_gleam)](https://hex.pm/packages/lzf_gleam)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/lzf_gleam/)

```sh
gleam add lzf_gleam
```

## Quickstart

To use this LZF compression/decompression library, you will need to create a new Gleam project and add lzf dependency

```gleam
import lzf

pub fn main() {
  // Compression:
  "abcabcabcabcabcabc" |> compress
  // <<3, 97, 98, 99, 240, 3, 240, 9, 1, 99>>
  
  // Decompression
  <<3, 97, 98, 99, 240, 3, 240, 9, 1, 99>> |> decompress
  // "abcabcabcabcabcabc"
}
```

Further documentation can be found at <https://hexdocs.pm/lzf_gleam>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
```
