# Two independent classes in one module.
# Exercises: the Val universe carrying MULTIPLE per-class constructors, and multiple
# derive_storable% invocations in the one prelude.
class Dog:
    def __init__(self, legs):
        self.legs = legs


class Cat:
    def __init__(self, lives):
        self.lives = lives

    def remaining(self):
        return self.lives
