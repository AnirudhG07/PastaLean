from contracts import *

def furthestDistanceFromOrigin(moves: str) -> int:
    Ensures(Result() == abs(moves.count('L') - moves.count('R')) + moves.count('_'))
    return abs(moves.count('L') - moves.count('R')) + moves.count('_')