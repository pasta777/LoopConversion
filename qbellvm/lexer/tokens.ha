use io;
use fmt;

export type NUMBER = i64;
export type S_FLOAT = f32;
export type D_FLOAT = f64;
export type STR = str;

export type GLOBAL_ID = str;
export type LOCAL_ID = str;
export type TYPE_ID = str;
export type BLOCK_ID = str;

export type NL = void;
export type OPEN_BRACE = void;
export type CLOSE_BRACE = void;
export type OPEN_BRACKET = void;
export type CLOSE_BRACKET = void;
export type W = void;
export type L = void;
export type S = void;
export type D = void;
export type B = void;
export type H = void;
export type Z = void;
export type MINUS = void;
export type PLUS = void;
export type EQ = void;
export type COMMA = void;

export type SB = void;
export type UB = void;
export type SH = void;
export type UH = void;

export type EXPORT = void;
export type THREAD = void;
export type SECTION = void;
export type TYPE = void;
export type ALIGN = void;
export type DATA = void;
export type FUNCTION = void;
export type ENV = void;
export type VARIADIC = void;
export type DBGFILE = void;
export type DBGLOC = void;

export type ADD = void;
export type AND = void;
export type DIV = void;
export type MUL = void;
export type NEG = void;
export type OR = void;
export type REM = void;
export type SAR = void;
export type SHL = void;
export type SHR = void;
export type SUB = void;
export type UDIV = void;
export type UREM = void;
export type XOR = void;

export type ALLOC4 = void;
export type ALLOC8 = void;
export type ALLOC16 = void;
export type BLIT = void;
export type LOADD = void;
export type LOADL = void;
export type LOADS = void;
export type LOADSB = void;
export type LOADSH = void;
export type LOADSW = void;
export type LOADUB = void;
export type LOADUH = void;
export type LOADUW = void;
export type LOADW = void;
export type STOREB = void;
export type STORED = void;
export type STOREH = void;
export type STOREL = void;
export type STORES = void;
export type STOREW = void;

export type CEQD = void;
export type CEQL = void;
export type CEQS = void;
export type CEQW = void;
export type CGED = void;
export type CGES = void;
export type CGTD = void;
export type CGTS = void;
export type CLED = void;
export type CLES = void;
export type CLTD = void;
export type CLTS = void;
export type CNED = void;
export type CNEL = void;
export type CNES = void;
export type CNEW = void;
export type CSGEL = void;
export type CSGEW = void;
export type CSGTL = void;
export type CSGTW = void;
export type CSLEL = void;
export type CSLEW = void;
export type CSLTL = void;
export type CSLTW = void;
export type CUGEL = void;
export type CUGEW = void;
export type CUGTL = void;
export type CUGTW = void;
export type CULEL = void;
export type CULEW = void;
export type CULTL = void;
export type CULTW = void;
export type COD = void;
export type COS = void;
export type CUOD = void;
export type CUOS = void;

export type DTOSI = void;
export type DTOUI = void;
export type EXTS = void;
export type EXTSB = void;
export type EXTSH = void;
export type EXTSW = void;
export type EXTUB = void;
export type EXTUH = void;
export type EXTUW = void;
export type SLTOF = void;
export type ULTOF = void;
export type STOSI = void;
export type STOUI = void;
export type SWTOF = void;
export type UWTOF = void;
export type TRUNCD = void;

export type CAST = void;
export type COPY = void;
export type CALL = void;
export type VASTART = void;
export type VAARG = void;

export type PHI = void;
export type JMP = void;
export type JNZ = void;
export type RET = void;
export type HLT = void;

export type UNKNOWN = !str;
export type INVALID = !str;

export type UNARY_RET = (NEG | LOADD | LOADS | LOADL | LOADSW | LOADUW | LOADW | LOADSH | LOADUH | LOADSB | LOADUB | ALLOC4 | ALLOC8 | ALLOC16 | EXTSW | EXTUW | EXTSH | EXTUH | EXTSB | EXTUB | EXTS | TRUNCD | STOSI | STOUI | DTOSI | DTOUI | SWTOF | UWTOF | SLTOF | ULTOF | CAST | COPY | VAARG);
export type BINARY = (STOREB | STORED | STORES | STOREL | STOREW | STOREH);
export type BINARY_RET = (ADD | SUB | DIV | MUL | UDIV | REM | UREM | OR | XOR | AND | SAR | SHR | SHL | CEQD | CEQL | CEQS | CEQW | CGED | CGES | CGTD | CGTS | CLED | CLES | CLTD | CLTS | CNED | CNEL | CNES | CNEW | COD | COS | CSGEL | CSGEW | CSGTL | CSGTW | CSLEL | CSLEW | CSLTL | CSLTW | CUGEL | CUGEW | CUGTL | CUGTW | CULEL | CULEW | CULTL | CULTW | CUOD | CUOS);
export type INST = (VASTART | UNARY_RET | BINARY | BINARY_RET | BLIT);

export type token = (
    NUMBER | S_FLOAT | D_FLOAT | STR |
    GLOBAL_ID | LOCAL_ID | TYPE_ID | BLOCK_ID |
    NL | OPEN_BRACE | CLOSE_BRACE | OPEN_BRACKET | CLOSE_BRACKET | W | L | S | D | B | H | Z | MINUS | PLUS | EQ | COMMA |
    EXPORT | THREAD | SECTION | TYPE | ALIGN | DATA | FUNCTION | ENV | VARIADIC | DBGFILE | DBGLOC |
    SB | UB | SH | UH |
    VASTART | UNARY_RET | BINARY | BINARY_RET | BLIT |
    CALL | PHI | JMP | JNZ | RET | HLT |
    io::EOF
);

export type error = !(UNKNOWN | INVALID);

export fn token_print(tok: (token | error)) void = {
    match (tok) {
        case io::EOF => fmt::println("EOF")!;
        case let id: GLOBAL_ID => fmt::printfln("global: {}", id)!;
        case let id: LOCAL_ID => fmt::printfln("local: {}", id)!;
        case let id: TYPE_ID => fmt::printfln("type: {}", id)!;
        case let id: BLOCK_ID => fmt::printfln("block: {}", id)!;
        case let num: NUMBER => fmt::printfln("number: {}", num: int)!;
        case let string: STR => fmt::printfln("str: {}", string)!;
        case let unkown: UNKNOWN => fmt::printfln("UNKNOWN TOKEN: {}", unkown)!;
        case let invalid: INVALID => fmt::printfln("INVALID: {}", invalid)!;
        case NL => fmt::println("\\n")!;
        case OPEN_BRACE => fmt::println("{")!;
        case CLOSE_BRACE => fmt::println("}")!;
        case OPEN_BRACKET => fmt::println("(")!;
        case CLOSE_BRACKET => fmt::println(")")!;
        case W => fmt::println("w")!;
        case L => fmt::println("l")!;
        case S => fmt::println("s")!;
        case D => fmt::println("d")!;
        case B => fmt::println("b")!;
        case H => fmt::println("h")!;
        case Z => fmt::println("z")!;
        case MINUS => fmt::println("-")!;
        case PLUS => fmt::println("+")!;
        case EQ => fmt::println("=")!;
        case COMMA => fmt::println(",")!;
        case FUNCTION => fmt::println("func")!;
        case DBGFILE => fmt::println("dbg file")!;
        case DATA => fmt::println("data")!;
        case => fmt::println("op")!;
    };
};
