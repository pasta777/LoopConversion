use codegen::var;

use ast;

use io;
use fmt;

fn _const(codegen: *codegen, handle: io::handle, this: ast::_const)  (void | io::error) = match (this) {
    case let this: ast::global_id => fmt::fprintf(handle, "@{}", this)?;
    case let this: (i64 | f32 | f64) => fmt::fprint(handle, this)?;
};

fn dynconst(codegen: *codegen, handle: io::handle, this: ast::dynconst)  (void | io::error) = match (this) {
    case let this: ast::threaded_id => fmt::fprint(handle, this)?;
    case let this: ast::_const => _const(codegen, handle, this)?;
};

fn val_type(codegen: *codegen, handle: io::handle, this: ast::val)  (void | io::error) = match (this) {
    case let this: ast::local_id =>
        switch (var::_size(codegen.variables, this)) {
            case var::var_size::PTR => fmt::fprint(handle, "ptr")?;
            case var::var_size::I1  => fmt::fprint(handle, "i1")?;
            case var::var_size::I8  => fmt::fprint(handle, "i8")?;
            case var::var_size::I16 => fmt::fprint(handle, "i16")?;
            case var::var_size::I32 => fmt::fprint(handle, "i32")?;
            case var::var_size::I64 => fmt::fprint(handle, "i64")?;
        };
    case => void;
};

fn val(codegen: *codegen, handle: io::handle, this: ast::val)  (void | io::error) = match (this) {
    case let this: ast::local_id =>
        fmt::fprintf(handle, "%{}.{}", this, var::count(codegen.variables, this))?;
    case let this: ast::dynconst => dynconst(codegen, handle, this)?;
};
