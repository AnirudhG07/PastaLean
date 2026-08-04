# Edge case: a class-free program under --heap. No classes means no value universe is needed, so
# the prelude is skipped and output should match the default path (a no-op for --heap at this stage).
x = 5
y = x + 3
z = y * 2
