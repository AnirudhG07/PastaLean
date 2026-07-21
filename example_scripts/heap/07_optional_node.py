# The recursive-node pattern: a field defaulting to None becomes `Option ClassName`.
# Exercises: `Val.node (val : Int) (next : Option Node)` and derive_storable% over an Option field.
class Node:
    def __init__(self, val: int, next=None):
        self.val = val
        self.next = next

    def value(self):
        return self.val
