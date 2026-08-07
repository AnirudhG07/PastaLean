from typing import List
from contracts import *


def count_beats(note: str) -> int:
    Requires(note == "o" or note == "o|" or note == ".|")
    Ensures((note == "o" and Result() == 4)
            or (note == "o|" and Result() == 2)
            or (note == ".|" and Result() == 1))
    if note == "o": return 4
    elif note == "o|": return 2
    elif note == ".|": return 1


def parse_music(music_string: str) -> List[int]:
    """ Input to this function is a string representing musical notes in a special ASCII format.
    Your task is to parse this string and return list of integers corresponding to how many beats does each
    not last.

    Here is a legend:
    'o' - whole note, lasts four beats
    'o|' - half note, lasts two beats
    '.|' - quater note, lasts one beat

    >>> parse_music('o o| .| o| o| .| .| .| .| o o')
    [4, 2, 1, 2, 2, 1, 1, 1, 1, 4, 4]
    """
    Requires(music_string == ""
             or all(n == "o" or n == "o|" or n == ".|" for n in music_string.split(" ")))
    # One beat count per note, in order.
    Ensures(len(Result()) == (0 if music_string == "" else len(music_string.split(" "))))
    # Only the three legal durations can ever come out.
    Ensures(all(b == 1 or b == 2 or b == 4 for b in Result()))
    # The point: entry i is the duration the legend assigns to note i.
    Ensures(Result() == [4 if n == "o" else (2 if n == "o|" else 1)
                         for n in ([] if music_string == "" else music_string.split(" "))])
    # Aggregate form: the piece's total length is the summed beat count of its notes.
    Ensures(sum(Result()) == sum(
        4 if n == "o" else (2 if n == "o|" else 1)
        for n in ([] if music_string == "" else music_string.split(" "))))

    if music_string == "": return []
    return list(map(count_beats, music_string.split(" ")))
