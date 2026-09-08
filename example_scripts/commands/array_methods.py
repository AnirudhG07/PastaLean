# Exercises the Array-backed list methods in the runnable twin: an O(1) stack
# (append/pop under `while st:`), plus reverse/insert/count/index/clear.
def stack_sum(n: int) -> int:
    st = []
    for i in range(n):
        st.append(i)
    total = 0
    while st:
        total += st.pop()
    return total


def list_ops() -> int:
    xs = [3, 1, 2, 1]
    xs.insert(0, 9)
    xs.reverse()
    ones = xs.count(1)
    two_at = xs.index(2)
    xs.clear()
    return ones + two_at + len(xs)


def main():
    print(stack_sum(5))
    print(list_ops())


if __name__ == "__main__":
    main()
