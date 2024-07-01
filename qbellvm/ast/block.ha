use io;
use fmt;
use strings;

export type block = struct {
    ids: []str,
    instructions: []instruction,
};

fn block_finalize(this: *block) void = {
    for (let i = 0z; i < len(this.ids); i += 1) {
        free(this.ids[i]);
    };
    free(this.ids);

    for (let inst &.. this.instructions) {
        inst_finalize(inst);
    };
    free(this.instructions);
};

fn block_print(this: *block, handle: io::handle, indent: str = "") (void | io::error) = {
    fmt::fprintfln(handle, "{}block:", indent)?;
    const indent = strings::concat(indent, "\t");
    defer free(indent);

    for (let id .. this.ids) {
        fmt::fprintfln(handle, "{}id: {}", indent, id)?;
    };
};