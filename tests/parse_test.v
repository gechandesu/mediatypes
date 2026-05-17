import mediatypes
import os

fn test_parse_line() {
	media_type_m3u8 :=
		mediatypes.parse_line('application/vnd.apple.mpegurl                   m3u8')!
	assert media_type_m3u8 == mediatypes.MediaType{
		@type:      'application'
		subtype:    'vnd.apple.mpegurl'
		extensions: ['m3u8']
	}
	assert media_type_m3u8.name() == 'application/vnd.apple.mpegurl'

	media_type_xmod :=
		mediatypes.parse_line('audio/x-mod                                     mod ult uni m15 mtm 669 med')!
	assert media_type_xmod == mediatypes.MediaType{
		@type:      'audio'
		subtype:    'x-mod'
		extensions: ['mod', 'ult', 'uni', 'm15', 'mtm', '669', 'med']
	}
	assert media_type_xmod.name() == 'audio/x-mod'
}

fn test_parse_string() {
	data := os.read_file('/etc/mime.types') or { return }
	result := mediatypes.parse_string(data)
	assert result.len > 0
}

fn test_parse() {
	mut file := os.open('/etc/mime.types') or { return }
	result := mediatypes.parse(mut file)
	assert result.len > 0
}
