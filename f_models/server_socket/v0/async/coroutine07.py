"""
Using coroutines with asyncio.
"""

import asyncio
from asyncio import coroutine


print("---1---")


def outer():
    yield 1
    yield from inner()
    yield 4


def inner():
    yield 2
    yield 3


for i in outer():
    print(i)

print("---1---")
# RuntimeError: Task got bad yield: 1
try:
    asyncio.run(outer())
except Exception as e:
    print(e)


print("---2---")


@coroutine  # Changes nothing here
def outer2():
    yield 1
    yield from inner2()
    yield 4


@coroutine
def inner2():
    yield 2
    yield 3


for i in outer2():
    print(i)
print("---2---")
# RuntimeError: Task got bad yield: 1
try:
    asyncio.run(outer2())
except Exception as e:
    print(e)


print("---3---")


def outer3():
    print("Outer")
    yield from inner3()
    print("Outer End")


def inner3():
    print("Inner")
    return 2
    print("Inner End")


# TypeError: 'int' object is not iterable
try:
    asyncio.run(outer3())
except Exception as e:
    print(e)


print("---4---")


@coroutine
def outer4():
    print("Outer")
    yield from inner4()
    print("Outer End")


@coroutine
def inner4():
    print("Inner")
    return 2
    print("Inner End")


asyncio.run(outer4())


print("---5---")


async def outer5():
    print("Outer")
    await inner5()
    print("Outer End")


async def inner5():
    print("Inner")
    return 2
    print("Inner End")


asyncio.run(outer5())
