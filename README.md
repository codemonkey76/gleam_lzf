# lzf

Compress and decompress using LZF algorithm

[![Package Version](https://img.shields.io/hexpm/v/lzf)](https://hex.pm/packages/lzf)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/lzf/)

```sh
gleam add lzf
```
```gleam
import lzf

pub fn main() {
  "abcabcabcabcabcabc" |> compress
  // <<3, 97, 98, 99, 240, 3, 240, 9, 1, 99>> 
}
```

Further documentation can be found at <https://hexdocs.pm/lzf>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
```
