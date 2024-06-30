use strings;

use fmt;

export type var_size = enum { PTR, I1, I8, I16, I32, I64};

export type var = struct {
    name: str,
    _size: var_size,
    count: i64,
};

export fn add(variables: *[]var, name: str, _size: var_size) void = {
    for (let var &.. variables) {
        if (strings::compare(var.name, name) == 0) {
            var.count += 1;
            return;
        };
    };

    append(variables, var {
        name = strings::dup(name),
        count = 0,
        _size = _size
    });
};

export fn count(variables: []var, name: str) i64 = {
    for (let var &.. variables) {
        if (strings::compare(var.name, name) == 0) {
            return var.count;
        };
    };

    return -1;
};

export fn _size(variables: []var, name: str) var_size = {
    for (let var &.. variables) {
        if (strings::compare(var.name, name) == 0) {
            return var._size;
        };
    };

    return var_size::I32;
};