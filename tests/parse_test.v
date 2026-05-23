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

fn test_parse_content_type() {
	test_data_valid := {
		// vfmt off
		'Content-Type: text/plain': mediatypes.MediaType{
			@type:   'text'
			subtype: 'plain'
		}
		'content-type: text/plain': mediatypes.MediaType{
			@type:   'text'
			subtype: 'plain'
		}
		'Content-Type: text/plain; charset=UTF-8': mediatypes.MediaType{
			@type:      'text'
			subtype:    'plain'
			parameters: {
				'charset': 'UTF-8'
			}
		}
		'Content-Type: text/plain; charset="UTF-8"': mediatypes.MediaType{
			@type:      'text'
			subtype:    'plain'
			parameters: {
				'charset': 'UTF-8'
			}
		}
		'Content-Type: text/plain; charset=utf-8; format=flowed; delsp=yes': mediatypes.MediaType{
			@type:      'text'
			subtype:    'plain'
			parameters: {
				'charset': 'utf-8'
				'format':  'flowed'
				'delsp':   'yes'
			}
		}
		// vfmt on
	}
	for input, output in test_data_valid {
		assert mediatypes.parse_content_type(input)! == output
	}
}
