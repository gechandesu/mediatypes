import mediatypes

fn test_mediatype() {
	t := mediatypes.MediaType{
		@type:      'text'
		subtype:    'plain'
		parameters: {
			'charset': 'UTF-8'
		}
	}
	assert t.name() == 'text/plain'
	assert t.string() == 'text/plain; charset=UTF-8'
	assert t.string(flags: .compact) == 'text/plain;charset=UTF-8'
	assert t.string(flags: .compact | .lowercase) == 'text/plain;charset=utf-8'
}
