use os;
use lexer;
use parser;
use ast;
use codegen;

use fmt;

export fn main() void = {
    const lexer = lexer::new(os::stdin);
    defer lexer::finalize(&lexer);

    const parser = parser::new(&lexer);
    defer parser::finalize(&parser);

    let program = parser::parse(&parser)!;
    defer ast::program_finalize(&program);

    let generator = codegen::new();
    defer codegen::finalize(&generator);
    codegen::program(&generator, os::stdout, &program)!;
};
