use codegen::var;

use ast;

use io;
use fmt;


export type codegen = struct {
    current_func: *ast::funcdef,
    variables: []var::var
};

export fn new() codegen = {
    return codegen {
        current_func = null: *ast::funcdef,
        ...
    };
};

export fn program(codegen: *codegen, handle: io::handle, this: *ast::program) (void | io::error) = {
    fmt::fprintfln(handle, "declare i32 @printf(ptr, ...)\n")?;

    for (let definition .. this.definitions) {
        match (definition) {
            case let func: ast::funcdef => funcdef(codegen, handle, &func)?;
            case let data: ast::datadef => datadef(codegen, handle, &data)?;
            case => void;
        };
    };
};

export fn finalize(this: *codegen) void = {
    yield;
};
