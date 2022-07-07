"""
Nested generators-coroutines.
"""


def outer():
    yield 1
    yield from inner()
    yield 4


def inner():
    yield 2
    yield 3


for i in outer():
    print(i)
