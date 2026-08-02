from typing import List
from contracts import *


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
    Requires(music_string == "" or all(note in ["o", "o|", ".|"] for note in music_string.split(" ")))
    Ensures(len(Result()) == (0 if music_string == "" else len(music_string.split(" "))))
    Ensures(all(beat in [1, 2, 4] for beat in Result()))

    def count_beats(note: str) -> int:
        Requires(note in ["o", "o|", ".|"])
        Ensures((note == "o" and Result() == 4) or
                (note == "o|" and Result() == 2) or
                (note == ".|" and Result() == 1))
        if note == "o": return 4
        elif note == "o|": return 2
        elif note == ".|": return 1
    
    if music_string == "": return []
    return list(map(count_beats, music_string.split(" ")))