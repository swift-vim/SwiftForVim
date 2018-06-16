import types
import sys



class MockBuffer():
    def __init__(self):
        self.number = 1
        self.name = "mock"

class MockWindow():
    def __init__(self):
        self.cursor = (1, 2)

# actual vim apis

class Current():
    def __init__(self):
        self.buffer = MockBuffer()
        self.window = MockWindow()

current = Current()

class MockRuntime():
    def __init__(self):
        self.command = lambda value: None
        self.eval = lambda value: value

runtime = MockRuntime()

def command(value):
    return runtime.command(value)

def eval(value):
    return runtime.eval(value)

def eval_int(value):
    return int(value)

def eval_bool(value):
    return True

def py_exec(value):
    exec(value)

