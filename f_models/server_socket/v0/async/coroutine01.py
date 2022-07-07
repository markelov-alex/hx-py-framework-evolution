"""
Iterators.
"""


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


print()
print("Without iterators:")
print_items([1, 2, 3,])
print()
print_items2([1, 2, 3,])
print()
print("With iterators:")
print_items3(Iterator([1, 2, 3,]))
print()
print_items3(ReverseIterator([1, 2, 3,]))
