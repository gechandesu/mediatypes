module mediatypes

import io
import sync

pub const default_media_type = MediaType{
	@type:   'application'
	subtype: 'octet-stream'
}

struct MediaTypeDatabase {
mut:
	mux   &sync.RwMutex
	types map[string]MediaType
	exts  map[string]string
}

@[params]
pub struct MediaTypeAddParams {
pub:
	override bool
}

// add adds the new media type to the database.
pub fn (mut m MediaTypeDatabase) add(typ MediaType, params MediaTypeAddParams) {
	m.mux.lock()
	defer {
		m.mux.unlock()
	}
	media_type_name := typ.name()
	if !params.override {
		if media_type_name in m.types {
			return
		}
	}
	m.types[media_type_name] = typ
	for ext in typ.extensions {
		m.exts[ext] = media_type_name
	}
}

// add_map adds a map of media types to the database.
pub fn (mut m MediaTypeDatabase) add_map(types map[string]MediaType, params MediaTypeAddParams) {
	m.mux.lock()
	defer {
		m.mux.unlock()
	}
	for name, typ in types {
		if !params.override {
			if name in m.types {
				continue
			}
		}
		m.types[name] = typ
		for ext in typ.extensions {
			m.exts[ext] = name
		}
	}
}

// get returns the media type from database by name or none.
pub fn (mut m MediaTypeDatabase) get(name string) ?MediaType {
	m.mux.lock()
	defer {
		m.mux.unlock()
	}
	return m.types[name] or { return none }
}

// has reports is the media type present in the database.
pub fn (mut m MediaTypeDatabase) has(name string) bool {
	m.mux.lock()
	defer {
		m.mux.unlock()
	}
	return name in m.types
}

// delete deletes the media type from database by name.
pub fn (mut m MediaTypeDatabase) delete(name string) {
	m.mux.lock()
	defer {
		m.mux.unlock()
	}
	if name !in m.types {
		return
	}
	typ := m.types[name] or { return }
	for ext in typ.extensions {
		unsafe { m.exts.delete(ext) }
	}
	unsafe { m.types.delete(name) }
}

// lookup returns the media type associated with the `ext` (starting with dot or not).
// If no media type found the default `application/octet-stream` type will be returned.
pub fn (mut m MediaTypeDatabase) lookup(ext string) MediaType {
	return m.lookup_opt(ext) or { default_media_type }
}

// lookup_opt returns the media type associated with the `ext` (starting with dot or not)
// or none if no associated media type found.
pub fn (mut m MediaTypeDatabase) lookup_opt(ext string) ?MediaType {
	m.mux.lock()
	defer {
		m.mux.unlock()
	}
	mut type_name := ''
	if ext.starts_with('.') {
		type_name = m.exts[ext.all_after('.')] or { return none }
	} else {
		type_name = m.exts[ext] or { return none }
	}
	media_type := m.types[type_name] or { return none }
	return media_type
}

// new creates empty media type database.
pub fn new() &MediaTypeDatabase {
	return &MediaTypeDatabase{
		mux: sync.new_rwmutex()
	}
}

// load creates the new media types database from reader.
pub fn load(mut r io.Reader) &MediaTypeDatabase {
	mut db := new()
	mut media_type := MediaType{}
	mut buf_reader := io.new_buffered_reader(reader: r)
	for {
		line := buf_reader.read_line() or { break }
		media_type = parse_line_internal(line) or { continue }
		media_type_name := media_type.name()
		db.types[media_type_name] = media_type
		for ext in media_type.extensions {
			db.exts[ext] = media_type_name
		}
	}
	return db
}

// construct creates the new media type database initialized with existing types and exts maps.
//
// The `type/subtype` media type name is expected in `types` map key. `exts` map should contain
// key-value pairs where key is file extension without leading dot and value is a `type/subtype`
// media type name.
pub fn construct(types map[string]MediaType, exts map[string]string) &MediaTypeDatabase {
	return &MediaTypeDatabase{
		mux:   sync.new_rwmutex()
		types: types
		exts:  exts
	}
}
