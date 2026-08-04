# Single inheritance where the base carries a mode-varying (float) field: under `--mode both` the
# exact twin's field is ℚ and the runnable `'rn` twin's is Float, so the two twins genuinely DIFFER.
# Regression for the `'rn` subclass extending the WRONG base (`Savings'rn extends Account` instead of
# `Account'rn`), which mismatched Float vs ℚ at `Savings'rn.new` and broke `derive_storable%`.
class Account:
    def __init__(self, balance: float):
        self.balance: float = balance

    def deposit(self, amount: float):
        self.balance = self.balance + amount


class Savings(Account):
    def __init__(self, balance: float, rate: float):
        self.balance: float = balance
        self.rate: float = rate

    def interest(self):
        return self.balance * self.rate
