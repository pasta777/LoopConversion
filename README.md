A simple LLVM Pass which transforms the loop below into a formula.

```c
for(int i = ANY; i < n; i++)
  x++;
// x = x + (n - i)
```
