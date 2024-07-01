use io;
use fmt;
use strings;

export type linkage_export = void;
export type linkage_thread = void;
export type linkage_section = struct {
    name: str,
    flags: (str | void)
};

export type linkage = (linkage_export | linkage_thread | linkage_section);

fn linkage_finalize(this: *linkage) void = {
    match(*this) {
        case let this: linkage_section =>
            free(this.name);
            match(this.flags) {
                case let flags: str => free(flags);
                case => yield void;
            };
        case => yield void;
    };
};

export fn linkage_print(this: *linkage, handle: io::handle, indent: str = "") (void | io::error) = {
    fmt::fprintf(handle, "{}linkage ", indent)?;

    const indent = strings::concat(indent, "\t");
    defer free(indent);

    match (*this) {
        case linkage_export => fmt::fprintln(handle, "export")?;
        case linkage_thread => fmt::fprintln(handle, "thread")?;
        case let this: linkage_section =>
            match (this.flags) {
                case let flags: str => fmt::fprintfln(handle, "name: {}, flags: {}", this.name, flags)?;
                case void => fmt::fprintfln(handle, "name: {}", this.name)?;
            };
    };
};
