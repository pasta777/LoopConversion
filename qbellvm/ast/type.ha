use ast::types;

use io;
use fmt;
use strings;

export type typedef = struct {
    name: str,
    alignment: (i64 | void),
    typ: typedef_type
};

fn typedef_finalize(this: *typedef) void = {
    free(this.name);
    match (this.typ) {
        case let structs: []typedef_struct =>
            free(structs);
        case let unions: []typedef_union =>
            for (let structs .. unions) {
                free(structs);
            };
            free(unions);
        case => yield void;
    };
};

export type typedef_struct = struct {
    typ: ast::types::subty,
    off: (i64 | void),
};
export type typedef_union = []typedef_struct;

export type typedef_type = ([]typedef_struct | []typedef_union | i64);


export fn typedef_struct_print(this: *[]typedef_struct, handle: io::handle, indent: str = "") (io::error | void) = {
    fmt::fprintfln(handle, "{}struct:", indent)?;
    const indent = strings::concat(indent, "\t");
    defer free(indent);

    for (let _struct .. this) {
        const typ = types::subty_print(_struct.typ);
        defer free(typ);

        match (_struct.off) {
            case let off: i64 => fmt::fprintfln(handle, "{}{} {}", indent, typ, off)?;
            case => fmt::fprintfln(handle, "{}{}", indent, typ)?;
        };
    };
};


export fn typedef_union_print(this: *[]typedef_union, handle: io::handle, indent: str = "") (io::error | void) = {
    for (let structs .. this) {
        typedef_struct_print(&structs, handle, indent)?;
    };
};


export fn typedef_type_print(this: *typedef_type, handle: io::handle, indent: str = "") (io::error | void) = {
    match (*this) {
        case let this: i64 => fmt::fprintfln(handle, "{}opaque: {}", indent, this)?;
        case let this: []typedef_struct => typedef_struct_print(&this, handle, indent)?;
        case let this: []typedef_union =>typedef_union_print(&this, handle, indent)?;
    };
};

export fn typedef_print(this: *typedef, handle: io::handle, indent: str = "") (io::error | void) = {
    fmt::fprintfln(handle, "{}typedef {}:", indent, this.name)?;

    const indent = strings::concat(indent, "\t");
    defer free(indent);

    match (this.alignment) {
        case let alignment: i64 =>
            const new = fmt::fprintfln(handle, "{}align {}", indent, alignment)?;

        case => yield void;
    };

    typedef_type_print(&this.typ, handle, indent)?;
};
