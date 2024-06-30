use ast::types;

export type arg_env = void;
export type arg_variadic = void;
export type arg_value = struct {
    typ: (ast::types::abity | arg_env),
    val: val,
};
export type arg = (arg_variadic | arg_value);

fn arg_finalize(this: *arg) void = {
    match(*this) {
        case let this: arg_value => val_finalize(&this.val);
        case arg_variadic => yield void;
    };
};

export type dbgloc = struct {
    line: i64,
    column: i64
};

export type unary = enum { VASTART };
export type instruction_unary = struct {
    inst: unary,
    first: val,
};

export type binary = enum { STOREB, STORED, STORES, STOREL, STOREW, STOREH };
export type instruction_binary = struct {
    inst: binary,
    first: val,
    second: val,
};

export type ternary = enum { BLIT };
export type instruction_ternary = struct {
    inst: ternary,
    first: val,
    second: val,
    third: val,
};

export type binary_ret = enum { ADD, SUB, DIV, MUL, UDIV, REM, UREM, OR, XOR, AND, SAR, SHR, SHL, CEQD, CEQL, CEQS, CEQW, CGED, CGES, CGTD, CGTS, CLED, CLES, CLTD, CLTS, CNED, CNEL, CNES, CNEW, COD, COS, CSGEL, CSGEW, CSGTL, CSGTW, CSLEL, CSLEW, CSLTL, CSLTW, CUGEL, CUGEW, CUGTL, CUGTW, CULEL, CULEW, CULTL, CULTW, CUOD, CUOS };
export type return_binary = struct {
    inst: binary_ret,
    first: val,
    second: val,
};

export type unary_ret = enum { NEG, LOADD, LOADS, LOADL, LOADSW, LOADUW, LOADW, LOADSH, LOADUH, LOADSB, LOADUB, ALLOC4, ALLOC8, ALLOC16, EXTSW, EXTUW, EXTSH, EXTUH, EXTSB, EXTUB, EXTS, TRUNCD, STOSI, STOUI, DTOSI, DTOUI, SWTOF, UWTOF, SLTOF, ULTOF, CAST, COPY, VAARG };
export type return_unary = struct {
    inst: unary_ret,
    first: val
};

export type phi_val = struct {
    block_id: str,
    val: val,
};

export type phi = struct {
    val: []phi_val
};

export type call = struct {
    func: val,
    args: []arg
};

fn inst_call_finalize(this: *call) void = {
    val_finalize(&this.func);
    for (let arg &.. this.args) {
        arg_finalize(arg);
    };
    free(this.args);
};

export type returnable = (return_unary | return_binary | phi | call);
export type set = struct {
    name: local_id,
    typ: ast::types::abity,
    val: returnable
};

export type jmp = struct {
    block_id: str
};

export type jnz = struct {
    val: val,
    ifz: str,
    ifn: str,
};

export type ret = struct {
    val: (val | void)
};
export type hlt = void;
export type jump = (jmp | jnz | ret | hlt);

export type instruction = (
    instruction_unary   |
    instruction_binary  |
    instruction_ternary |
    call                |
    set                 |
    jump                |
    dbgloc
);

fn inst_set_finalize(this: *set) void = {
    free(this.name);
    match (this.val) {
        case let this: return_unary =>
            val_finalize(&this.first);
        case let this: return_binary =>
            val_finalize(&this.first);
            val_finalize(&this.second);
        case let this: phi =>
            for (let val &.. this.val) {
                free(val.block_id);
                val_finalize(&val.val);
            };
            free(this.val);
        case let this: call =>
            inst_call_finalize(&this);
        case => yield void;
    };
};

fn inst_ret_finalize(this: *ret) void = {
    match (this.val) {
        case let this: val =>
            val_finalize(&this);
        case => yield void;
    };
};

fn inst_finalize(this: *instruction) void = {
    match(*this) {
        case let this: instruction_unary =>
            val_finalize(&this.first);
        case let this: instruction_binary =>
            val_finalize(&this.first);
            val_finalize(&this.second);
        case let this: instruction_ternary =>
            val_finalize(&this.first);
            val_finalize(&this.second);
            val_finalize(&this.third);
        case let this: call =>
            inst_call_finalize(&this);
        case let this: set =>
            inst_set_finalize(&this);
        case let this: jmp =>
            free(this.block_id);
        case let this: jnz =>
            val_finalize(&this.val);
            free(this.ifz);
            free(this.ifn);
        case let this: ret =>
            inst_ret_finalize(&this);
        case => yield void;
    };
};
