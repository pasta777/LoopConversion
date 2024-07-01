target triple = "x86_64-redhat-linux-gnu"

declare i32 @printf(ptr noundef, ...)

%T1 = type <{ i8, i8, i8, i8 }>
@.fmt = constant %T1 <{ i8 37, i8 100, i8 10, i8 0 }>

define i32 @main() {
  %n.0 = alloca i32, align 4
  %i.0 = alloca i32, align 4

  store i32 0, ptr %n.0, align 4
  store i32 0, ptr %i.0, align 4
  br label %loop.cond

loop.cond:
  %i.1.0 = load i32, ptr %i.0, align 4
  %i.cmp15.0 = icmp slt i32 %i.1.0, 15
  %i.cmp15.1 = zext i1 %i.cmp15.0 to i32

  %i.cmp15.2 = trunc i32 %i.cmp15.1 to i1
  br i1 %i.cmp15.2, label %loop.body, label %loop.end

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
