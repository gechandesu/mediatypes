# Media Types

`mediatypes` module allows you to manipulate media types, also known as MIME
types.

Applications can manage types through the `MediaTypeDatabase` abstraction.
Types can be pre-defined in the application, and additional arbitrary
(including custom) types can be loaded at runtime from memory or from files
that adhere to the /etc/mime.types format.

See also:

* https://en.wikipedia.org/wiki/MIME
* https://wiki.debian.org/MIME/etc/mime.types
* https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/MIME_types
* https://www.iana.org/assignments/media-types/media-types.xhtml

## Usage

For example load the system-wide media types mapping file /etc/mime.types and
try to detect the files media type by extension:

```v
import os
import mediatypes

fn main() {
	mut mime_types_file := os.open('/etc/mime.types')!
	defer {
		mime_types_file.close()
	}

	mime_types := mediatypes.load(mut mime_types_file)

	test_data := {
		'style.css':     'text/css'
		'image.png':     'image/png'
		'manifest.json': 'application/json'
	}

	for file_name, expected_type in test_data {
		mime_type := mime_types.lookup(os.file_ext(file_name))
		dump(mime_type)
		assert mime_type.name() == expected_type
	}
}
```

You can add any custom media types and associate media types with file
extensions as you need by manipulating the `MediaTypeDatabase` object:

```v ignore
mut mime_types := mediatypes.new() // or use mediatypes.load()
mime_types.add(mediatypes.MediaType{
	type_name:  'application'
	subtype:    'my-custom-type'
	extensions: ['custom']
})
```

## Embedding media types database into application

To add built-in support for media types to an application, you need to define
constants with type data in the application's source code. For large lists of
types, this is too tedious, so a special code generator script is included
with the `mediatypes` lib.

Use embed_media_types.vsh to get the `.v` file content with embedded media
types database.

The following command will print the .v file content to the standard output:

```
v run embed_media_types.vsh
```

By default script will download the
[mime.types](https://github.com/apache/httpd/blob/trunk/docs/conf/mime.types)
file maintained by Apache HTTP Server project.

Run `v run embed_media_types.vsh -help` to see available script options.

embed_media_types.vsh script skips type definitions for which a list of file
extensions is not specified.

The script output is not formatted be default. Use `v fmt` to format the
generated file.
