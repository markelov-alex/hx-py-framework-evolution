"""
Nested generators. Real life example.
"""


def infinite_counter():
    i = 1
    while True:
        yield i
        i += 1


def factorial():
    result = 1
    for i in infinite_counter():
        result *= i
        yield result


print()
for i in factorial():
    print(i)
    if i > 1000:
        break
