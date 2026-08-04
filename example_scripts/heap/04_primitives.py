# All primitive field kinds together: str, int, float, bool (via explicit annotations).
# Exercises: every primitive Val ctor field type + the numericMode-aware float slot
# (Float under --mode run, Rat under --mode prove) and the matching Storable instances.
class Record:
    name: str = ""
    count: int = 0
    ratio: float = 0.0
    active: bool = False

    def total(self):
        return self.count
