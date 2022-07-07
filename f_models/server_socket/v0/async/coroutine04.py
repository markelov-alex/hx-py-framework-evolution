"""
Introduce yield from.
"yield from gen" as syntactic sugar for "for i in gen: yield i".
"""


def counter(n):
    print("Counter")
    i = 1
    while True:
        yield i
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
for i in counter(5):
    print(i)


print()
for i in counter2(5):
    print(i)


print()
for i in counter3(5):
    print(i)

g = counter3(5)
next(g)
next(g)
