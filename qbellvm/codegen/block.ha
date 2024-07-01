use ast;
use ast::types;

use io;
use fmt;

fn block(codegen: *codegen, handle: io::handle, this: *ast::block) (void | io::error) = {
    fmt::fprintfln(handle, "{}:", this.ids[0])?;

    for (let i = 0z; i < len(this.instructions); i += 1) {
        const instr = this.instructions[i];
        instruction(codegen, handle, &instr)?;
    };
};
