use ast;
use ast::types;

use io;
use fmt;
use strings;

fn funcdef_enter(codegen: *codegen, this: *ast::funcdef) void = {
    codegen.current_func = this;
    codegen.variables = [];
};

fn funcdef_leave(codegen: *codegen) void = {
    for (let i = 0z; i < len(codegen.variables); i += 1) {
        free(codegen.variables[i].name);
    };
    free(codegen.variables);
};

fn funcdef(codegen: *codegen, handle: io::handle, this: *ast::funcdef) (void | io::error) = {
    funcdef_enter(codegen, this);
    defer funcdef_leave(codegen);

    fmt::fprint(handle, "define ")?;

    match (this.ret_type) {
        case let this: types::abity => abity(codegen, handle, this)?;
        case void => fmt::fprint(handle, "void")?;
    };

    fmt::fprintfln(handle, " @{} () {{", this.name)?;

    for (let i = 0z; i < len(this.blocks); i += 1) {
        block(codegen, handle, &this.blocks[i])?;

        if (i < len(this.blocks) - 1) {
            const block = this.blocks[i];
            const next = this.blocks[i + 1];
            const last_inst = block.instructions[len(block.instructions) - 1];

            match (last_inst) {
                case ast::jump => void;
                case =>
                    fmt::fprintfln(handle, "\tbr label %{}", next.ids[0])?;
            };
        };
    };

    fmt::fprintln(handle, "}\n")?;
};
