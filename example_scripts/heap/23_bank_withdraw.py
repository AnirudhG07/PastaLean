# IO + exceptions + heap: a shared bank account, mutated through an alias. Reads a withdrawal amount;
# overdrawing raises ValueError, caught and reported as -1. The mutation is done through `alias` but
# observed through `acct` (real reference semantics).
#   run with input "40"  -> prints 60
#   run with input "150" -> prints -1
class Account:
    def __init__(self, balance):
        self.balance = balance

    def withdraw(self, amount):
        if amount > self.balance:
            raise ValueError("insufficient funds")
        self.balance = self.balance - amount

    def get(self):
        return self.balance


if __name__ == "__main__":
    acct = Account(100)
    alias = acct
    n = int(input())
    try:
        alias.withdraw(n)
        print(acct.get())
    except ValueError:
        print(-1)
