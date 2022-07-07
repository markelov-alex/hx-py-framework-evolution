# https://snarky.ca/how-the-heck-does-async-await-work-in-python-3-5/


def print_items(items):
    i, total = 0, len(items)
    while i < total:
        print(items[i])
        i += 1


def print_items2(items):
    i = len(items) - 1
    while i >= 0:
        print(items[i])
        i -= 1


class Iterator:
    def __init__(self, items):
        self.items = items
        self.i = 0
        self.count = len(items) if items else 0

    def next(self):
        if self.i >= self.count:
            raise Exception
        item = self.items[self.i]
        self.i += 1
        return item


class ReverseIterator(Iterator):
    def next(self):
        if self.i >= self.count:
            raise Exception
        item = self.items[self.count - 1 - self.i]
        self.i += 1
        return item


def print_items3(iterator):
    while True:
        try:
            print(iterator.next())
        except:
            break


class myrange:
    def __init__(self, count):
        self.i = 0
        self.count = count

    def __iter__(self):
        return self

    def __next__(self):
        if self.i >= self.count:
            raise StopIteration()
        i = self.i
        self.i += 1
        return i


def myrange2(count):
    i = 0
    while True:
        if i >= count:
            return  # Will raise StopIteration() in next()
        yield i
        i += 1


def print_items4(iterator):
    for item in iterator:
        print(item)


print()
print_items([1, 2, 3,])
print()
print_items2([1, 2, 3,])
print()
print_items3(Iterator([1, 2, 3,]))
print()
print_items3(ReverseIterator([1, 2, 3,]))
print()
print()
print_items4(myrange(3))
print()
print_items4(myrange2(3))
print()


def myrange3():
    i = 1
    while True:
        yield i
        i += 1


def factorial():
    r = myrange3()
    result = 1
    while True:
        i = next(r)
        result *= i
        yield result


gen = factorial()
# while True:
#     print(next(gen))
#     input("Press Enter to get next value")
for i in range(5):
    print(next(gen))


def inf_range2():
    i = 0
    while True:
        n = yield i
        i += 1
        if n is not None:
            i = n


gen = inf_range2()
# while True:
#     n = input("Type next value to continue or \"exit\" or press Enter:")
#     if n == "exit":
#         break
#     if n:
#         print(gen.send(int(n)))
#     else:
#         print(next(gen))
#         print(gen.send(None))  # Same


# -def inf_range():
#     i = 1
#     while True:
#         yield i
#         i += 1
#
#
# def factorial():
#     r = inf_range()
#     result = 1
#     while True:
#         i = yield from r
#         result *= i
#         yield result
#
#
# gen = factorial()
# while True:
#     print(next(gen))
#     input("Press Enter to get next value")


# _inf_range2 = inf_range2


def inf_range3():
    print("Wrapper3")
    for i in inf_range2():
        yield i
    print("Never reached")


def inf_range4():
    print("Wrapper4")
    yield from inf_range2()
    print("Never reached")


gen = inf_range3()
# gen = inf_range4()
while True:
    n = input("Type next value to continue or \"exit\" or press Enter:")
    if n == "exit":
        break
    if n:
        print(gen.send(int(n)))
    else:
        print(next(gen))


# # https://towardsdatascience.com/cpython-internals-how-do-generators-work-ba1c4405b4bc
def outer():
    yield 1
    n = yield from inner()
    yield n
    yield 5


def inner():
    print("We're inside")
    value = yield 2
    value = yield 2.5
    print("Received:", value)
    return 4


print()
gen = outer()
print(next(gen), "| 1")
# We're inside
print(next(gen), "| 2")
print(next(gen), "| 2.5")
# Received: 3
print(gen.send(3), "| 4")
print(next(gen), "| 5")
# print(next(gen))
# StopIteration


exit()




# import concurrent.futures
#
#
# counter = 0
#
#
# def increment_counter(fake_value):
#     global counter
#     for _ in range(100):
#         counter += 1
#     print(counter)
#
#
# if __name__ == "__main__":
#     fake_data = [x for x in range(5000)]
#     counter = 0
#     with concurrent.futures.ThreadPoolExecutor(max_workers=5000) as executor:
#         executor.map(increment_counter, fake_data)
# exit()


class myrange:
    def __init__(self, max):
        self.max = max
        self.i = 0

    def __iter__(self):
        return self

    def __next__(self):
        if self.i >= self.max:
            raise StopIteration()
        i = self.i
        self.i += 1
        return i


# class myrange2:
#     def __init__(self, max):
#         self.max = max
#         self.i = 0
#
#     def __iter__(self):
#         return self
#
#     def __next__(self):
#         if self.i >= self.max:
#             raise StopIteration()
#         yield self.i
#         self.i += 1


def myrange2(max):
    i = 0
    while i < max:
        u = yield i  # u always None
        i += 1


def myrange3(max):
    i = 0
    while i < max:
        u = (yield i)  # u always None, as send() not called
        i += 1


def myrange4(max):
    # yield myrange(max)
    # yield next(myrange(max))
    for i in myrange(max):
        x = yield i
        print("x:", x)


def myrange5(max):
    yield from myrange(max)
    # (yield from myrange(max))


def myrange6(max):
    i, q = 0, None
    while i < max:
        print(f"q: {q} i: {i}")
        q = yield i
        # q = (yield i)
        print(f" q: {q} i: {i}")
        i += 1


# a1 = [i for i in myrange(10)]
# print(a1)
#
# g2 = myrange2(10)
# a2 = [i for i in myrange2(10)]
# print(a2)
#
# g3 = myrange3(10)
# gg3 = next(g3)
# a3 = [i for i in myrange3(10)]
# print(a3)
#
# a4 = [i for i in myrange4(10)]
# print(a4)
#
# a5 = [i for i in myrange5(10)]
# print(a5)
#
# g6 = myrange6(10)
# print(next(g6))
# print(next(g6))
# print(g6.send(3))
# print(g6.send(4))
# print(next(g6))
# print(next(g6))
# print(next(g6))


# Don't return from b() back to a()
# def a():
#     print("Start a")
#     g = b()
#     print(" Start a", g)
#     yield g
#     print("  End a")
#
#
# def b():
#     print("   Start b")
#     # yield from range(10)
#     yield 10
#     print("    End b")
#
#
# gen = next(a())
# print("1", gen)
# print("2", next(gen))

# Output:
# Start a
# Start a <generator object b at 0x0000000003B00AC8>
# 1 <generator object b at 0x0000000003B00AC8>
# Start b
# 2 10


# class CoroWrapper:
#     def __init__(self, gen):
#         assert isgenerator(gen), gen
#         self.gen = gen
#         self.__name__ = getattr(gen, '__name__', None)
#         self.__qualname__ = getattr(gen, '__qualname__', None)
#
#     def __iter__(self):
#         return self
#
#     def __next__(self):
#         return self.gen.send(None)
#
#     def send(self, value):
#         return self.gen.send(value)
#
#     def throw(self, type, value=None, traceback=None):
#         return self.gen.throw(type, value, traceback)
#
#     def close(self):
#         return self.gen.close()
#
#     @property
#     def gi_frame(self):
#         return self.gen.gi_frame
#
#     @property
#     def gi_running(self):
#         return self.gen.gi_running
#
#     @property
#     def gi_code(self):
#         return self.gen.gi_code
#
#     def __await__(self):
#         return self
#
#     @property
#     def gi_yieldfrom(self):
#         return self.gen.gi_yieldfrom
#
#
# def coroutine(gen):
#     def wrapper(*args, **kwds):
#         w = CoroWrapper(gen(*args, **kwds))
#         return w
#     return wrapper

# last_gen = None
#
#
# def coroutine(gen_func):
#     # @wraps(gen)
#     def wrapper(*args, **kwds):
#         global last_gen
#         prev_gen = last_gen
#         last_gen = gen = gen_func(*args, **kwds)
#         print(f"WRAPPER before call {gen} of {gen_func}")
#         result = next(gen)
#         print(f" WRAPPER after call {gen} result: {result}")
#         last_gen = prev_gen
#         if prev_gen:
#             print(f"  WRAPPER after call {gen} before send to {prev_gen} result: {result}")
#             prev_gen.send(result)
#             print(f"   WRAPPER after call {gen} after send to {prev_gen} result: {result}")
#             pass
#         else:
#             yield result
#         yield
#
#     print("wrapper:", wrapper, "for:", gen_func)
#     return wrapper
#
#
# @coroutine
# def a():
#     print("Start a")
#     g = b()
#     print(" Start a", g)
#     # yield g
#     r = yield from g
#     print("  End a", r)
#     # +
#     # g2 = b()
#     # r = yield from g2
#     # print("   End a2", r)
#
#
# @coroutine
# def b():
#     print("   Start b")
#     # yield from range(10)
#     r = yield 10
#     # prev_gen.send(10)
#     print("    End b", r)
#
#
# aa = a()
# print(f"Start: {aa}")
# print(next(aa))
# # +
# # print(next(aa))
#
# # gen = next(a())
# # print("1", gen)
# # print("2", next(gen))


# def a():
#     print("Start a")
#     g = b()
#     print(" Start a", g)
#     # yield g
#     r = (yield from g)
#     print("  End a", r)
#     # +
#     # g2 = b()
#     # r = yield from g2
#     # print("   End a2", r)
#
#
# def b():
#     print("   Start b")
#     # yield from range(10)
#     # r = aa.send(10)
#     r = (yield 10)
#     # prev_gen.send(10)
#     print("    End b", r)
#
#
# aa = a()
# print(f"Start: {aa}")
# print(next(aa))


# @asyncio.coroutine
# def b():
#     print("   Start b")
#     for i in range(5):
#         print("    yield b:", i)
#         yield from asyncio.sleep(1)
#         yield i
#         print("    yielded b:", i)
#     # r = (yield 10)
#     print("    End b")
#
#
# g = b()
#
#
# @asyncio.coroutine
# def a():
#     print("Start a")
#     print(" Start a", g)
#     # yield g
#     r = (yield from g)
#     print("  End a", r)
#     r = (yield from g)
#     print("  End a", r)
#     # +
#     g2 = b()
#     r = yield from g2
#     print("   End a2", r)
#
# aa = a()
# print(f"Start: {g}")
# print(next(aa))
# aa.send(next(g))
# aa.send(next(g))
#
# # print(next(aa))
# # print(next(g))
# # print(next(g))
#
# # print(next(aa))
# # print(next(aa))


# async def a():
#     print("Start a")
#     g = b()
#     print(" Start a", g)
#     # yield g
#     r = (await g)
#     print("  End a", r)
#     # +
#     g2 = b()
#     r = await g2
#     print("   End a2", r)
#
#
# async def b():
#     print("   Start b")
#     # r = (yield 10)
#     return await c()
#     # print("    End b", r)
#
#
# async def c():
#     print("   Start c")
#     # r = (yield 10)
#     return 10
#     # print("    End c", r)
#
#
# asyncio.run(a())
# # print(f"Start: {aa}")
# # print(await aa)
# # print(await aa)


# def mygen():
#     i = 0
#     while True:
#         print("  gen yield i:", i)
#         max = yield i
#         print("   gen continue max:", max)
#         if max is not None and i > max:
#             break
#         i += 1
#
#
# gen = mygen()
# for i in gen:
#     print("i:", i)
#     gen.send(random.random() * 10)


# https://stackoverflow.com/questions/49005651/how-does-asyncio-actually-work
# def mygen():
#     i = 0
#     gen2 = mygen2()
#     # max = yield from gen2
#     max = next(gen2)
#     while True:
#         print("gen2:", gen2)
#         print("  gen yield i:", i)
#         # max = yield from gen2
#         # print("   gen send max:", max)
#         max = gen2.send(random.random() * 10)
#         print("    gen continue max:", max)
#         if max is not None and i > max:
#             break
#         i += 1
#
#
# def mygen2():
#     i = 0
#     while True:
#         print("  gen2 yield i:", i)
#         max = yield i
#         print("   gen2 continue max:", max)
#         if max is not None and i > max:
#             break
#         i += 1
#
#
# gen = mygen()
# # for i in gen:
# while True:
#     print("gen:", gen)
#     i = next(gen)
#     print("i:", i)
#     t = gen.send(random.random() * 10)
#     print(" i:", i, t)


# # https://towardsdatascience.com/cpython-internals-how-do-generators-work-ba1c4405b4bc
# def gener():
#     print("First number")
#     a = yield
#     print("Second number")
#     b = yield
#     print("Addition result:", a+b)
#     c = yield
#
#
# g = gener()
# next(g)  # Advance the generator to first yield
# g.send(5)
# g.send(5)


# # https://towardsdatascience.com/cpython-internals-how-do-generators-work-ba1c4405b4bc
def inner():
    print("We're inside")
    value = yield 2
    print("Received", value)
    return 4


def outer():
    yield 1
    retval = yield from inner()
    print("Returned", retval)
    yield 5


g = outer()
next(g)
next(g)  # Automatically enter the inner() generator
g.send(3)

