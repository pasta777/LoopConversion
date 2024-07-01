use ast::types;

use io;
use fmt;
use strings;

export type datadef = struct {
    linkage: []linkage,
    name: str,
    alignment: (i64 | void),
    definitions: []datadef_item
};

fn datadef_finalize(this: *datadef) void = {
    for (let link &.. this.linkage) {
        linkage_finalize(link);
    };
    free(this.linkage);

    free(this.name);

    for (let item &.. this.definitions) {
        datadef_item_finalize(item);
    };
    free(this.definitions);
};

export type datadef_offset = i64;
export type datadef_value = struct {
    typ: ast::types::extty,
    val: dataval
};
export type datadef_item = (datadef_offset | datadef_value);

fn datadef_item_finalize(this: *datadef_item) void = {
    match(*this) {
        case let this: datadef_value =>
            match(this.val) {
                case let this: dataval_global =>
                    free(this.id);
                case let this: str =>
                    free(this);
                case let this: _const => const_finalize(&this);
            };
        case datadef_value => yield void;
    };
};

export type dataval_global = struct {
    id:  global_id,
    off: (i64 | void)
};

export type dataval = (dataval_global | str | _const);

export fn datadef_print(this: *datadef, handle: io::handle, indent: str = "") (void | io::error) = {
    fmt::fprintfln(handle, "{}data {}:", indent, this.name)?;
    const indent = strings::concat(indent, "\t");
    defer free(indent);

    for (let linkage &.. this.linkage) {
        linkage_print(linkage, handle, indent)?;
    };

    match(this.alignment) {
        case let alignment: i64 =>
            fmt::fprintfln(handle, "{}alignment {}:", indent, alignment)?;

        case => yield void;
    };

    for (let item .. this.definitions) {
        match(item) {
            case let this: datadef_value =>
                match(this.val) {
                    case let this: dataval_global =>
                        match(this.off) {
                            case let off: i64 =>
                                fmt::fprintfln(handle, "{}global_id {} + {}", indent, this.id, off)?;
                            case =>
                                fmt::fprintfln(handle, "{}global_id {}", indent, this.id)?;
                        };
                    case let this: str =>
                        fmt::fprintfln(handle, "{}str {}", indent, this)?;

                    case let this: _const =>
                        const new = const_print(&this, indent);
                        defer free(new);

                        fmt::fprintfln(handle, "{}const {}", indent, new)?;
                };
            case let off: datadef_offset =>
                fmt::fprintfln(handle, "{}offset {}", indent, off)?;
        };
    };
};
