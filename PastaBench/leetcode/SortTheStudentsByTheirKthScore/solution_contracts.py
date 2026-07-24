from contracts import *
from typing import List

def sortTheStudents(score: List[List[int]], k: int) -> List[List[int]]:
    Requires(k >= 0)
    Requires(all(k < len(row) for row in score))
    return sorted(score, key=lambda x: -x[k])