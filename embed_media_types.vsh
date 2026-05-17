#!/usr/bin/env v

import flag
import net.http
import os
import strings
import maps
import mediatypes

const media_types_url = 'https://raw.githubusercontent.com/apache/httpd/refs/heads/trunk/docs/conf/mime.types'

struct Preferences {
mut:
	help             bool     @[xdoc: 'print this help message and exit.']
	output_file      string   @[xdoc: 'output file path, stdout by default.']
	media_types      []string @[xdoc: 'file with extra media types in the /etc/mime.types format']
	no_network       bool     @[xdoc: 'if set do not download mime.types file from network, -mime-types flag must be passed']
	import_stmt      string = 'import mediatypes'   @[xdoc: 'mediatypes module import statement, defaults to `import mediatypes`']
	module_name      string = 'main'   @[xdoc: 'the generated .v file module name, defaults to `main`']
	types_const_name string = 'media_types_list'   @[xdoc: 'name for const that contains map[string]MediaType, defaults to `media_types_list`']
	exts_const_name  string = 'media_types_exts'   @[xdoc: 'name for const that constains map[string]string with file extensions, defaults to `media_types_exts`']
	db_const_name    string = 'media_types_database'   @[xdoc: 'name for const that contains the MediaTypeDatabase, defaults to `media_types_database`']
	types_const_pub  bool     @[xdoc: 'make const with map[string]MediaType public']
	exts_const_pub   bool     @[xdoc: 'make const with file extensions map[string]string public']
	db_const_pub     bool     @[xdoc: 'make const with MediaTypeDatabase public']
	no_db_const      bool     @[xdoc: 'do not write constant with MediaTypeDatabase to generated file']
	file_header      string   @[xdoc: 'header comment for generated .v file, no header by default']
}

fn main() {
	name := arguments()[0]
	mut pref, _ := flag.to_struct[Preferences](arguments(),
		style: .go_flag
		skip:  1
	)!
	help := flag.to_doc[Preferences](
		style:   .v
		options: flag.DocOptions{
			compact: true
		}
	)!
	if pref.help {
		println('Usage: ${name} [OPTION]...')
		println(help)
		exit(0)
	}
	gen(pref) or {
		eprintln('error during gen: ${err}')
		exit(1)
	}
}

fn gen(pref Preferences) ! {
	media_types := collect_media_types(pref)!
	mut buf := strings.new_builder(4096)
	if pref.file_header != '' {
		for line in pref.file_header.split_into_lines() {
			buf.writeln('// ${line}')
		}
	}
	buf.write_string('')
	buf.write_string('module ' + pref.module_name)
	buf.writeln('')
	buf.writeln(pref.import_stmt)
	buf.writeln('')
	if pref.types_const_pub {
		buf.write_string('pub ')
	}
	buf.writeln('const ${pref.types_const_name} = {')
	for name, media_type in media_types {
		if media_type.extensions.len == 0 {
			continue
		}
		buf.writeln("'${name}': mediatypes.MediaType{")
		buf.writeln("type_name: '${media_type.type_name}'")
		buf.writeln("subtype: '${media_type.subtype}'")
		buf.writeln('extensions: ${media_type.extensions}')
		buf.writeln('}')
	}
	buf.writeln('}')
	buf.writeln('')
	if pref.exts_const_pub {
		buf.write_string('pub ')
	}
	buf.writeln('const ${pref.exts_const_name} = {')
	for name, media_type in media_types {
		if media_type.extensions.len == 0 {
			continue
		}
		for ext in media_type.extensions {
			buf.writeln("'${ext}': '${name}'")
		}
	}
	buf.writeln('}')
	buf.writeln('')
	if !pref.no_db_const {
		if pref.db_const_pub {
			buf.write_string('pub ')
		}
		buf.writeln('const ${pref.db_const_name} = mediatypes.construct(${pref.types_const_name}, ${pref.exts_const_name})')
	}

	data := buf.str()
	if pref.output_file == '' {
		println(data)
	} else {
		os.write_file(pref.output_file, data)!
	}
}

fn collect_media_types(pref Preferences) !map[string]mediatypes.MediaType {
	mut types := map[string]mediatypes.MediaType{}
	mut media_type_files := pref.media_types.clone()
	if !pref.no_network {
		temp_file := os.join_path_single(os.temp_dir(), 'mime.types.tmp')
		defer(fn) {
			os.rm(temp_file) or {}
		}
		http.download_file(media_types_url, temp_file)!
		media_type_files << temp_file
	}
	if media_type_files.len == 0 {
		return error('no media types to process, pass -media-types flag or disable -no-network flag')
	}
	for file_name in media_type_files {
		mut file := os.open(file_name) or {
			eprintln('E: cannot read `${file_name}`: ${err}')
			continue
		}
		defer {
			file.close()
		}
		maps.merge_in_place(mut types, mediatypes.parse(mut file))
	}
	return types
}
