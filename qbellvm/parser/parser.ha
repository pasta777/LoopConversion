use lexer;
use ast;
use ast::types;
use strings;

use encoding::utf8;
use io;

export type parse_error = !void;
export type error = !(parse_error | int | lexer::error | utf8::invalid | io::error);

export type parser = struct {
    lexer: *lexer::lexer,
    peek: lexer::token,
};

fn new_error(parser: *parser) error = parse_error;

export fn new(lexer: *lexer::lexer) parser = {
    return parser {
        lexer = lexer,
        peek = io::EOF,
    };
};

export fn finalize(parser: *parser) void = void;

fn next(parser: *parser) (lexer::token | error) = {
    parser.peek = lexer::next(parser.lexer)?;
    return parser.peek;
};

export fn parse(parser: *parser) (ast::program | error) = {
    next(parser)?;

    const ast = program(parser)?;

    return match(parser.peek) {
        case io::EOF => yield ast;
        case => yield parse_error;
    };
};

fn program(parser: *parser) (ast::program | error) = match (parser.peek) {
    case (
        lexer::DBGFILE | lexer::TYPE | lexer::FUNCTION | lexer::DATA
        | lexer::EXPORT | lexer::THREAD | lexer::SECTION |
    ) =>
        yield ast::program{
            definitions = def_array(parser)?
        };

    case => yield new_error(parser);
};

fn basety(parser: *parser) (ast::types::basety | error) = match (parser.peek) {
    case lexer::W =>
        next(parser)?;
        yield ast::types::w;
    case lexer::L =>
        next(parser)?;
        yield ast::types::l;
    case lexer::S =>
        next(parser)?;
        yield ast::types::s;
    case lexer::D =>
        next(parser)?;
        yield ast::types::d;

    case => yield new_error(parser);
};

fn extty(parser: *parser) (ast::types::extty | error) = match (parser.peek) {
    case (lexer::W | lexer::L | lexer::S | lexer::D) =>
        yield basety(parser)?;

    case lexer::B =>
        next(parser)?;
        yield ast::types::b;
    case lexer::H =>
        next(parser)?;
        yield ast::types::h;

    case => yield new_error(parser);
};

fn subty(parser: *parser) (ast::types::subty | error) = match (parser.peek) {
    case (lexer::W | lexer::L | lexer::S | lexer::D | lexer::B | lexer::H) =>
        yield extty(parser)?;

    case let id: lexer::TYPE_ID =>
        const id = strings::dup(id);
        next(parser)?;
        yield id: ast::types::type_id;

    case => yield new_error(parser);
};

fn subwty(parser: *parser) (ast::types::subwty | error) = match (parser.peek) {
    case lexer::SB =>
        next(parser)?;
        yield ast::types::sb;
    case lexer::UB =>
        next(parser)?;
        yield ast::types::ub;
    case lexer::SH =>
        next(parser)?;
        yield ast::types::sh;
    case lexer::UH =>
        next(parser)?;
        yield ast::types::uh;

    case => yield new_error(parser);
};

fn abity(parser: *parser) (ast::types::abity | error) = match (parser.peek) {
    case (lexer::SB | lexer::UB | lexer::SH | lexer::UH) =>
        yield subwty(parser)?;

    case (lexer::W | lexer::L | lexer::S | lexer::D) =>
        yield basety(parser)?;

    case let id: lexer::TYPE_ID =>
        const id = strings::dup(id);
        next(parser)?;
        yield id: ast::types::type_id;

    case => yield new_error(parser);
};

fn abityP(parser: *parser) (ast::types::abity | void | error) = match (parser.peek) {
    case (
        lexer::SB | lexer::UB | lexer::SH | lexer::UH |
        lexer::W | lexer::L | lexer::S | lexer::D | lexer::TYPE_ID
    ) =>
        yield abity(parser)?;

    case lexer::GLOBAL_ID =>
        yield void;

    case => yield new_error(parser);
};

fn _const(parser: *parser) (ast::_const | error) = match (parser.peek) {
    case let id: lexer::GLOBAL_ID =>
        const id = strings::dup(id);
        next(parser)?;

        yield id: ast::global_id;

    case (lexer::MINUS | lexer::NUMBER | lexer::S_FLOAT | lexer::D_FLOAT) =>
        yield constP(parser)?;

    case => yield new_error(parser);
};

fn constP(parser: *parser) (ast::_const | error) = match (parser.peek) {
    case lexer::MINUS =>
        next(parser)?;

        const num = match(parser.peek) {
            case let num: lexer::NUMBER => yield num;
            case => return new_error(parser);
        };
        next(parser)?;

        yield -(num: i64);

    case let num: lexer::NUMBER =>
        next(parser)?;
        yield num: i64;

    case let num: lexer::S_FLOAT =>
        next(parser)?;
        yield num: f32;

    case let num: lexer::D_FLOAT =>
        next(parser)?;
        yield num: f64;

    case => yield new_error(parser);
};

fn dynconst(parser: *parser) (ast::dynconst | error) = match (parser.peek) {
    case (lexer::MINUS | lexer::NUMBER | lexer::S_FLOAT | lexer::D_FLOAT | lexer::GLOBAL_ID) =>
        yield _const(parser)?;

    case lexer::THREAD =>
        next(parser)?;

        const id = match(parser.peek) {
            case let id: lexer::GLOBAL_ID => yield strings::dup(id);
            case => return new_error(parser);
        };
        next(parser)?;

        yield id: ast::threaded_id;

    case => yield new_error(parser);
};

fn val(parser: *parser) (ast::val | error) = match (parser.peek) {
    case (
        lexer::MINUS | lexer::NUMBER | lexer::S_FLOAT |
        lexer::D_FLOAT | lexer::GLOBAL_ID | lexer::THREAD
    ) =>
        yield dynconst(parser)?;

    case let id: lexer::LOCAL_ID =>
        const id = strings::dup(id);
        next(parser)?;

        yield id: ast::local_id;

    case => yield new_error(parser);
};

fn valP(parser: *parser) (ast::val | void | error) = match (parser.peek) {
    case (
        lexer::MINUS | lexer::NUMBER | lexer::S_FLOAT | lexer::D_FLOAT |
        lexer::GLOBAL_ID | lexer::THREAD | lexer::LOCAL_ID
    ) =>
        yield val(parser)?;

    case lexer::NL => yield void;
    case => yield new_error(parser);
};


fn nl(parser: *parser) (void | error) = match (parser.peek) {
    case lexer::NL =>
        next(parser)?;
        nlP(parser)?;

    case => yield new_error(parser);
};

fn nlP(parser: *parser) (void | error) = match (parser.peek) {
    case lexer::NL =>
        next(parser)?;
        nlP(parser)?;

    case (
        lexer::DBGFILE | lexer::TYPE | lexer::FUNCTION | lexer::DATA | lexer::EXPORT |
        lexer::THREAD | lexer::SECTION | lexer::OPEN_BRACE | lexer::BLOCK_ID | lexer::DBGLOC |
        lexer::LOCAL_ID | lexer::CALL | lexer::VASTART | lexer::BINARY | lexer::BLIT |
        lexer::CLOSE_BRACE | lexer::JMP | lexer::JNZ | lexer::RET | lexer::HLT |
        io::EOF
    ) => yield void;

    case => yield new_error(parser);
};


fn def_array(parser: *parser) ([]ast::definition | error) = match (parser.peek) {
    case (
        lexer::DBGFILE | lexer::EXPORT | lexer::THREAD | lexer::SECTION |
        lexer::FUNCTION | lexer::DATA | lexer::TYPE
    ) =>
        const new = _def(parser)?;
        let rest = def_arrayP(parser)?;

        append(rest, new);

        const l = len(rest);
        for (let i = 0z; i < l / 2; i += 1) {
            const temp = rest[i];
            rest[i] = rest[l - i - 1];
            rest[l - i - 1] = temp;
        };

        yield rest;
    case => yield new_error(parser);
};

fn def_arrayP(parser: *parser) ([]ast::definition | error) = match (parser.peek) {
    case (
        lexer::DBGFILE | lexer::EXPORT | lexer::THREAD | lexer::SECTION |
        lexer::FUNCTION | lexer::DATA | lexer::TYPE
    ) =>
        const definition = _def(parser)?;

        let definitions = def_arrayP(parser)?;

        append(definitions, definition);

        yield definitions;

    case io::EOF => yield [];
    case => yield new_error(parser);
};

fn _def(parser: *parser) (ast::definition | error) = match (parser.peek) {
    case (lexer::FUNCTION | lexer::DATA) =>
        yield defP(parser)?;

    case (lexer::EXPORT | lexer::THREAD | lexer::SECTION) =>
        const linkage = linkage_array(parser)?;
        const definition = defP(parser)?;

        yield match (definition) {
            case let func: ast::funcdef =>
                func.linkage = linkage;
                yield func;
            case let data: ast::datadef =>
                data.linkage = linkage;
                yield data;
        };

    case lexer::TYPE =>
        const definition = typedef(parser)?;
        nlP(parser)?;

        yield definition;

    case lexer::DBGFILE =>
        next(parser)?;

        const file = match(parser.peek) {
            case let file: lexer::STR => yield strings::dup(file: str);
            case => return new_error(parser);
        };
        next(parser)?;

        nlP(parser)?;

        yield ast::dbgfile {
            file = file
        };

    case => yield new_error(parser);
};

fn defP(parser: *parser) (ast::definition | error) = match (parser.peek) {
    case lexer::FUNCTION =>
        const definition = funcdef(parser)?;
        nlP(parser)?;

        yield definition;
    case lexer::DATA =>
        const definition = datadef(parser)?;
        nlP(parser)?;

        yield definition;

    case => yield new_error(parser);
};


fn linkage_array(parser: *parser) ([]ast::linkage | error) = match (parser.peek) {
    case (lexer::EXPORT | lexer::THREAD | lexer::SECTION) =>
        const new = linkage(parser)?;

        let rest = linkage_arrayP(parser)?;
        append(rest, new);

        const l = len(rest);
        for (let i = 0z; i < l / 2; i += 1) {
            const temp = rest[i];
            rest[i] = rest[l - i - 1];
            rest[l - i - 1] = temp;
        };

        yield rest;

    case => yield new_error(parser);
};

fn linkage_arrayP(parser: *parser) ([]ast::linkage | error) = match (parser.peek) {
    case (lexer::EXPORT | lexer::THREAD | lexer::SECTION) =>
        const link = linkage(parser)?;

        let rest = linkage_arrayP(parser)?;
        append(rest, link);

        yield rest;

    case (lexer::FUNCTION | lexer::DATA) => yield [];
    case => yield new_error(parser);
};

fn linkage(parser: *parser) (ast::linkage | error) = match (parser.peek) {
    case lexer::EXPORT =>
        next(parser)?;

        nlP(parser)?;

        yield ast::linkage_export;

    case lexer::THREAD =>
        next(parser)?;

        nlP(parser)?;

        yield ast::linkage_thread;

    case lexer::SECTION =>
        next(parser)?;
        const strings = strP(parser)?;
        defer free(strings);
        nlP(parser)?;

        yield if (len(strings) == 1) {
            yield ast::linkage_section {
                name = strings[0],
                flags = void
            };
        } else {
            yield ast::linkage_section {
                name = strings[1],
                flags = strings[0]
            };
        };

    case => yield new_error(parser);
};

fn strP(parser: *parser) ([]str | error) = match (parser.peek) {
    case let string: lexer::STR =>
        const string = strings::dup(string);
        next(parser)?;

        let strings = strPP(parser)?;
        append(strings, string);

        yield strings;

    case => yield new_error(parser);
};

fn strPP(parser: *parser) ([]str | error) = match (parser.peek) {
    case let string: lexer::STR =>
        const string = strings::dup(string);
        next(parser)?;

        let strings = []: []str;
        append(strings, string);

        yield strings;

    case (
        lexer::NL | lexer::FUNCTION | lexer::DATA |
        lexer::EXPORT | lexer::THREAD | lexer::SECTION
    ) =>
        yield [];

    case => yield new_error(parser);
};

fn alignment(parser: *parser) (i64 | void | error) = match(parser.peek) {
    case lexer::ALIGN =>
        next(parser)?;

        const alignment = match(parser.peek) {
            case let num: lexer::NUMBER => yield num: i64;
            case => return new_error(parser);
        };
        next(parser)?;

        yield alignment;
    case lexer::OPEN_BRACE => yield void;
    case => yield new_error(parser);
};


fn datadef(parser: *parser) (ast::datadef | error) = match (parser.peek) {
    case lexer::DATA =>
        next(parser)?;

        const name = match(parser.peek) {
            case let id: lexer::GLOBAL_ID => yield strings::dup(id: str);
            case => return new_error(parser);
        };
        next(parser)?;


        match(parser.peek) {
            case lexer::EQ => yield void;
            case => return new_error(parser);
        };
        next(parser)?;

        const alignment = alignment(parser)?;

        match(parser.peek) {
            case lexer::OPEN_BRACE => yield void;
            case => return new_error(parser);
        };
        next(parser)?;

        const items = datadef_array(parser)?;

        match(parser.peek) {
            case lexer::CLOSE_BRACE => yield void;
            case => return new_error(parser);
        };
        next(parser)?;

        yield ast::datadef {
            linkage = [],
            alignment = alignment,
            name = name,
            definitions = items
        };

    case => yield new_error(parser);
};

fn datadef_array(parser: *parser) ([]ast::datadef_item | error) = match (parser.peek) {
    case (lexer::W | lexer::L | lexer::S | lexer::D | lexer::B | lexer::H | lexer::Z) =>
        const new = datadef_item(parser)?;
        defer free(new);

        let rest = datadef_arrayP(parser)?;
        append(rest, new...);

        const l = len(rest);
        for (let i = 0z; i < l / 2; i += 1) {
            const temp = rest[i];
            rest[i] = rest[l - i - 1];
            rest[l - i - 1] = temp;
        };

        yield rest;

    case lexer::CLOSE_BRACE => yield [];
    case => yield new_error(parser);
};

fn datadef_arrayP(parser: *parser) ([]ast::datadef_item | error) = match (parser.peek) {
    case lexer::COMMA =>
        next(parser)?;

        const new = datadef_item(parser)?;
        defer free(new);

        let rest = datadef_arrayP(parser)?;
        append(rest, new...);

        yield rest;

    case lexer::CLOSE_BRACE => yield [];
    case => yield new_error(parser);
};

fn datadef_item(parser: *parser) ([]ast::datadef_item | error) = match (parser.peek) {
    case (lexer::W | lexer::L | lexer::S | lexer::D | lexer::B | lexer::H) =>
        let ret: []ast::datadef_item = [];

        const typ = extty(parser)?;
        let vals = dataval_array(parser)?;
        defer free(vals);

        for (let val .. vals) {
            append(ret, ast::datadef_value {
                typ = typ,
                val = val
            });
        };

        yield ret;

    case lexer::Z =>
        next(parser)?;

        const off = match(parser.peek) {
            case let num: lexer::NUMBER => yield num: i64;
            case => return new_error(parser);
        };
        next(parser)?;

        let ret: []ast::datadef_item = [];
        append(ret, off: ast::datadef_offset);

        yield ret;

    case => yield new_error(parser);
};

fn dataval_array(parser: *parser) ([]ast::dataval | error) = match (parser.peek) {
    case (
        lexer::MINUS | lexer::NUMBER | lexer::S_FLOAT |
        lexer::D_FLOAT | lexer::GLOBAL_ID | lexer::STR
    ) =>
        const val = dataval(parser)?;

        let rest = dataval_arrayP(parser)?;
        append(rest, val);

        const l = len(rest);
        for (let i = 0z; i < l / 2; i += 1) {
            const temp = rest[i];
            rest[i] = rest[l - i - 1];
            rest[l - i - 1] = temp;
        };

        yield rest;

    case => yield new_error(parser);
};

fn dataval_arrayP(parser: *parser) ([]ast::dataval | error) = match (parser.peek) {
    case (
        lexer::MINUS | lexer::NUMBER | lexer::S_FLOAT |
        lexer::D_FLOAT | lexer::GLOBAL_ID | lexer::STR
    ) =>
        const val = dataval(parser)?;

        let rest = dataval_arrayP(parser)?;
        append(rest, val);

        yield rest;

    case (lexer::CLOSE_BRACE | lexer::COMMA) => yield [];
    case => yield new_error(parser);
};

fn dataval(parser: *parser) (ast::dataval | error) = match (parser.peek) {
    case let id: lexer::GLOBAL_ID =>
        const id = strings::dup(id): ast::global_id;
        next(parser)?;

        const off = dataval_offset(parser)?;

        yield ast::dataval_global {
            id = id,
            off = off
        };

    case (lexer::MINUS | lexer::NUMBER | lexer::S_FLOAT | lexer::D_FLOAT) =>
        yield constP(parser)?;

    case let string: lexer::STR =>
        const string = strings::dup(string);
        next(parser)?;

        yield string;

    case => yield new_error(parser);
};

fn dataval_offset(parser: *parser) (i64 | void | error) = match (parser.peek) {
    case lexer::PLUS =>
        next(parser)?;

        const off = match(parser.peek) {
            case let num: lexer::NUMBER => yield num: i64;
            case => return new_error(parser);
        };
        next(parser)?;

        yield off;

    case (
        lexer::MINUS | lexer::NUMBER | lexer::S_FLOAT | lexer::D_FLOAT |
        lexer::GLOBAL_ID | lexer::STR | lexer::CLOSE_BRACE | lexer::COMMA
    ) =>
        yield void;

    case => yield new_error(parser);
};


fn typedef(parser: *parser) (ast::typedef | error) = match (parser.peek) {
    case lexer::TYPE =>
        next(parser)?;

        const name = match(parser.peek) {
            case let id: lexer::TYPE_ID => yield strings::dup(id: str);
            case => return new_error(parser);
        };
        next(parser)?;

        match(parser.peek) {
            case lexer::EQ => yield void;
            case => return new_error(parser);
        };
        next(parser)?;

        const alignment = alignment(parser)?;

        match(parser.peek) {
            case lexer::OPEN_BRACE => yield void;
            case => return new_error(parser);
        };
        next(parser)?;

        const typ = typedef_item(parser)?;

        match(parser.peek) {
            case lexer::CLOSE_BRACE => yield void;
            case => return new_error(parser);
        };
        next(parser)?;

        yield ast::typedef {
            name = name,
            alignment = alignment,
            typ = typ
        };

    case => yield new_error(parser);
};

fn typedef_item(parser: *parser) (ast::typedef_type | error) = match (parser.peek) {
    case (lexer::W | lexer::L | lexer::S | lexer::D | lexer::B | lexer::H | lexer::TYPE_ID) =>
        yield struct_array(parser)?;

    case lexer::OPEN_BRACE =>
        yield union_array(parser)?;

    case let num: lexer::NUMBER =>
        next(parser)?;
        yield num: i64;

    case => yield new_error(parser);
};

fn struct_array(parser: *parser) ([]ast::typedef_struct | error) = match (parser.peek) {
    case (lexer::W | lexer::L | lexer::S | lexer::D | lexer::B | lexer::H | lexer::TYPE_ID) =>
        const typ = subty(parser)?;
        const off = struct_offset(parser)?;

        let rest = struct_arrayP(parser)?;
        append(rest, ast::typedef_struct{
            typ = typ,
            off = off
        });

        // reverse([]ast::typedef_struct)

        yield rest;

    case => yield new_error(parser);
};

fn struct_arrayP(parser: *parser) ([]ast::typedef_struct | error) = match (parser.peek) {
    case lexer::COMMA =>
        next(parser)?;

        const typ = subty(parser)?;
        const off = struct_offset(parser)?;

        let rest = struct_arrayP(parser)?;
        append(rest, ast::typedef_struct{
            typ = typ,
            off = off
        });

        yield rest;

    case lexer::CLOSE_BRACE =>
        yield [];

    case => yield new_error(parser);
};

fn struct_offset(parser: *parser) (i64 | void | error) = match (parser.peek) {
    case let num: lexer::NUMBER =>
        next(parser)?;
        yield num: i64;

    case (lexer::COMMA | lexer::OPEN_BRACE) => yield void;
    case => yield new_error(parser);
};

fn union_array(parser: *parser) ([]ast::typedef_union | error) = match (parser.peek) {
    case lexer::OPEN_BRACE =>
        next(parser)?;

        const _struct = struct_array(parser)?;

        match(parser.peek) {
            case lexer::CLOSE_BRACE => yield void;
            case => return new_error(parser);
        };
        next(parser)?;

        let rest = union_arrayP(parser)?;
        append(rest, _struct);

        const l = len(rest);
        for (let i = 0z; i < l / 2; i += 1) {
            const temp = rest[i];
            rest[i] = rest[l - i - 1];
            rest[l - i - 1] = temp;
        };

        yield rest;

    case => yield new_error(parser);
};

fn union_arrayP(parser: *parser) ([]ast::typedef_union | error) = match (parser.peek) {
    case lexer::OPEN_BRACE =>
        next(parser)?;

        const _struct = struct_array(parser)?;

        match(parser.peek) {
            case lexer::CLOSE_BRACE => yield void;
            case => return new_error(parser);
        };
        next(parser)?;

        let rest = union_arrayP(parser)?;
        append(rest, _struct);

        yield rest;

    case lexer::CLOSE_BRACE => yield [];
    case => yield new_error(parser);
};


fn funcdef(parser: *parser) (ast::funcdef | error) = match (parser.peek) {
    case lexer::FUNCTION =>
        next(parser)?;

        const ret_type = abityP(parser)?;

        const name = match(parser.peek) {
            case let id: lexer::GLOBAL_ID =>
                yield strings::dup(id: str);
            case => return new_error(parser);
        };
        next(parser)?;

        match(parser.peek) {
            case lexer::OPEN_BRACKET => yield void;
            case => return new_error(parser);
        };
        next(parser)?;

        const params = param_array(parser)?;

        match(parser.peek) {
            case lexer::CLOSE_BRACKET => yield void;
            case => return new_error(parser);
        };
        next(parser)?;

        nlP(parser)?;

        match(parser.peek) {
            case lexer::OPEN_BRACE => yield void;
            case => return new_error(parser);
        };
        next(parser)?;

        nl(parser)?;

        const blocks = block_array(parser)?;

        match(parser.peek) {
            case lexer::CLOSE_BRACE => yield void;
            case => return new_error(parser);
        };
        next(parser)?;

        yield ast::funcdef {
            linkage = [],
            ret_type = ret_type,
            name = name,
            params = params,
            blocks = blocks,
        };
    case => yield new_error(parser);
};

fn param_array(parser: *parser) ([]ast::param | error) = match (parser.peek) {
    case (
        lexer::W | lexer::L | lexer::S | lexer::D | lexer::SB | lexer::UB |
        lexer::SH | lexer::UH | lexer::TYPE_ID | lexer::ENV | lexer::VARIADIC
    ) =>
        const new_param = param(parser)?;
        let rest = param_arrayP(parser)?;

        append(rest, new_param);

        const l = len(rest);
        for (let i = 0z; i < l / 2; i += 1) {
            const temp = rest[i];
            rest[i] = rest[l - i - 1];
            rest[l - i - 1] = temp;
        };

        yield rest;

    case lexer::CLOSE_BRACKET => yield [];
    case => yield new_error(parser);
};

fn param_arrayP(parser: *parser) ([]ast::param | error) = match (parser.peek) {
    case lexer::COMMA =>
        next(parser)?;

        const new_param = param(parser)?;
        let rest = param_arrayP(parser)?;

        append(rest, new_param);

        yield rest;
    case lexer::CLOSE_BRACKET => yield [];
    case => yield new_error(parser);
};

fn param(parser: *parser) (ast::param | error) = match (parser.peek) {
    case (
        lexer::W | lexer::L | lexer::S | lexer::D | lexer::SB |
        lexer::UB | lexer::SH | lexer::UH | lexer::TYPE_ID
    ) =>
        const typ = abity(parser)?;

        const name = match(parser.peek) {
            case let id: lexer::LOCAL_ID => yield strings::dup(id);
            case => return new_error(parser);
        };
        next(parser)?;

        yield ast::param_named {
            typ = typ,
            name = name
        };
    case lexer::ENV =>
        next(parser)?;

        const name = match(parser.peek) {
            case let id: lexer::LOCAL_ID => yield strings::dup(id);
            case => return new_error(parser);
        };
        next(parser)?;

        yield ast::param_named {
            typ = ast::param_env,
            name = name
        };

    case lexer::VARIADIC =>
        next(parser)?;

        yield ast::param_variadic;
    case => yield new_error(parser);
};

fn block_array(parser: *parser) ([]ast::block | error) = match (parser.peek) {
    case lexer::BLOCK_ID =>
        const block = block(parser)?;

        let rest = block_arrayP(parser)?;
        append(rest, block);

        const l = len(rest);
        for (let i = 0z; i < l / 2; i += 1) {
            const temp = rest[i];
            rest[i] = rest[l - i - 1];
            rest[l - i - 1] = temp;
        };

        yield rest;
    case => yield new_error(parser);
};

fn block_arrayP(parser: *parser) ([]ast::block | error) = match (parser.peek) {
    case lexer::BLOCK_ID =>
        const block = block(parser)?;

        let rest = block_arrayP(parser)?;
        append(rest, block);

        yield rest;
    case lexer::CLOSE_BRACE => yield [];
    case => yield new_error(parser);
};


fn block(parser: *parser) (ast::block | error) = match (parser.peek) {
    case lexer::BLOCK_ID =>
        const ids = block_ids(parser)?;
        let instructions = inst_array(parser)?;

        yield ast::block {
            ids = ids,
            instructions = instructions
        };
    case => yield new_error(parser);
};

fn block_ids(parser: *parser) ([]str | error) = match (parser.peek) {
    case let id: lexer::BLOCK_ID =>
        const id = strings::dup(id);
        next(parser)?;

        nlP(parser)?;

        let ids = block_idsP(parser)?;
        append(ids, id);

        yield ids;

    case => yield new_error(parser);
};

fn block_idsP(parser: *parser) ([]str | error) = match (parser.peek) {
    case let id: lexer::BLOCK_ID =>
        const id = strings::dup(id);
        next(parser)?;

        nlP(parser)?;

        let ids = block_idsP(parser)?;
        append(ids, id);

        yield ids;

    case (
        lexer::DBGLOC | lexer::LOCAL_ID | lexer::CALL | lexer::JMP | lexer::JNZ |
        lexer::RET | lexer::HLT | lexer::VASTART | lexer::BINARY | lexer::BLIT
    ) => yield [];
    case => yield new_error(parser);
};

fn inst_array(parser: *parser) ([]ast::instruction | error) = match (parser.peek) {
    case (
        lexer::DBGLOC | lexer::CALL | lexer::LOCAL_ID | lexer::VASTART |
        lexer::UNARY_RET | lexer::BINARY | lexer::BINARY_RET | lexer::BLIT
    ) =>
        let instr = inst(parser)?;
        nl(parser)?;
        let rest = inst_arrayP(parser)?;

        append(rest, instr);

        const l = len(rest);
        for (let i = 0z; i < l / 2; i += 1) {
            const temp = rest[i];
            rest[i] = rest[l - i - 1];
            rest[l - i - 1] = temp;
        };

        yield rest;

    case (lexer::JMP | lexer::JNZ | lexer::RET | lexer::HLT) =>
        let instr = jump(parser)?;
        nl(parser)?;

        let instructions = []: []ast::instruction;
        append(instructions, instr);

        yield instructions;

    case => yield new_error(parser);
};

fn inst_arrayP(parser: *parser) ([]ast::instruction | error) = match (parser.peek) {
    case (
        lexer::DBGLOC | lexer::CALL | lexer::LOCAL_ID | lexer::VASTART |
        lexer::UNARY_RET | lexer::BINARY | lexer::BINARY_RET | lexer::BLIT
    ) =>
        let instr = inst(parser)?;
        nl(parser)?;

        let rest = inst_arrayP(parser)?;
        append(rest, instr);

        yield rest;

    case (lexer::JMP | lexer::JNZ | lexer::RET | lexer::HLT) =>
        let instr = jump(parser)?;
        nl(parser)?;

        let instructions = []: []ast::instruction;
        append(instructions, instr);

        yield instructions;
    case (lexer::CLOSE_BRACE | lexer::BLOCK_ID) => yield [];
    case => yield new_error(parser);
};


fn inst(parser: *parser) (ast::instruction | error) = match (parser.peek) {
    case lexer::DBGLOC =>
        next(parser)?;

        const line = match(parser.peek) {
            case let line: lexer::NUMBER => yield line;
            case => return new_error(parser);
        };
        next(parser)?;

        match(parser.peek) {
            case lexer::COMMA => yield void;
            case => return new_error(parser);
        };
        next(parser)?;

        const column = match(parser.peek) {
            case let column: lexer::NUMBER => yield column;
            case => return new_error(parser);
        };
        next(parser)?;

        yield ast::dbgloc {
            line = line,
            column = column
        };

    case lexer::CALL =>
        next(parser)?;

        const func = val(parser)?;

        match(parser.peek) {
            case lexer::OPEN_BRACKET => yield void;
            case => return new_error(parser);
        };
        next(parser)?;

        const args = arg_array(parser)?;

        match(parser.peek) {
            case lexer::CLOSE_BRACKET => yield void;
            case => return new_error(parser);
        };
        next(parser)?;

        yield ast::call {
            func = func,
            args = args
        };

    case lexer::VASTART =>
        const inst = unary(parser)?;
        const first = val(parser)?;

        yield ast::instruction_unary {
            inst = inst,
            first = first
        };

    case lexer::BINARY =>
        const inst = binary(parser)?;

        const val1 = val(parser)?;

        match(parser.peek) {
            case lexer::COMMA => yield void;
            case => return new_error(parser);
        };
        next(parser)?;

        const val2 = val(parser)?;

        yield ast::instruction_binary {
            inst = inst,
            first = val1,
            second = val2
        };

    case lexer::BLIT =>
        const inst = ternary(parser)?;

        const val1 = val(parser)?;

        match(parser.peek) {
            case lexer::COMMA => yield void;
            case => return new_error(parser);
        };
        next(parser)?;

        const val2 = val(parser)?;

        match(parser.peek) {
            case lexer::COMMA => yield void;
            case => return new_error(parser);
        };
        next(parser)?;

        const val3 = val(parser)?;

        yield ast::instruction_ternary {
            inst = inst,
            first = val1,
            second = val2,
            third = val3
        };

    case let id: lexer::LOCAL_ID =>
        const id = strings::dup(id);
        next(parser)?;

        match(parser.peek) {
            case lexer::EQ => yield void;
            case => return new_error(parser);
        };
        next(parser)?;

        // TODO: abity?
        const typ = abity(parser)?;

        const ret = inst_ret(parser)?;

        yield ast::set {
            name = id: ast::local_id,
            typ = typ,
            val = ret
        };

    case => yield new_error(parser);
};

fn inst_ret(parser: *parser) (ast::returnable | error) = match (parser.peek) {
    case lexer::UNARY_RET =>
        const inst = unary_ret(parser)?;
        const first = val(parser)?;

        yield ast::return_unary {
            inst = inst,
            first = first
        };

    case lexer::BINARY_RET =>
        const inst = binary_ret(parser)?;

        const first = val(parser)?;

        match(parser.peek) {
            case lexer::COMMA => yield void;
            case => return new_error(parser);
        };
        next(parser)?;

        const second = val(parser)?;

        yield ast::return_binary {
            inst = inst,
            first = first,
            second = second
        };

    case lexer::PHI =>
        next(parser)?;

        const val = phi_array(parser)?;

        yield ast::phi {
            val = val
        };

    case lexer::CALL =>
        next(parser)?;

        const func = val(parser)?;

        match(parser.peek) {
            case lexer::OPEN_BRACKET => yield void;
            case => return new_error(parser);
        };
        next(parser)?;

        const args = arg_array(parser)?;

        match(parser.peek) {
            case lexer::CLOSE_BRACKET => yield void;
            case => return new_error(parser);
        };
        next(parser)?;

        yield ast::call {
            func = func,
            args = args
        };

    case => yield new_error(parser);
};

fn phi_array(parser: *parser) ([]ast::phi_val | error) = match (parser.peek) {
    case let id: lexer::BLOCK_ID =>
        const id = strings::dup(id);
        next(parser)?;

        const val = val(parser)?;
        let rest = phi_arrayP(parser)?;

        append(rest, ast::phi_val {
            block_id = id,
            val = val
        });

        const l = len(rest);
        for (let i = 0z; i < l / 2; i += 1) {
            const temp = rest[i];
            rest[i] = rest[l - i - 1];
            rest[l - i - 1] = temp;
        };

        yield rest;

    case => yield new_error(parser);
};

fn phi_arrayP(parser: *parser) ([]ast::phi_val | error) = match (parser.peek) {
    case lexer::COMMA =>
        next(parser)?;

        const id = match(parser.peek) {
            case let id: lexer::BLOCK_ID => yield strings::dup(id);
            case => return new_error(parser);
        };
        next(parser)?;

        const val = val(parser)?;
        let rest = phi_arrayP(parser)?;

        append(rest, ast::phi_val {
            block_id = id,
            val = val
        });

        yield rest;

    case lexer::NL => yield [];

    case => yield new_error(parser);
};

fn arg_array(parser: *parser) ([]ast::arg | error) = match (parser.peek) {
    case (
        lexer::W | lexer::L | lexer::S | lexer::D | lexer::SB | lexer::UB |
        lexer::SH | lexer::UH | lexer::TYPE_ID | lexer::ENV | lexer::VARIADIC
    ) =>
        let new = arg(parser)?;
        let rest = arg_arrayP(parser)?;
        append(rest, new);

        const l = len(rest);
        for (let i = 0z; i < l / 2; i += 1) {
            const temp = rest[i];
            rest[i] = rest[l - i - 1];
            rest[l - i - 1] = temp;
        };

        yield rest;
    case => yield new_error(parser);
};

fn arg_arrayP(parser: *parser) ([]ast::arg | error) = match (parser.peek) {
    case lexer::COMMA =>
        next(parser)?;

        let new = arg(parser)?;
        let rest = arg_arrayP(parser)?;
        append(rest, new);

        yield rest;
    case lexer::CLOSE_BRACKET => yield [];

    case => yield new_error(parser);
};

fn arg(parser: *parser) (ast::arg | error) = match (parser.peek) {
    case (
        lexer::W | lexer::L | lexer::S | lexer::D | lexer::SB |
        lexer::UB | lexer::SH | lexer::UH | lexer::TYPE_ID
    ) =>
        const typ = abity(parser)?;
        const val = val(parser)?;

        yield ast::arg_value {
            typ = typ,
            val = val
        };

    case lexer::ENV =>
        next(parser)?;
        const val = val(parser)?;

        yield ast::arg_value {
            typ = ast::arg_env,
            val = val
        };
    case lexer::VARIADIC =>
        next(parser)?;

        yield ast::arg_variadic;

    case => yield new_error(parser);
};

fn jump(parser: *parser) (ast::jump | error) = match (parser.peek) {
        case lexer::JMP =>
        next(parser)?;

        const id = match(parser.peek) {
            case let id: lexer::BLOCK_ID => yield strings::dup(id);
            case => return new_error(parser);
        };
        next(parser)?;

        yield ast::jmp {
            block_id = id
        };

    case lexer::JNZ =>
        next(parser)?;

        const val = val(parser)?;

        match(parser.peek) {
            case lexer::COMMA => yield void;
            case => return new_error(parser);
        };
        next(parser)?;

        const ifz = match(parser.peek) {
            case let id: lexer::BLOCK_ID => yield strings::dup(id);
            case => return new_error(parser);
        };
        next(parser)?;

        match(parser.peek) {
            case lexer::COMMA => yield void;
            case => return new_error(parser);
        };
        next(parser)?;

        const ifn = match(parser.peek) {
            case let id: lexer::BLOCK_ID => yield strings::dup(id);
            case => return new_error(parser);
        };
        next(parser)?;

        yield ast::jnz {
            val = val,
            ifz = ifz,
            ifn = ifn
        };

    case lexer::RET =>
        next(parser)?;

        const val = valP(parser)?;

        yield ast::ret {
            val = val
        };

    case lexer::HLT =>
        next(parser)?;

        yield ast::hlt;
    case => yield new_error(parser);
};


fn unary(parser: *parser) (ast::unary | error) = match (parser.peek) {
    case lexer::VASTART =>
        next(parser)?;
        yield ast::unary::VASTART;
    case => yield new_error(parser);
};

fn unary_ret(parser: *parser) (ast::unary_ret | error) = match (parser.peek) {
    case let inst: lexer::UNARY_RET =>
        next(parser)?;

        yield match (inst) {
            case lexer::NEG     => yield ast::unary_ret::NEG;
            case lexer::LOADD   => yield ast::unary_ret::LOADD;
            case lexer::LOADS   => yield ast::unary_ret::LOADS;
            case lexer::LOADL   => yield ast::unary_ret::LOADL;
            case lexer::LOADSW  => yield ast::unary_ret::LOADSW;
            case lexer::LOADUW  => yield ast::unary_ret::LOADUW;
            case lexer::LOADW   => yield ast::unary_ret::LOADW;
            case lexer::LOADSH  => yield ast::unary_ret::LOADSH;
            case lexer::LOADUH  => yield ast::unary_ret::LOADUH;
            case lexer::LOADSB  => yield ast::unary_ret::LOADSB;
            case lexer::LOADUB  => yield ast::unary_ret::LOADUB;
            case lexer::ALLOC4  => yield ast::unary_ret::ALLOC4;
            case lexer::ALLOC8  => yield ast::unary_ret::ALLOC8;
            case lexer::ALLOC16 => yield ast::unary_ret::ALLOC16;
            case lexer::EXTSW   => yield ast::unary_ret::EXTSW;
            case lexer::EXTUW   => yield ast::unary_ret::EXTUW;
            case lexer::EXTSH   => yield ast::unary_ret::EXTSH;
            case lexer::EXTUH   => yield ast::unary_ret::EXTUH;
            case lexer::EXTSB   => yield ast::unary_ret::EXTSB;
            case lexer::EXTUB   => yield ast::unary_ret::EXTUB;
            case lexer::EXTS    => yield ast::unary_ret::EXTS;
            case lexer::TRUNCD  => yield ast::unary_ret::TRUNCD;
            case lexer::STOSI   => yield ast::unary_ret::STOSI;
            case lexer::STOUI   => yield ast::unary_ret::STOUI;
            case lexer::DTOSI   => yield ast::unary_ret::DTOSI;
            case lexer::DTOUI   => yield ast::unary_ret::DTOUI;
            case lexer::SWTOF   => yield ast::unary_ret::SWTOF;
            case lexer::UWTOF   => yield ast::unary_ret::UWTOF;
            case lexer::SLTOF   => yield ast::unary_ret::SLTOF;
            case lexer::ULTOF   => yield ast::unary_ret::ULTOF;
            case lexer::CAST    => yield ast::unary_ret::CAST;
            case lexer::COPY    => yield ast::unary_ret::COPY;
            case lexer::VAARG   => yield ast::unary_ret::VAARG;
        };
    case => yield new_error(parser);
};

fn binary(parser: *parser) (ast::binary | error) = match (parser.peek) {
    case let inst: lexer::BINARY =>
        next(parser)?;

        yield match (inst) {
            case lexer::STOREB => yield ast::binary::STOREB;
            case lexer::STORED => yield ast::binary::STORED;
            case lexer::STORES => yield ast::binary::STORES;
            case lexer::STOREL => yield ast::binary::STOREL;
            case lexer::STOREW => yield ast::binary::STOREW;
            case lexer::STOREH => yield ast::binary::STOREH;
        };
    case => yield new_error(parser);
};

fn binary_ret(parser: *parser) (ast::binary_ret | error) = match (parser.peek) {
    case let inst: lexer::BINARY_RET =>
        next(parser)?;

        yield match (inst) {
            case lexer::ADD   => yield ast::binary_ret::ADD;
            case lexer::SUB   => yield ast::binary_ret::SUB;
            case lexer::DIV   => yield ast::binary_ret::DIV;
            case lexer::MUL   => yield ast::binary_ret::MUL;
            case lexer::UDIV  => yield ast::binary_ret::UDIV;
            case lexer::REM   => yield ast::binary_ret::REM;
            case lexer::UREM  => yield ast::binary_ret::UREM;
            case lexer::OR    => yield ast::binary_ret::OR;
            case lexer::XOR   => yield ast::binary_ret::XOR;
            case lexer::AND   => yield ast::binary_ret::AND;
            case lexer::SAR   => yield ast::binary_ret::SAR;
            case lexer::SHR   => yield ast::binary_ret::SHR;
            case lexer::SHL   => yield ast::binary_ret::SHL;
            case lexer::CEQD  => yield ast::binary_ret::CEQD;
            case lexer::CEQL  => yield ast::binary_ret::CEQL;
            case lexer::CEQS  => yield ast::binary_ret::CEQS;
            case lexer::CEQW  => yield ast::binary_ret::CEQW;
            case lexer::CGED  => yield ast::binary_ret::CGED;
            case lexer::CGES  => yield ast::binary_ret::CGES;
            case lexer::CGTD  => yield ast::binary_ret::CGTD;
            case lexer::CGTS  => yield ast::binary_ret::CGTS;
            case lexer::CLED  => yield ast::binary_ret::CLED;
            case lexer::CLES  => yield ast::binary_ret::CLES;
            case lexer::CLTD  => yield ast::binary_ret::CLTD;
            case lexer::CLTS  => yield ast::binary_ret::CLTS;
            case lexer::CNED  => yield ast::binary_ret::CNED;
            case lexer::CNEL  => yield ast::binary_ret::CNEL;
            case lexer::CNES  => yield ast::binary_ret::CNES;
            case lexer::CNEW  => yield ast::binary_ret::CNEW;
            case lexer::COD   => yield ast::binary_ret::COD;
            case lexer::COS   => yield ast::binary_ret::COS;
            case lexer::CSGEL => yield ast::binary_ret::CSGEL;
            case lexer::CSGEW => yield ast::binary_ret::CSGEW;
            case lexer::CSGTL => yield ast::binary_ret::CSGTL;
            case lexer::CSGTW => yield ast::binary_ret::CSGTW;
            case lexer::CSLEL => yield ast::binary_ret::CSLEL;
            case lexer::CSLEW => yield ast::binary_ret::CSLEW;
            case lexer::CSLTL => yield ast::binary_ret::CSLTL;
            case lexer::CSLTW => yield ast::binary_ret::CSLTW;
            case lexer::CUGEL => yield ast::binary_ret::CUGEL;
            case lexer::CUGEW => yield ast::binary_ret::CUGEW;
            case lexer::CUGTL => yield ast::binary_ret::CUGTL;
            case lexer::CUGTW => yield ast::binary_ret::CUGTW;
            case lexer::CULEL => yield ast::binary_ret::CULEL;
            case lexer::CULEW => yield ast::binary_ret::CULEW;
            case lexer::CULTL => yield ast::binary_ret::CULTL;
            case lexer::CULTW => yield ast::binary_ret::CULTW;
            case lexer::CUOD  => yield ast::binary_ret::CUOD;
            case lexer::CUOS  => yield ast::binary_ret::CUOS;
        };
    case => yield new_error(parser);
};

fn ternary(parser: *parser) (ast::ternary | error) = match (parser.peek) {
    case lexer::BLIT =>
        next(parser)?;
        yield ast::ternary::BLIT;
    case => yield new_error(parser);
};
