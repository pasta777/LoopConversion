use fmt;
use strings;

export type global_id = str;
export type threaded_id = str;
export type local_id = str;
export type _const = (i64 | f32 | f64 | global_id);
export type dynconst = (_const | threaded_id);
export type val = (dynconst | local_id);

fn const_finalize(this: *_const) void = match(*this) {
    case let this: global_id => free(this);
    case => yield void;
};

fn dynconst_finalize(this: *dynconst) void = match(*this) {
    case let this: threaded_id => free(this);
    case let this: _const => const_finalize(&this);
};

fn val_finalize(this: *val) void = match(*this) {
    case let this: local_id => free(this);
    case let this: dynconst => dynconst_finalize(&this);
};

fn const_print(this: *_const, indent: str = "") str = match(*this) {
    case let this: global_id => yield strings::dup(this);
    case let this: (i64 | f32 | f64) => yield fmt::asprintf("{}", this);
};

fn dynconst_print(this: *dynconst, indent: str = "") str = match(*this) {
    case let this: threaded_id => yield strings::dup(this);
    case let this: _const => yield const_print(&this);
};

fn val_print(this: *val, indent: str = "") str = match(*this) {
    case let this: local_id => yield strings::dup(this);
    case let this: dynconst => yield dynconst_print(&this);
};
