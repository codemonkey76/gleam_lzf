import gleam/bit_array
import gleam/int

pub type BackRef {
  BackRef(len: Int, offset: Int)
}

pub fn to_string(ref: BackRef) -> String {
  "len: " <> int.to_string(ref.len) <> ", offset: " <> int.to_string(ref.offset)
}

pub fn to_bit_array(ref: BackRef) -> BitArray {
  <<1:1, ref.len:3, ref.offset:12>>
}

pub fn resolve(
  ref: BackRef,
  data: BitArray,
  current_pos: Int,
) -> Result(String, Nil) {
  case bit_array.slice(data, current_pos - ref.offset, ref.len) {
    Ok(slice) -> {
      bit_array.to_string(slice)
    }
    Error(Nil) -> Error(Nil)
  }
}
