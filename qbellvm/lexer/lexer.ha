use io;
use bufio;
use strings;
use regex;
use encoding::utf8;
use strconv;

use fmt;

export type lexer = struct {
    handle:  io::handle,
    lasttok: (token | error),
    line:    int,
    col:     int
};

export fn new(handle: io::handle) lexer = {
    return lexer {
        handle  = handle,
        lasttok = io::EOF,
        line    = 1,
        col     = 1
    };
};

fn freetok(tok: (token | error)) void = {
    match (tok) {
        case let tok: GLOBAL_ID => free(tok);
        case let tok: LOCAL_ID  => free(tok);
        case let tok: TYPE_ID   => free(tok);
        case let tok: BLOCK_ID  => free(tok);
        case let tok: STR       => free(tok);
        case let tok: UNKNOWN   => free(tok);
        case let tok: INVALID   => free(tok);
        case => yield;
    };
};

export fn finalize(lexer: *lexer) void = {
    freetok(lexer.lasttok);
};

const skip = " \t";
fn read_rune(lexer: *lexer) (rune | utf8::invalid | io::error) = {
    for (true) {
        const read = match (bufio::read_rune(lexer.handle)?) {
            case io::EOF => yield '\0';
            case let ch: rune => yield ch;
        };

        lexer.col += 1;
        if (read == '\n') {
            lexer.line += 1;
            lexer.col = 0;
        };

        return read;
    };
};

fn readtok(lexer: *lexer, reg: *regex::regex) (str | utf8::invalid | io::error) = {
    let id: []rune = [];
    defer free(id);

    let test_id: []rune = [];
    defer free(test_id);

    for (true) {
        const read = read_rune(lexer)?;
        if (read == '\0') {
            return strings::fromrunes(id);
        };

        append(test_id, read);
        const test_id = strings::fromrunes(test_id);
        defer free(test_id);

        if (!regex::test(reg, test_id)) {
            bufio::unreadrune(lexer.handle, read);
            return strings::fromrunes(id);
        };

        append(id, read);
    };
};

fn readstr(lexer: *lexer) (token | error | utf8::invalid | io::error) = {
    let runes: []rune = [];
    defer free(runes);

    let no_escape: []rune = [];
    defer free(no_escape);

    for (true) {
        const read = read_rune(lexer)?;

        switch (read) {
            case '\0', '\n' =>
                return strings::fromrunes(no_escape): INVALID;
            case '"' =>
                return strings::fromrunes(runes): STR;
            case '\\' =>
                const read = read_rune(lexer)?;

                append(runes, switch (read) {
                    case '\0', '\n' =>
                        return strings::fromrunes(no_escape): INVALID;
                    case '0' => yield '\0';
                    case 'n' => yield '\n';
                    case 't' => yield '\t';
                    case '"' => yield '"';
                    case => yield read;
                });
                append(no_escape, '\\');
                append(no_escape, read);
            case =>
                append(runes, read);
                append(no_escape, read);
        };
    };
};

fn tokens(tok: str) (token | error) = {
    return switch (tok) {
        case "export"   => yield EXPORT;
        case "thread"   => yield THREAD;
        case "section"  => yield SECTION;
        case "type"     => yield TYPE;
        case "align"    => yield ALIGN;
        case "data"     => yield DATA;
        case "function" => yield FUNCTION;
        case "env"      => yield ENV;
        case "..."      => yield VARIADIC;
        case "dbgfile"  => yield DBGFILE;
        case "dbgloc"   => yield DBGLOC;

        case "sb" => yield SB;
        case "ub" => yield UB;
        case "sh" => yield SH;
        case "uh" => yield UH;

        case "add"  => yield ADD;
        case "and"  => yield AND;
        case "div"  => yield DIV;
        case "mul"  => yield MUL;
        case "neg"  => yield NEG;
        case "or"   => yield OR;
        case "rem"  => yield REM;
        case "sar"  => yield SAR;
        case "shl"  => yield SHL;
        case "shr"  => yield SHR;
        case "sub"  => yield SUB;
        case "udiv" => yield UDIV;
        case "urem" => yield UREM;
        case "xor"  => yield XOR;

        case "alloc16" => yield ALLOC16;
        case "alloc4"  => yield ALLOC4;
        case "alloc8"  => yield ALLOC8;
        case "blit"    => yield BLIT;
        case "loadd"   => yield LOADD;
        case "loadl"   => yield LOADL;
        case "loads"   => yield LOADS;
        case "loadsb"  => yield LOADSB;
        case "loadsh"  => yield LOADSH;
        case "loadsw"  => yield LOADSW;
        case "loadub"  => yield LOADUB;
        case "loaduh"  => yield LOADUH;
        case "loaduw"  => yield LOADUW;
        case "loadw"   => yield LOADW;
        case "storeb"  => yield STOREB;
        case "stored"  => yield STORED;
        case "storeh"  => yield STOREH;
        case "storel"  => yield STOREL;
        case "stores"  => yield STORES;
        case "storew"  => yield STOREW;

		case "ceqd"   => yield CEQD;
		case "ceql"   => yield CEQL;
		case "ceqs"   => yield CEQS;
		case "ceqw"   => yield CEQW;
		case "cged"   => yield CGED;
		case "cges"   => yield CGES;
		case "cgtd"   => yield CGTD;
		case "cgts"   => yield CGTS;
		case "cled"   => yield CLED;
		case "cles"   => yield CLES;
		case "cltd"   => yield CLTD;
		case "clts"   => yield CLTS;
		case "cned"   => yield CNED;
		case "cnel"   => yield CNEL;
		case "cnes"   => yield CNES;
		case "cnew"   => yield CNEW;
		case "cod"    => yield COD;
		case "cos"    => yield COS;
		case "csgel"  => yield CSGEL;
		case "csgew"  => yield CSGEW;
		case "csgtl"  => yield CSGTL;
		case "csgtw"  => yield CSGTW;
		case "cslel"  => yield CSLEL;
		case "cslew"  => yield CSLEW;
		case "csltl"  => yield CSLTL;
		case "csltw"  => yield CSLTW;
		case "cugel"  => yield CUGEL;
		case "cugew"  => yield CUGEW;
		case "cugtl"  => yield CUGTL;
		case "cugtw"  => yield CUGTW;
		case "culel"  => yield CULEL;
		case "culew"  => yield CULEW;
		case "cultl"  => yield CULTL;
		case "cultw"  => yield CULTW;
		case "cuod"   => yield CUOD;
		case "cuos"   => yield CUOS;

		case "dtosi"   => yield DTOSI;
		case "dtoui"   => yield DTOUI;
		case "exts"    => yield EXTS;
		case "extsb"   => yield EXTSB;
		case "extsh"   => yield EXTSH;
		case "extsw"   => yield EXTSW;
		case "extub"   => yield EXTUB;
		case "extuh"   => yield EXTUH;
		case "extuw"   => yield EXTUW;
		case "sltof"   => yield SLTOF;
		case "ultof"   => yield ULTOF;
		case "stosi"   => yield STOSI;
		case "stoui"   => yield STOUI;
		case "swtof"   => yield SWTOF;
		case "uwtof"   => yield UWTOF;
		case "truncd"  => yield TRUNCD;

		case "cast"  => yield CAST;
		case "copy"  => yield COPY;

		case "call"  => yield CALL;

		case "vastart"  => yield VASTART;
		case "vaarg"    => yield VAARG;

		case "phi"  => yield PHI;

		case "jmp"  => yield JMP;
		case "jnz"  => yield JNZ;
		case "ret"  => yield RET;
		case "hlt"  => yield HLT;

        case =>
            fmt::printfln("error, unknown token: {}", tok)!;
            yield strings::dup(tok): UNKNOWN;
    };
};

fn _next(lexer: *lexer) (token | error | utf8::invalid | io::error) = {
    let read = read_rune(lexer)?;

    for (strings::contains(skip, read)) {
        read = read_rune(lexer)?;
    };

    const number_re = regex::compile(`[0-9]+$`)!;
    defer regex::finish(&number_re);

    const char_re = regex::compile(`[A-Za-z_.][A-Za-z0-9_.]*$`)!;
    defer regex::finish(&char_re);

    switch (read) {
        case '#' =>
            for (read != '\n') {
                read = read_rune(lexer)?;

                if (read == '\0') {
                    return io::EOF;
                };
            };

            return NL;
        case '$', '%', ':', '@'=>
            const what = read;
            const id = readtok(lexer, &char_re)?;

            return switch (what) {
                case '$' => yield id: GLOBAL_ID;
                case '%' => yield id: LOCAL_ID;
                case ':' => yield id: TYPE_ID;
                case '@' => yield id: BLOCK_ID;
                case => yield io::EOF;
            };
        case '"' => return readstr(lexer);
        case => yield;
    };

    const id: str = strings::fromrunes([read]);
    defer free(id);

    if (regex::test(&number_re, id)) {
        bufio::unreadrune(lexer.handle, read);
        const id = readtok(lexer, &number_re)?;
        defer free(id);

        return strconv::stoi64(id): NUMBER;
    } else if (regex::test(&char_re, id)) {
        bufio::unreadrune(lexer.handle, read);
        const id = readtok(lexer, &char_re)?;
        defer free(id);

        if (len(id) > 1) {
            return tokens(id);
        };
    };

    if (read == '\0') {
        return io::EOF;
    };

    switch (read) {
        case '\n' => return NL;
        case '{'  => return OPEN_BRACE;
        case '}'  => return CLOSE_BRACE;
        case '('  => return OPEN_BRACKET;
        case ')'  => return CLOSE_BRACKET;
        case 'w'  => return W;
        case 'l'  => return L;
        case 's'  => return S;
        case 'd'  => return D;
        case 'b'  => return B;
        case 'h'  => return H;
        case 'z'  => return Z;
        case '-'  => return MINUS;
        case '+'  => return PLUS;
        case '='  => return EQ;
        case ','  => return COMMA;
        case =>
            fmt::printfln("error, unknown charatcher: {}", read)!;
            return strings::fromrunes([read]): UNKNOWN;
    };
};

export fn next(lexer: *lexer) (token | error | utf8::invalid | io::error) = {
    freetok(lexer.lasttok);

    const tok = _next(lexer);

    lexer.lasttok = match(tok) {
        case let tok: token => yield tok;
        case let tok: error => yield tok;
        case => return tok;
    };

    return lexer.lasttok;
};
