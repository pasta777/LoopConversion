use codegen::var;
use codegen::instruction;

use ast;
use ast::types;

use io;
use fmt;

fn instruction(codegen: *codegen, handle: io::handle, this: *ast::instruction) (void | io::error) = {
    match(*this) {
        // case ast::instruction_unary => void;
        case let this: ast::instruction_binary => binary(codegen, handle, &this)?;
        // case ast::instruction_ternary => void;
        // case ast::call => void;
        case let this: ast::set => set(codegen, handle, &this)?;
        case let this: ast::jump => jump(codegen, handle, &this)?;
        // case ast::dbgloc => void;
        case => fmt::fprintln(handle, "\tinstr")?;
    };
};

fn binary(codegen: *codegen, handle: io::handle, this: *ast::instruction_binary) (void | io::error) = {
    switch (this.inst) {
        case ast::binary::STOREW =>
            fmt::fprint(handle, "\tstore i32 ")?;
            val(codegen, handle, this.first)?;
            fmt::fprintf(handle, ", ")?;
            val_type(codegen, handle, this.second)?;
            fmt::fprintf(handle, " ")?;
            val(codegen, handle, this.second)?;
            fmt::fprintf(handle, ", align 4")?;
        case => void;
    };

    fmt::fprintln(handle)?;
};

fn set(codegen: *codegen, handle: io::handle, this: *ast::set) (void | io::error) = {
    const count = var::count(codegen.variables, this.name);

    fmt::fprintf(handle, "\t%{}.{} = ", this.name, count + 1)?;
    match (this.val) {
        case let inst: ast::return_unary =>
            switch (inst.inst) {
                case ast::unary_ret::ALLOC4, ast::unary_ret::ALLOC8, ast::unary_ret::ALLOC16 =>
                    alloca(codegen, handle, &inst)?;
                    var::add(&codegen.variables, this.name, var::var_size::PTR);
                case ast::unary_ret::LOADW =>
                    fmt::fprintf(handle, "load i32, ")?;
                    val_type(codegen, handle, inst.first)?;
                    fmt::fprintf(handle, " ")?;
                    val(codegen, handle, inst.first)?;
                    fmt::fprintf(handle, ", align 4")?;

                    var::add(&codegen.variables, this.name, var::var_size::I32);
                case =>
                    instruction::unary(handle, inst.inst)?;
                    fmt::fprint(handle, " ")?;
                    abity(codegen, handle, this.typ)?;

                    var::add(&codegen.variables, this.name, var::var_size::I8);
            };
        case let inst: ast::return_binary =>
            instruction::binary(handle, inst.inst)?;
            fmt::fprint(handle, " ")?;
            val_type(codegen, handle, inst.first)?;
            fmt::fprint(handle, " ")?;
            val(codegen, handle, inst.first)?;
            fmt::fprint(handle, ", ")?;
            val(codegen, handle, inst.second)?;

            switch (inst.inst) {
                case ast::binary_ret::CSLTW =>
                    var::add(&codegen.variables, this.name, var::var_size::I1);
                case => var::add(&codegen.variables, this.name, var::var_size::I32);
            };

        case let inst: ast::call =>
            fmt::fprint(handle, "call")?;
            fmt::fprint(handle, " ")?;
            abity(codegen, handle, this.typ)?;
            fmt::fprint(handle, " ")?;
            val(codegen, handle, inst.func)?;
            fmt::fprint(handle, "(")?;

            for (let i = 0z; i < len(inst.args); i += 1) {
                if (i != 0) {
                    fmt::fprint(handle, ", ")?;
                };

                const arg = inst.args[i] as ast::arg_value;
                match (arg.val) {
                    case let id: ast::local_id =>
                        abity(codegen, handle, arg.typ as ast::types::abity)?;
                        fmt::fprint(handle, " ")?;
                        val(codegen, handle, id)?;
                    case let dyn: ast::dynconst =>
                        fmt::fprint(handle, "ptr ")?;
                        dynconst(codegen, handle, dyn)?;
                };
            };

            fmt::fprint(handle, ")")?;

            var::add(&codegen.variables, this.name, var::var_size::I8);
        case => void;
    };

    fmt::fprintln(handle)?;
};

fn alloca(codegen: *codegen, handle: io::handle, this: *ast::return_unary) (void | io::error) = {
    fmt::fprint(handle, "alloca ")?;
    match  (this.first) {
        case let _size: i64 =>
            switch (_size) {
                case 1 => fmt::fprint(handle, "i8, ")?;
                case 2 => fmt::fprint(handle, "i16, ")?;
                case 4 => fmt::fprint(handle, "i32, ")?;
                case 8 => fmt::fprint(handle, "i64, ")?;
                case => void;
            };
        case => void;
    };

    switch (this.inst) {
        case ast::unary_ret::ALLOC4  => fmt::fprint(handle, "align 4")?;
        case ast::unary_ret::ALLOC8  => fmt::fprint(handle, "align 8")?;
        case ast::unary_ret::ALLOC16 => fmt::fprint(handle, "align 16")?;
        case => void;
    };
};

fn jump(codegen: *codegen, handle: io::handle, this: *ast::jump) (void | io::error) = {
    match(*this) {
        case let this: ast::jmp => fmt::fprintfln(handle, "\tbr label %{}", this.block_id)?;
        case let this: ast::jnz =>
            fmt::fprint(handle, "\tbr ")?;
            val_type(codegen, handle, this.val)?;
            fmt::fprint(handle, " ")?;
            val(codegen, handle, this.val)?;
            fmt::fprintfln(handle, ", label %{}, label %{}", this.ifz, this.ifn)?;
        case let this: ast::ret =>
            match (this.val) {
                case let this: ast::val =>
                    fmt::fprint(handle, "\tret ")?;
                    abity(codegen, handle, codegen.current_func.ret_type as types::abity)?;
                    fmt::fprint(handle, " ")?;
                    val(codegen, handle, this)?;
                    fmt::fprintln(handle)?;
                case void =>
                    fmt::fprintln(handle, "\tret void")?;
            };
        case => void;
    };
};
