import gleam/bit_array
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/result

pub fn main() {
  let s =
    "I am Sam
Sam I am
That Sam-I-am!
That Sam-I-am!
I do not like
That Sam-I-am!

Do you like
green eggs and ham?

I do not like them,
Sam-I-am.
I do not like
green eggs and ham.

Would you like them
here or there?

I would not like them
here or there.
I would not like them
anywhere.
I do not like
green eggs and ham.
I do not like them,
Sam-I-am.
"
  s |> compress
}

// Compress input using the LZF algorithm
fn compress(input: String) -> String {
  bit_array.from_string(input)
  |> process_input(0, dict.new(), <<>>)
  |> bit_array.to_string
  |> result.unwrap("")
}

fn process_input(
  input: BitArray,
  position: Int,
  matches: Dict(Int, Int),
  output: BitArray,
) -> BitArray {
  case input {
    <<first:8, rest:bits>> -> {
      io.debug(
        "Processing byte: "
        <> int.to_string(first)
        <> " at position: "
        <> int.to_string(position),
      )
      case find_match(position, input, matches) {
        #(len, pos) if len >= 3 -> {
          let new_output_data = output_match(output, len, pos)
          process_input(rest, position + len, matches, new_output_data)
        }
        _ -> {
          let new_matches = update_matches(matches, position, input)
          let output = <<output:bits, first>>
          process_input(rest, position + 1, new_matches, output)
        }
      }
    }
    _ -> output
  }
}

fn update_matches(
  matches: Dict(Int, Int),
  pos: Int,
  input: BitArray,
) -> Dict(Int, Int) {
  case input {
    <<start:16, _>> -> dict.insert(matches, start, pos)
    _ -> matches
  }
}

fn find_match(pos: Int, input: BitArray, matches: Dict(Int, Int)) -> #(Int, Int) {
  case input {
    <<start:16, _>> -> {
      io.debug("Checking match for start: " <> int.to_string(start))
      case dict.get(matches, start) {
        Ok(match_pos) -> #(match_len(input, pos, match_pos), match_pos)
        _ -> #(0, 0)
      }
    }
    _ -> #(0, 0)
  }
}

fn match_len(input: BitArray, position: Int, match_position: Int) -> Int {
  let input_size = bit_array.byte_size(input)
  case
    bit_array.slice(input, position, input_size - position),
    bit_array.slice(input, match_position, input_size - match_position)
  {
    Ok(seq1), Ok(seq2) -> match_len_recursive(seq1, seq2, 0)
    _, _ -> 0
  }
}

fn match_len_recursive(seq1: BitArray, seq2: BitArray, length: Int) -> Int {
  case seq1, seq2 {
    <<first1:8, rest1:bits>>, <<first2:8, rest2:bits>> if first1 == first2 -> {
      match_len_recursive(rest1, rest2, length + 1)
    }
    _, _ -> length
  }
}

fn output_match(
  output_data: BitArray,
  match_len: Int,
  match_pos: Int,
) -> BitArray {
  let control_byte = match_len - 2
  let distance_high = match_pos / 256
  let distance_low = match_pos % 256
  let match_token = <<control_byte:8, distance_high:8, distance_low:8>>
  bit_array.concat([output_data, match_token])
}
