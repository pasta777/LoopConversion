use ast;

use io;
use fmt;

export fn binary(handle: io::handle, inst: ast::binary_ret) (void | io::error) = {
    switch (inst) {
        case ast::binary_ret::ADD => fmt::fprint(handle, "add")?;
        case ast::binary_ret::CSLTW => fmt::fprint(handle, "icmp slt")?;
        case => fmt::fprint(handle, "binary")?;
    };
};