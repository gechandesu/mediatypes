module mediatypes

import io

// parse parses the multiline MIME-types file content e.g. /etc/mime.types.
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
