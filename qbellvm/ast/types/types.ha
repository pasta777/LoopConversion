use strings;

export type w = void;
export type l = void;
export type s = void;
export type d = void;
export type b = void;
export type h = void;
export type sb = void;
export type ub = void;
export type sh = void;
export type uh = void;
export type type_id = str;

export type basety = (w | l | s | d);
export type extty = (basety | b | h);
export type subty = (extty | type_id);
export type subwty = (sb | ub | sh | uh);

export type abity = (basety | subwty | type_id);

export fn abity_print(typ: abity) str = match (typ) {
    case w               => yield strings::dup("w");
    case l               => yield strings::dup("l");
    case s               => yield strings::dup("s");
    case d               => yield strings::dup("d");
    case sb              => yield strings::dup("sb");
    case ub              => yield strings::dup("ub");
    case sh              => yield strings::dup("sh");
    case uh              => yield strings::dup("uh");
    case let id: type_id => yield strings::dup(id);
};

export fn subty_print(typ: subty) str = match (typ) {
    case w               => yield strings::dup("w");
    case l               => yield strings::dup("l");
    case s               => yield strings::dup("s");
    case d               => yield strings::dup("d");
    case b               => yield strings::dup("b");
    case h               => yield strings::dup("h");
    case let id: type_id => yield strings::dup(id);
};
