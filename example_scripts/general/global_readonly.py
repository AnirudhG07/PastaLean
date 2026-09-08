# `global` for a read-only module global: the declaration is a no-op and the name
# resolves to the top-level def. (A `global` that *mutates* is a loud refusal.)
LIMIT = 100
settings = {"scale": 3}

def scaled(x):
    global settings
    return x * settings["scale"]

def within(x):
    global LIMIT
    return x < LIMIT

def main():
    print(scaled(5))
    print(within(50))
