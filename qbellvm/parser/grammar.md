# LL(1) QBE grammar

```
program ::= def_array

basety ::= 'w'
basety ::= 'l'
basety ::= 's'
basety ::= 'd'

extty ::= basety
extty ::= 'b'
extty ::= 'h'

subty ::= extty
subty ::= TYPE_ID

subwty ::= SB
subwty ::= UB
subwty ::= SH
subwty ::= UH

abity ::= basety
abity ::= subwty
abity ::= TYPE_ID

abityP ::= abity
abityP ::= ''

const  ::= GLOBAL_ID
const  ::= constP

constP ::= '-' NUMBER
constP ::= NUMBER
constP ::= S_FLOAT
constP ::= D_FLOAT

dynconst ::= const
dynconst ::= THREAD GLOBAL_ID

val ::= dynconst
val ::= LOCAL_ID

valP ::= val
valP ::= ''


nl  ::= '\n' nlP
nlP ::= '\n' nlP
nlP ::= ''


def_array  ::= def def_arrayP
def_arrayP ::= def def_arrayP
def_arrayP ::= ''

def  ::= defP
def  ::= linkage_array defP
def  ::= typedef nlP
def  ::= DBGFILE STR nlP
defP ::= funcdef nlP
defP ::= datadef nlP


linkage_array  ::= linkage linkage_arrayP
linkage_arrayP ::= linkage linkage_arrayP
linkage_arrayP ::= ''

linkage ::= EXPORT nlP
linkage ::= THREAD nlP
linkage ::= SECTION strP nlP

strP ::= str strPP
strPP ::= str
strPP ::= ''

alignment ::= ALIGN NUMBER
alignment ::= ''


datadef ::= DATA GLOBAL_ID '=' alignment '{' datadef_array '}'

datadef_array  ::= datadef_item datadef_arrayP
datadef_arrayP ::= ',' datadef_item datadef_arrayP
datadef_arrayP ::= ''

datadef_item   ::= extty dataval_array
datadef_item   ::= 'z' NUMBER

dataval_array  ::= dataval dataval_arrayP
dataval_arrayP ::= dataval dataval_arrayP
dataval_arrayP ::= ''

dataval ::= GLOBAL_ID dataval_offset
dataval ::= STR
dataval ::= constP

dataval_offset ::= '+' NUMBER
dataval_offset ::= ''


typedef ::= TYPE TYPE_ID '=' alignment '{' typedef_item '}'

typedef_item ::= struct_array
typedef_item ::= union_array
typedef_item ::= NUMBER

struct_array  ::= subty struct_offset struct_arrayP
struct_arrayP ::= ',' subty struct_offset struct_arrayP
struct_arrayP ::= ''

struct_offset ::= NUMBER
struct_offset ::= ''

union_array  ::= '{' struct_array '}' union_arrayP
union_arrayP ::= '{' struct_array '}' union_arrayP
union_arrayP ::= ''


funcdef ::= FUNCTION abityP GLOBAL_ID '(' param_array ')' nlP '{' nl block_array '}'

param_array  ::= ''
param_array  ::= param param_arrayP
param_arrayP ::= ',' param param_arrayP
param_arrayP ::= ''

param ::= abity LOCAL_ID
param ::= ENV LOCAL_ID
param ::= VARIADIC

block_array  ::= block block_arrayP
block_arrayP ::= block block_arrayP
block_arrayP ::= ''


block ::= block_ids inst_array

block_ids  ::= BLOCK_ID nl block_idsP
block_idsP ::= BLOCK_ID nl block_idsP
block_idsP ::= ''

inst_array  ::= inst nl inst_arrayP
inst_array  ::= jump nl
inst_arrayP ::= inst nl inst_arrayP
inst_arrayP ::= jump nl
inst_arrayP ::= ''

inst ::= DBGLOC NUMBER ',' NUMBER
inst ::= unary val
inst ::= binary val ',' val
inst ::= ternary val ',' val ',' val
inst ::= LOCAL_ID '=' basety inst_ret
inst ::= CALL val '(' arg_array ')'

inst_ret ::= unary_ret val
inst_ret ::= binary_ret val ',' val
inst_ret ::= PHI phi_array
inst_ret ::= CALL val '(' arg_array ')'

phi_array ::= BLOCK_ID val phi_arrayP
phi_arrayP ::= ',' BLOCK_ID val phi_arrayP
phi_arrayP ::= ''

arg_array ::= arg arg_arrayP
arg_arrayP ::= ',' arg arg_arrayP
arg_arrayP ::= ''

arg ::= abity val
arg ::= ENV val
arg ::= VARIADIC

jump ::= JMP BLOCK_ID
jump ::= JNZ val ',' BLOCK_ID ',' BLOCK_ID
jump ::= RET valP
jump ::= HLT

unary ::= UNARY_OP
unary_ret ::= UNARYRET_OP
binary ::= BINARY_OP
binary_ret ::= BINARYRET_OP
ternary ::= TERNARY
```

# First/Follow table

| Nonterminal    | Nullable? | First                                                                    | Follow                                                                                                                                                  |
|----------------|-----------|--------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------|
| S              | ✖         | DBGFILE, TYPE, FUNCTION, DATA, EXPORT, THREAD, SECTION                   |                                                                                                                                                         |
| program        | ✖         | DBGFILE, TYPE, FUNCTION, DATA, EXPORT, THREAD, SECTION                   | $                                                                                                                                                       |
| basety         | ✖         | 'w', 'l', 's', 'd'                                                       | PHI, CALL, UNARYRET_OP, BINARYRET_OP, GLOBAL_ID, STR, '-', NUMBER, S_FLOAT, D_FLOAT, LOCAL_ID, THREAD, '}', ','                                         |
| extty          | ✖         | 'w', 'l', 's', 'd', 'b', 'h'                                             | GLOBAL_ID, STR, '-', NUMBER, S_FLOAT, D_FLOAT, '}', ','                                                                                                 |
| subty          | ✖         | 'w', 'l', 's', 'd', 'b', 'h', TYPE_ID                                    | '}', ',', NUMBER                                                                                                                                        |
| subwty         | ✖         | SB, UB, SH, UH                                                           | LOCAL_ID, GLOBAL_ID, THREAD, '-', NUMBER, S_FLOAT, D_FLOAT                                                                                              |
| abity          | ✖         | 'w', 'l', 's', 'd', SB, UB, SH, UH, TYPE_ID                              | LOCAL_ID, GLOBAL_ID, THREAD, '-', NUMBER, S_FLOAT, D_FLOAT                                                                                              |
| abityP         | ✔         | 'w', 'l', 's', 'd', SB, UB, SH, UH, TYPE_ID                              | GLOBAL_ID                                                                                                                                               |
| const          | ✖         | GLOBAL_ID, '-', NUMBER, S_FLOAT, D_FLOAT                                 | '\n', ',', '(', ')'                                                                                                                                     |
| constP         | ✖         | '-', NUMBER, S_FLOAT, D_FLOAT                                            | '}', ',', GLOBAL_ID, STR, '-', NUMBER, S_FLOAT, D_FLOAT, '\n', '(', ')'                                                                                 |
| dynconst       | ✖         | GLOBAL_ID, THREAD, '-', NUMBER, S_FLOAT, D_FLOAT                         | '\n', ',', '(', ')'                                                                                                                                     |
| val            | ✖         | GLOBAL_ID, THREAD, LOCAL_ID, '-', NUMBER, S_FLOAT, D_FLOAT               | '\n', ',', '(', ')'                                                                                                                                     |
| valP           | ✔         | GLOBAL_ID, THREAD, LOCAL_ID, '-', NUMBER, S_FLOAT, D_FLOAT               | '\n'                                                                                                                                                    |
| nl             | ✖         | '\n'                                                                     | BLOCK_ID, DBGLOC, LOCAL_ID, CALL, JMP, JNZ, RET, HLT, UNARY_OP, BINARY_OP, TERNARY, '}'                                                                 |
| nlP            | ✔         | '\n'                                                                     | DBGFILE, TYPE, FUNCTION, DATA, EXPORT, THREAD, SECTION, '{', BLOCK_ID, DBGLOC, LOCAL_ID, CALL, JMP, JNZ, RET, HLT, UNARY_OP, BINARY_OP, TERNARY, '}', $ |
| def_array      | ✖         | DBGFILE, TYPE, FUNCTION, DATA, EXPORT, THREAD, SECTION                   | $                                                                                                                                                       |
| def_arrayP     | ✔         | DBGFILE, TYPE, FUNCTION, DATA, EXPORT, THREAD, SECTION                   | $                                                                                                                                                       |
| def            | ✖         | DBGFILE, TYPE, FUNCTION, DATA, EXPORT, THREAD, SECTION                   | DBGFILE, TYPE, FUNCTION, DATA, EXPORT, THREAD, SECTION, $                                                                                               |
| defP           | ✖         | FUNCTION, DATA                                                           | DBGFILE, TYPE, FUNCTION, DATA, EXPORT, THREAD, SECTION, $                                                                                               |
| linkage_array  | ✖         | EXPORT, THREAD, SECTION                                                  | FUNCTION, DATA                                                                                                                                          |
| linkage_arrayP | ✔         | EXPORT, THREAD, SECTION                                                  | FUNCTION, DATA                                                                                                                                          |
| linkage        | ✖         | EXPORT, THREAD, SECTION                                                  | FUNCTION, DATA, EXPORT, THREAD, SECTION                                                                                                                 |
| strP           | ✖         | str                                                                      | FUNCTION, DATA, EXPORT, THREAD, SECTION, '\n'                                                                                                           |
| strPP          | ✔         | str                                                                      | FUNCTION, DATA, EXPORT, THREAD, SECTION, '\n'                                                                                                           |
| alignment      | ✔         | ALIGN                                                                    | '{'                                                                                                                                                     |
| datadef        | ✖         | DATA                                                                     | DBGFILE, TYPE, FUNCTION, DATA, EXPORT, THREAD, SECTION, '\n', $                                                                                         |
| datadef_array  | ✖         | 'w', 'l', 's', 'd', 'b', 'h', 'z'                                        | '}'                                                                                                                                                     |
| datadef_arrayP | ✔         | ','                                                                      | '}'                                                                                                                                                     |
| datadef_item   | ✖         | 'w', 'l', 's', 'd', 'b', 'h', 'z'                                        | '}', ','                                                                                                                                                |
| dataval_array  | ✖         | GLOBAL_ID, STR, '-', NUMBER, S_FLOAT, D_FLOAT                            | '}', ','                                                                                                                                                |
| dataval_arrayP | ✔         | GLOBAL_ID, STR, '-', NUMBER, S_FLOAT, D_FLOAT                            | '}', ','                                                                                                                                                |
| dataval        | ✖         | GLOBAL_ID, STR, '-', NUMBER, S_FLOAT, D_FLOAT                            | '}', ',', GLOBAL_ID, STR, '-', NUMBER, S_FLOAT, D_FLOAT                                                                                                 |
| dataval_offset | ✔         | '+'                                                                      | '}', ',', GLOBAL_ID, STR, '-', NUMBER, S_FLOAT, D_FLOAT                                                                                                 |
| typedef        | ✖         | TYPE                                                                     | DBGFILE, TYPE, FUNCTION, DATA, EXPORT, THREAD, SECTION, '\n', $                                                                                         |
| typedef_item   | ✖         | NUMBER, 'w', 'l', 's', 'd', 'b', 'h', TYPE_ID, '{'                       | '}'                                                                                                                                                     |
| struct_array   | ✖         | 'w', 'l', 's', 'd', 'b', 'h', TYPE_ID                                    | '}'                                                                                                                                                     |
| struct_arrayP  | ✔         | ','                                                                      | '}'                                                                                                                                                     |
| struct_offset  | ✔         | NUMBER                                                                   | '}', ','                                                                                                                                                |
| union_array    | ✖         | '{'                                                                      | '}'                                                                                                                                                     |
| union_arrayP   | ✔         | '{'                                                                      | '}'                                                                                                                                                     |
| funcdef        | ✖         | FUNCTION                                                                 | DBGFILE, TYPE, FUNCTION, DATA, EXPORT, THREAD, SECTION, '\n', $                                                                                         |
| param_array    | ✔         | 'w', 'l', 's', 'd', SB, UB, SH, UH, TYPE_ID, ENV, VARIADIC               | ')'                                                                                                                                                     |
| param_arrayP   | ✔         | ','                                                                      | ')'                                                                                                                                                     |
| param          | ✖         | 'w', 'l', 's', 'd', SB, UB, SH, UH, TYPE_ID, ENV, VARIADIC               | ')', ','                                                                                                                                                |
| block_array    | ✖         | BLOCK_ID                                                                 | '}'                                                                                                                                                     |
| block_arrayP   | ✔         | BLOCK_ID                                                                 | '}'                                                                                                                                                     |
| block          | ✖         | BLOCK_ID                                                                 | '}', BLOCK_ID                                                                                                                                           |
| block_ids      | ✖         | BLOCK_ID                                                                 | DBGLOC, LOCAL_ID, CALL, JMP, JNZ, RET, HLT, UNARY_OP, BINARY_OP, TERNARY                                                                                |
| block_idsP     | ✔         | BLOCK_ID                                                                 | DBGLOC, LOCAL_ID, CALL, JMP, JNZ, RET, HLT, UNARY_OP, BINARY_OP, TERNARY                                                                                |
| inst_array     | ✖         | DBGLOC, LOCAL_ID, CALL, JMP, JNZ, RET, HLT, UNARY_OP, BINARY_OP, TERNARY | '}', BLOCK_ID                                                                                                                                           |
| inst_arrayP    | ✔         | DBGLOC, LOCAL_ID, CALL, JMP, JNZ, RET, HLT, UNARY_OP, BINARY_OP, TERNARY | '}', BLOCK_ID                                                                                                                                           |
| inst           | ✖         | DBGLOC, LOCAL_ID, CALL, UNARY_OP, BINARY_OP, TERNARY                     | '\n'                                                                                                                                                    |
| inst_ret       | ✖         | PHI, CALL, UNARYRET_OP, BINARYRET_OP                                     | '\n'                                                                                                                                                    |
| phi_array      | ✖         | BLOCK_ID                                                                 | '\n'                                                                                                                                                    |
| phi_arrayP     | ✔         | ','                                                                      | '\n'                                                                                                                                                    |
| arg_array      | ✖         | 'w', 'l', 's', 'd', SB, UB, SH, UH, TYPE_ID, ENV, VARIADIC               | ')'                                                                                                                                                     |
| arg_arrayP     | ✔         | ','                                                                      | ')'                                                                                                                                                     |
| arg            | ✖         | 'w', 'l', 's', 'd', SB, UB, SH, UH, TYPE_ID, ENV, VARIADIC               | ')', ','                                                                                                                                                |
| jump           | ✖         | JMP, JNZ, RET, HLT                                                       | '\n'                                                                                                                                                    |
| unary          | ✖         | UNARY_OP                                                                 | GLOBAL_ID, THREAD, LOCAL_ID, '-', NUMBER, S_FLOAT, D_FLOAT                                                                                              |
| unary_ret      | ✖         | UNARYRET_OP                                                              | GLOBAL_ID, THREAD, LOCAL_ID, '-', NUMBER, S_FLOAT, D_FLOAT                                                                                              |
| binary         | ✖         | BINARY_OP                                                                | GLOBAL_ID, THREAD, LOCAL_ID, '-', NUMBER, S_FLOAT, D_FLOAT                                                                                              |
| binary_ret     | ✖         | BINARYRET_OP                                                             | GLOBAL_ID, THREAD, LOCAL_ID, '-', NUMBER, S_FLOAT, D_FLOAT                                                                                              |
| ternary        | ✖         | TERNARY                                                                  | GLOBAL_ID, THREAD, LOCAL_ID, '-', NUMBER, S_FLOAT, D_FLOAT                                                                                              |
