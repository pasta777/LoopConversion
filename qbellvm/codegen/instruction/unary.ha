use ast;

use io;
use fmt;

export fn unary(handle: io::handle, inst: (ast::unary | ast::unary_ret)) (void | io::error) = {
    fmt::fprint(handle, "unary")?;
};