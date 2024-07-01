# qbellvm

## Compile [QBE](https://c9x.me/compile/) IR to LLVM

## Building

```sh
hare build .
```

## Using

qbellvm gets input from `stdin` and outputs to `stdout`. To use it with clang toolchain you can run
```sh
./qbellvm < tests/test.ssa | clang -x ir -
```

## Example 

### Input
tests/test.ssa:
```ssa
data $.fmt = { b 37, b 100, b 10, b 0 }

export
function w $main() {
@start
	%n =l alloc4 4
	%i =l alloc4 4

	storew 0, %n
	storew 0, %i

@loop.cond
	%i.1 =w loadw %i
	%i.cmp15 =w csltw %i.1, 15
	jnz %i.cmp15, @loop.body, @loop.end

@loop.body
	%n.1 =w loadw %n
	%n.1 =w add %n.1, 1
	storew %n.1, %n

@loop.iterate
	%i.2 =w loadw %i
	%i.2 =w add %i.2, 1
	storew %i.2, %i
	jmp @loop.cond

@loop.end
	%n.2 =w loadw %n
	%.1 =w call $printf(l $.fmt, w %n.2)

	ret 0
}
```


### Output

```ll
declare i32 @printf(ptr, ...)

%.fmt = type <{ i8, i8, i8, i8 }>
@.fmt = constant %.fmt <{ i8 37, i8 100, i8 10, i8 0 }>

define i32 @main () {
start:
        %n.0 = alloca i32, align 4
        %i.0 = alloca i32, align 4
        store i32 0, ptr %n.0, align 4
        store i32 0, ptr %i.0, align 4
        br label %loop.cond
loop.cond:
        %i.1.0 = load i32, ptr %i.0, align 4
        %i.cmp15.0 = icmp slt i32 %i.1.0, 15
        br i1 %i.cmp15.0, label %loop.body, label %loop.end
loop.body:
        %n.1.0 = load i32, ptr %n.0, align 4
        %n.1.1 = add i32 %n.1.0, 1
        store i32 %n.1.1, ptr %n.0, align 4
        br label %loop.iterate
loop.iterate:
        %i.2.0 = load i32, ptr %i.0, align 4
        %i.2.1 = add i32 %i.2.0, 1
        store i32 %i.2.1, ptr %i.0, align 4
        br label %loop.cond
loop.end:
        %n.2.0 = load i32, ptr %n.0, align 4
        %.1.0 = call i32 @printf(ptr @.fmt, i32 %n.2.0)
        ret i32 0
}
```