module mediatypes

import io

// parse_string parses the multiline MIME-types file content e.g. /etc/mime.types.
// The resulting map keys are `type/subtype` media type names.
pub fn parse_string(data string) map[string]MediaType {
	mut result := map[string]MediaType{}
	lines := data.split_into_lines()
	mut media_type := MediaType{}
	for line in lines {
		media_type = parse_line(line) or { continue }
		result[media_type.name()] = media_type
	}
	return result
}

// parse_line parses the MIME-type definition string such as `application/json json`.
pub fn parse_line(line string) !MediaType {
	return parse_line_internal(line)!
}

// parse parses the multiline MIME-types file content e.g. /etc/mime.types.
// The resulting map keys are `type/subtype` media type names.
// Example:
// ```v ignore
// import os
// import mediatypes
// mut file := os.open('/etc/mime.types')!
// defer { file.close() }
// mime_types := mediatypes.parse(mut file)
// println(mime_types)
// ```
pub fn parse(mut r io.Reader) map[string]MediaType {
	mut result := map[string]MediaType{}
	mut media_type := MediaType{}
	mut buf_reader := io.new_buffered_reader(reader: r)
	for {
		line := buf_reader.read_line() or { break }
		media_type = parse_line_internal(line) or { continue }
		result[media_type.name()] = media_type
	}
	return result
}

@[inline]
fn parse_line_internal(line string) !MediaType {
	clean_line := line.trim_space()
	if clean_line.is_blank() || clean_line.starts_with('#') {
		return error('empty input')
	}
	parts := clean_line.fields()
	if parts.len < 1 {
		return error('invalid input: `${line}`')
	}

	full_type := parts[0]
	extensions := if parts.len > 1 { parts[1..] } else { []string{} }

	type_parts := full_type.split('/')
	if type_parts.len != 2 {
		return error('invalid type: `${full_type}`')
	}
	return MediaType{
		@type:      type_parts[0]
		subtype:    type_parts[1]
		extensions: extensions
	}
}

// parse_content_type parses the Content-Type header and returns the media type.
pub fn parse_content_type(header string) !MediaType {
	if !header.is_pure_ascii() {
		return error('ascii text expected')
	}

	mut input := header.trim_space()

	if input.to_lower_ascii().starts_with('content-type:') {
		input = input[13..].trim_space()
	}

	if input == '' {
		return error('empty media type name')
	}

	parts := input.split(';')
	main_parts := parts[0].trim_space().split('/')

	if main_parts.len != 2 {
		return error('invalid type name, type/subtype expected: ${parts[0]}')
	}

	main_type := main_parts[0].trim_space().to_lower()
	sub_type := main_parts[1].trim_space().to_lower()

	if main_type == '' || sub_type == '' {
		return error('invalid type name, type/subtype expected: ${parts[0]}')
	}

	mut params := map[string]string{}

	for i := 1; i < parts.len; i++ {
		param := parts[i].trim_space()
		if param == '' {
			continue // skip empty parameters
		}
		key, mut val := param.split_once('=') or { '', '' }
		if key == '' || val == '' {
			continue // skip invalid parameters
		}
		if val.starts_with('"') && val.ends_with('"') && val.len >= 2 {
			val = val[1..val.len - 1] // trim quotes
		}
		params[key] = val
	}

	return MediaType{
		type:       main_type
		subtype:    sub_type
		parameters: params
	}
}
