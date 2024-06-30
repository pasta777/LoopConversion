use io;
use fmt;

export type dbgfile = struct {
    file: str
};

fn dbgfile_finalize(this: *dbgfile) void = {
    free(this.file);
};

export fn dbgfile_print(this: *dbgfile, handle: io::handle, indent: str = "") (void | io::error) = {
    fmt::fprintfln(handle, "{}dbgfile: {}", indent, this.file)?;
};
