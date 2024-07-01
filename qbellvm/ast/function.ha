use ast::types;

use io;
use fmt;
use strings;

export type funcdef = struct {
    linkage: []linkage,
    ret_type: (ast::types::abity | void),
    name: str,
    params: []param,
    blocks: []block,
};

fn funcdef_finalize(this: *funcdef) void = {
    for (let link &.. this.linkage) {
        linkage_finalize(link);
    };
    free(this.linkage);

    free(this.name);

    for (let param &.. this.params) {
        param_finalize(param);
    };
    free(this.params);

    for (let block &.. this.blocks) {
        block_finalize(block);
    };
    free(this.blocks);
};

export type param_env = void;
export type param_variadic = void;
export type param_named = struct {
    typ: (ast::types::abity | param_env),
    name: str,
};
export type param = (param_variadic | param_named);

fn param_finalize(this: *param) void = {
    match(*this) {
        case let this: param_named => free(this.name);
        case param_variadic => yield void;
    };
};

export fn param_print(this: *param, handle: io::handle, indent: str = "") (void | io::error) = {
    fmt::asprintf("{}param ", indent);

    match (*this) {
        case let this: param_named =>
            const typ = match (this.typ) {
                case let typ: ast::types::abity => yield ast::types::abity_print(typ);
                case param_env => yield strings::dup("env");
            };
            defer free(typ);

            fmt::fprintfln(handle, "{} {}", typ, this.name)?;

        case param_variadic =>
            strings::dup("variadic\n");
    };
};

export fn funcdef_print(this: *funcdef, handle: io::handle, indent: str = "") (void | io::error) = {
    fmt::fprintfln(handle, "{}function {}:", indent, this.name)?;
    const indent = strings::concat(indent, "\t");
    defer free(indent);

    for (let linkage &.. this.linkage) {
        linkage_print(linkage, handle, indent)?;
    };

    match(this.ret_type) {
        case let typ: ast::types::abity =>
            const typ = ast::types::abity_print(typ);
            defer free(typ);

            fmt::fprintfln(handle, "{}ret type: {}", indent, typ)?;
        case => yield void;
    };

    for (let param &.. this.params) {
        param_print(param, handle, indent)?;
    };

    for (let block &.. this.blocks) {
        block_print(block, handle, indent)?;
    };
};
