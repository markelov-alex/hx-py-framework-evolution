"""
Generators.
"""


class myrange_iter:
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


def myrange_gen(count):
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
print_items4(myrange_iter(3))
print()
print_items4(myrange_gen(3))
