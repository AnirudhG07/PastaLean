from contracts import *


# Hoisted to module scope: an `Ensures` inside a nested helper is attributed to the enclosing
# entry point and evaluated in its scope, where `score` does not exist.
def to_letter_grade(score: float) -> str:
    Requires(score >= 0.0 and score <= 4.0)
    Ensures((score == 4.0 and Result() == "A+") or
            (score > 3.7 and score < 4.0 and Result() == "A") or
            (score > 3.3 and score <= 3.7 and Result() == "A-") or
            (score > 3.0 and score <= 3.3 and Result() == "B+") or
            (score > 2.7 and score <= 3.0 and Result() == "B") or
            (score > 2.3 and score <= 2.7 and Result() == "B-") or
            (score > 2.0 and score <= 2.3 and Result() == "C+") or
            (score > 1.7 and score <= 2.0 and Result() == "C") or
            (score > 1.3 and score <= 1.7 and Result() == "C-") or
            (score > 1.0 and score <= 1.3 and Result() == "D+") or
            (score > 0.7 and score <= 1.0 and Result() == "D") or
            (score > 0.0 and score <= 0.7 and Result() == "D-") or
            (score == 0.0 and Result() == "E"))
    if score == 4.0:
      return "A+"
    elif score > 3.7:
      return "A"
    elif score > 3.3:
      return "A-"
    elif score > 3.0:
      return "B+"
    elif score > 2.7:
      return "B"
    elif score > 2.3:
      return "B-"
    elif score > 2.0:
      return "C+"
    elif score > 1.7:
      return "C"
    elif score > 1.3:
      return "C-"
    elif score > 1.0:
      return "D+"
    elif score > 0.7:
      return "D"
    elif score > 0.0:
      return "D-"
    else:
      return "E"


def numerical_letter_grade(grades: list[float]) -> list[str]:
    """It is the last week of the semester and the teacher has to give the grades
    to students. The teacher has been making her own algorithm for grading.
    The only problem is, she has lost the code she used for grading.
    She has given you a list of GPAs for some students and you have to write
    a function that can output a list of letter grades using the following table:
             GPA       |    Letter grade
              4.0                A+
            > 3.7                A
            > 3.3                A-
            > 3.0                B+
            > 2.7                B
            > 2.3                B-
            > 2.0                C+
            > 1.7                C
            > 1.3                C-
            > 1.0                D+
            > 0.7                D
            > 0.0                D-
              0.0                E


    Example:
    grade_equation([4.0, 3, 1.7, 2, 3.5]) ==> ['A+', 'B', 'C-', 'C', 'A-']
    """
    Requires(all(g >= 0.0 and g <= 4.0 for g in grades))
    Ensures(len(Result()) == len(grades))
    # The point: elementwise, output letter i is the band the i'th GPA falls in.
    Ensures(all(
        ((grades[i] == 4.0 and Result()[i] == "A+") or
         (grades[i] > 3.7 and grades[i] < 4.0 and Result()[i] == "A") or
         (grades[i] > 3.3 and grades[i] <= 3.7 and Result()[i] == "A-") or
         (grades[i] > 3.0 and grades[i] <= 3.3 and Result()[i] == "B+") or
         (grades[i] > 2.7 and grades[i] <= 3.0 and Result()[i] == "B") or
         (grades[i] > 2.3 and grades[i] <= 2.7 and Result()[i] == "B-") or
         (grades[i] > 2.0 and grades[i] <= 2.3 and Result()[i] == "C+") or
         (grades[i] > 1.7 and grades[i] <= 2.0 and Result()[i] == "C") or
         (grades[i] > 1.3 and grades[i] <= 1.7 and Result()[i] == "C-") or
         (grades[i] > 1.0 and grades[i] <= 1.3 and Result()[i] == "D+") or
         (grades[i] > 0.7 and grades[i] <= 1.0 and Result()[i] == "D") or
         (grades[i] > 0.0 and grades[i] <= 0.7 and Result()[i] == "D-") or
         (grades[i] == 0.0 and Result()[i] == "E"))
        for i in range(len(grades))
    ))
    # Equal GPAs always get the same letter (the banding is a function of the score alone).
    Ensures(all(
        grades[i] != grades[0] or Result()[i] == Result()[0]
        for i in range(len(grades))
    ))

    return [to_letter_grade(x) for x in grades]
