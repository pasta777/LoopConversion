## What is this?

A simple LLVM Pass which transforms the loop below into a formula, basically optimizing it from O(N) to O(1).

```c
for(int i = ANY; i < n; i++)
  x++;
// x = x + (n - i)
```

## How to use it?

- You will need [LLVM project](https://github.com/llvm/llvm-project) installed.
- Create a new folder in `/llvm/lib/Transforms/` relative to llvm-project folder named LoopConversion.
- In Transforms folder, add a line `add_subdirectory(LoopConversion)` into CMakeLists.txt
- Copy files from this folder into a newly created one.
- Type in terminal `./bin/opt -load lib/LLVMLoopConversion.so -enable-new-pm=0 -loop-conversion (name of the ll file) -S -o (name of the optimized ll file)` command.
