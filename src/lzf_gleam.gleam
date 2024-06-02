/// Library to handle LZF compression and decompression
import gleam/bit_array
import gleam/dict.{type Dict}
import gleam/int
import gleam/result
import lzf_gleam/internal/back_ref.{type BackRef, BackRef}

/// Compress an input string, returns an LZF compressed BitArray
pub fn compress(input: String) -> BitArray {
  input
  |> bit_array.from_string
  |> process_input(0, dict.new(), <<>>, <<>>, 0)
}

/// Decompress a BitArray, this may fail if the LZF compressed BitArray is malformed
pub fn decompress(data: BitArray) -> Result(String, DecompressError) {
  let result =
    data
    |> process_decompress(0, 0, <<>>)
    |> result.try(bit_array.to_string)

  case result {
    Ok(data) -> Ok(data)
    Error(_) -> Error(DecompressError)
  }
}

/// Error occurred deccompressing the BitArray
pub type DecompressError {
  DecompressError
}

fn process_decompress(
  data: BitArray,
  input_pos: Int,
  output_pos: Int,
  output: BitArray,
) -> Result(BitArray, Nil) {
  let cursor = input_pos * 8

  case data {
    <<_:size(cursor), control:1, len:3, offset:12, _:bits>> if control == 1 -> {
      let ref = BackRef(len, offset)

      case process_backreference(output_pos, ref, output) {
        Ok(output) ->
          process_decompress(data, input_pos + 2, output_pos + ref.len, output)
        Error(_) -> Error(Nil)
      }
    }
    <<_:size(cursor), control:1, len:7, _:bits>> if control == 0 -> {
      case process_literals(data, input_pos + 1, len, output) {
        Ok(output) -> {
          let output_pos = output_pos + len
          process_decompress(data, input_pos + len + 1, output_pos, output)
        }
        Error(_) -> Error(Nil)
      }
    }
    _ -> Ok(output)
  }
}

fn process_backreference(
  current_pos: Int,
  ref: BackRef,
  output: BitArray,
) -> Result(BitArray, Nil) {
  let cursor = { current_pos - ref.offset } * 8
  let len_bits = ref.len * 8
  case output {
    <<_:size(cursor), literals:size(len_bits), _:bits>> ->
      Ok(<<output:bits, literals:size(len_bits)>>)
    _ -> {
      Error(Nil)
    }
  }
}

fn process_literals(
  data: BitArray,
  current_pos: Int,
  len: Int,
  output: BitArray,
) -> Result(BitArray, Nil) {
  let cursor = current_pos * 8
  let len_bits = len * 8
  case data {
    <<_:size(cursor), literals:size(len_bits), _:bits>> -> {
      Ok(<<output:bits, literals:size(len_bits)>>)
    }
    _ -> {
      Error(Nil)
    }
  }
}

fn process_input(
  input: BitArray,
  current_pos: Int,
  hash_map: Dict(Int, Int),
  output: BitArray,
  literal_buffer: BitArray,
  literal_count: Int,
) -> BitArray {
  let cursor = current_pos * 8

  case input {
    <<_:size(cursor)>> -> output
    <<_:size(cursor), current:24, _:bits>> -> {
      process_current(
        input,
        current,
        current_pos,
        hash_map,
        output,
        literal_buffer,
        literal_count,
      )
    }
    <<_:size(cursor), rest:bits>> -> {
      let output = flush_literals(output, literal_buffer, literal_count)
      let size = bit_array.byte_size(rest)
      <<output:bits, size:8, rest:bits>>
    }
    _ -> panic as "shouldn't get here"
  }
}

fn process_current(
  input: BitArray,
  current: Int,
  current_pos: Int,
  hash_map: Dict(Int, Int),
  output: BitArray,
  literal_buffer: BitArray,
  literal_count: Int,
) -> BitArray {
  case dict.get(hash_map, current) {
    Ok(match_pos) -> {
      process_match(
        input,
        current,
        current_pos,
        match_pos,
        hash_map,
        output,
        literal_buffer,
        literal_count,
      )
    }
    _ -> {
      let hash_map = dict.insert(hash_map, current, current_pos)

      let first = current |> int.bitwise_shift_right(16)
      process_input(
        input,
        current_pos + 1,
        hash_map,
        output,
        <<literal_buffer:bits, first:8>>,
        literal_count + 1,
      )
    }
  }
}

fn process_match(
  input: BitArray,
  current: Int,
  current_pos: Int,
  match_pos: Int,
  hash_map: Dict(Int, Int),
  output: BitArray,
  literal_buffer: BitArray,
  literal_count: Int,
) -> BitArray {
  case current_pos - match_pos {
    diff if diff < 8191 -> {
      let match_len = get_match_len(input, match_pos, current_pos)
      let token = BackRef(match_len, diff)

      let output = flush_literals(output, literal_buffer, literal_count)
      let token = back_ref.to_bit_array(token)
      process_input(
        input,
        current_pos + match_len,
        hash_map,
        <<output:bits, token:bits>>,
        <<>>,
        0,
      )
    }
    _ -> {
      let hash_map = dict.insert(hash_map, current, current_pos)

      process_input(
        input,
        current_pos + 1,
        hash_map,
        output,
        <<literal_buffer:bits, current:8>>,
        literal_count + 1,
      )
    }
  }
}

fn flush_literals(output: BitArray, buffer: BitArray, count: Int) -> BitArray {
  case count > 0 {
    True -> {
      let control_byte = create_control_byte(count)
      <<output:bits, control_byte:bits, buffer:bits>>
    }
    False -> output
  }
}

fn create_control_byte(count: Int) -> BitArray {
  <<0:1, count:7>>
}

fn get_match_len(input: BitArray, match_pos: Int, current_pos: Int) -> Int {
  let len = bit_array.byte_size(input)

  let s1_result = bit_array.slice(input, match_pos, len - match_pos)
  let s2_result = bit_array.slice(input, current_pos, len - current_pos)

  case s1_result, s2_result {
    Ok(s1), Ok(s2) -> {
      match_len_recursive(s1, s2, 0)
    }
    _, _ -> {
      panic as "Something went wrong slicing the arrays, this shouldn't happen"
    }
  }
}

fn match_len_recursive(seq1: BitArray, seq2: BitArray, acc: Int) -> Int {
  case seq1, seq2 {
    <<first1:8, rest1:bits>>, <<first2:8, rest2:bits>>
      if first1 == first2 && acc < 7
    -> {
      match_len_recursive(rest1, rest2, acc + 1)
    }
    _, _ -> {
      acc
    }
  }
}
