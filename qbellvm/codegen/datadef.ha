use ast;
use ast::types;

use io;
use fmt;

fn datadef(codegen: *codegen, handle: io::handle, this: *ast::datadef) (void | io::error) = {
    fmt::fprintf(handle, "%{} = type ", this.name)?;
    fmt::fprint(handle, "<{ ")?;

    for (let i = 0z; i < len(this.definitions); i += 1) {
        const definition = this.definitions[i];

        match(definition) {
            case let this: ast::datadef_value =>
                if (i != 0) {
                    fmt::fprint(handle, ", ")?;
                };

                subty(codegen, handle, this.typ)?;

            case => void;
        };
    };

    fmt::fprintln(handle, " }>")?;

    fmt::fprintf(handle, "@{0} = constant %{0} ", this.name)?;
    fmt::fprint(handle, "<{ ")?;

    for (let i = 0z; i < len(this.definitions); i += 1) {
        const definition = this.definitions[i];

        match(definition) {
            case let this: ast::datadef_value =>
                if (i != 0) {
                    fmt::fprint(handle, ", ")?;
                };

                subty(codegen, handle, this.typ)?;

                fmt::fprint(handle, " ")?;

                match(this.val) {
                    case let this: str => fmt::fprint(handle, this)?;
                    case let this: ast::_const => _const(codegen, handle, this)?;

                    case => void;
                };

            case => void;
        };
    };

    fmt::fprintln(handle, " }>\n")?;
};
