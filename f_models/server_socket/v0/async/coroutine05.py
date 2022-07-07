"""
Introduce send(). Using send() with yield from.
send() is next() + setting value to yield expression.
Generators become real coroutines as data now goes in both directions.
"""


def counter(n):
    print("Counter")
    i = 1
    while True:
        x = yield i
        if x is not None:
            i = int(x)
        i += 1
        if i > n:
            print("Counter End")
            return


def counter2(n):
    print("Wrapper2")
    for i in counter(n):
        yield i
    print("Wrapper2 End")


def counter3(n):
    print("Wrapper3")
    yield from counter(n)
    print("Wrapper3 End")


print()
gen = counter(7)
print(next(gen))
print(gen.send(None))  # Same as next(gen)
print(gen.send(4))  # OK
for i in gen:  # Print the rest
    print(i)


print()
gen = counter2(7)
print(next(gen))
print(gen.send(None))  # Same as next(gen)
print(gen.send(4))  # Fail
for i in gen:  # Print the rest
    print(i)


print()
gen = counter3(7)
print(next(gen))
print(gen.send(None))  # Same as next(gen)
print(gen.send(4))  # OK
for i in gen:  # Print the rest
    print(i)
