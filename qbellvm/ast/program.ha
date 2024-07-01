use io;
use fmt;
use strings;

export type program = struct {
    definitions: []definition,
};

export fn program_finalize(this: *program) void = {
    for (let i = 0z; i < len(this.definitions); i += 1) {
        match (this.definitions[i]) {
            case let func: funcdef => funcdef_finalize(&func);
            case let data: datadef => datadef_finalize(&data);
            case let typ: typedef =>  typedef_finalize(&typ);
            case let dbg: dbgfile =>  dbgfile_finalize(&dbg);
        };
    };

    free(this.definitions);
};

export fn program_print(this: *program, handle: io::handle, indent: str = "") (void | io::error) = {
    fmt::fprintf(handle, "{}program:\n", indent)?;
    const indent = strings::concat(indent, "\t");
    defer free(indent);

    for (let definition .. this.definitions) {
        match (definition) {
            case let func: funcdef => funcdef_print(&func, handle, indent)?;
            case let data: datadef => datadef_print(&data, handle, indent)?;
            case let typ: typedef  => typedef_print(&typ, handle, indent)?;
            case let dbg: dbgfile  => dbgfile_print(&dbg, handle, indent)?;
        };
    };
};

export type definition = (funcdef | datadef | typedef | dbgfile);
