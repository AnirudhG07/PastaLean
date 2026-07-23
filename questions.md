# Questions

Some general questions i have:
- How is `==` and `is` modelled? `is` should be value + type match, while `==` should be value match like `1==1.0` is True but `1 is 1.0` is False.

- can we make a PastaLean REPL? which get `term` wise converted and evaluated? (like a python REPL but with PastaLean + Python) both.

- How does python closures work in pastalean?
```
functions = []
for i in range(3):
    functions.append(lambda: i)

print([f() for f in functions])  
``` 

Here’s what you get:
```
Output >>> [2, 2, 2]
```

- the asterick operation is supported, but is it to this extent? 
a, *b = 1, 2, 3, 4
print(a, b)  
 

Output >>> 1 [2, 3, 4]
 

But this might surprise you:

a, *b, = 1,
print(a, b)  
 

Output >>> 1 []
 

And this is valid too:

(*a,) = [1, 2, 3]
print(a) 
 

Output >>> [1, 2, 3]

- Why is PyAny not containing all possible PyType and only a few mentioned? PyType contains everything that is possible, so why does PyAny not saying that? even `typing` library ones should technically be allowed in PyAny, right?

- shared mutable

def _add_item(item, bucket=[]):
    bucket.append(item)
    return bucket

def add_item():
    print(_add_item("a"))
    print(_add_item("b"))
    print(_add_item("c"))
    assert _add_item("d") == ["a", "b", "c", "d"]

