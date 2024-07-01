use ast::types;

use io;
use fmt;

export fn abity(codegen: *codegen, handle: io::handle, this: types::abity) (void | io::error) = match (this) {
    case types::w               => fmt::fprint(handle, "i32")?;
    case types::l               => fmt::fprint(handle, "i64")?;
    case types::s               => fmt::fprint(handle, "f32")?;
    case types::d               => fmt::fprint(handle, "f64")?;
    case types::sb              => fmt::fprint(handle, "sb")?;
    case types::ub              => fmt::fprint(handle, "ub")?;
    case types::sh              => fmt::fprint(handle, "sh")?;
    case types::uh              => fmt::fprint(handle, "uh")?;
    case let id: types::type_id => fmt::fprint(handle, id)?;
};

export fn subty(codegen: *codegen, handle: io::handle, this: types::subty) (void | io::error) = match (this) {
    case types::w               => fmt::fprint(handle, "i32")?;
    case types::l               => fmt::fprint(handle, "i64")?;
    case types::s               => fmt::fprint(handle, "f32")?;
    case types::d               => fmt::fprint(handle, "f64")?;
    case types::b               => fmt::fprint(handle, "i8")?;
    case types::h               => fmt::fprint(handle, "i16")?;
    case let id: types::type_id => fmt::fprint(handle, id)?;
};
