module mediatypes

pub struct MediaType {
pub:
	@type      string
	subtype    string
	extensions []string
	parameters map[string]string
}

// name returns the name of media type as `type/subtype` string.
pub fn (t MediaType) name() string {
	return t.@type + '/' + t.subtype
}

@[params]
pub struct MediaTypeFormatParams {
pub:
	flags MediaTypeStringOpt
}

@[flag]
pub enum MediaTypeStringOpt {
	default
	lowercase // force lower case.
	compact   // eliminate the spaces from string.
}

// string returns the string with media type name with parameters suitable for use
// as HTTP or email Content-Type header value. Example: `text/plain; charset=UTF-8`.
// See also `parse_content_type()`.
pub fn (t MediaType) string(params MediaTypeFormatParams) string {
	mut res := t.name()
	mut sep := '; '
	if params.flags.has(.compact) {
		sep = ';'
	}
	for name, value in t.parameters {
		res += sep + name + '=' + value
	}
	if params.flags.has(.lowercase) {
		return res.to_lower_ascii()
	}
	return res
}
