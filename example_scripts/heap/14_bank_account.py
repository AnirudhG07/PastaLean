# A bank account with conditional withdrawal, shared between two handles (a "joint account").
# Exercises: constructor arg, multiple mutator methods, a conditional mutation reading self in the
# guard, a getter, and aliasing (deposit via one handle, withdraw via the other). Returns 120.
class BankAccount:
    def __init__(self, balance):
        self.balance = balance

    def deposit(self, amount):
        self.balance = self.balance + amount

    def withdraw(self, amount):
        if amount <= self.balance:
            self.balance = self.balance - amount

    def balance_of(self):
        return self.balance


def demo():
    acc = BankAccount(100)
    shared = acc            # same account
    acc.deposit(50)         # 150
    shared.withdraw(30)     # 120
    shared.withdraw(1000)   # insufficient funds → no change
    return acc.balance_of()
