def total_len(lst):
    return sum(map(len, lst))


def main():
    print(total_len(["ab", "cde", "f"]))
