from contracts import *


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
    Requires(all(0.0 <= g <= 4.0 for g in grades))
    Ensures(len(Result()) == len(grades))
    Ensures(all(
        ((grades[i] == 4.0 and Result()[i] == "A+") or
         (3.7 < grades[i] < 4.0 and Result()[i] == "A") or
         (3.3 < grades[i] <= 3.7 and Result()[i] == "A-") or
         (3.0 < grades[i] <= 3.3 and Result()[i] == "B+") or
         (2.7 < grades[i] <= 3.0 and Result()[i] == "B") or
         (2.3 < grades[i] <= 2.7 and Result()[i] == "B-") or
         (2.0 < grades[i] <= 2.3 and Result()[i] == "C+") or
         (1.7 < grades[i] <= 2.0 and Result()[i] == "C") or
         (1.3 < grades[i] <= 1.7 and Result()[i] == "C-") or
         (1.0 < grades[i] <= 1.3 and Result()[i] == "D+") or
         (0.7 < grades[i] <= 1.0 and Result()[i] == "D") or
         (0.0 < grades[i] <= 0.7 and Result()[i] == "D-") or
         (grades[i] == 0.0 and Result()[i] == "E"))
        for i in range(len(grades))
    ))

    def to_letter_grade(score: float) -> str:
      Requires(0.0 <= score <= 4.0)
      Ensures((score == 4.0 and Result() == "A+") or
              (3.7 < score < 4.0 and Result() == "A") or
              (3.3 < score <= 3.7 and Result() == "A-") or
              (3.0 < score <= 3.3 and Result() == "B+") or
              (2.7 < score <= 3.0 and Result() == "B") or
              (2.3 < score <= 2.7 and Result() == "B-") or
              (2.0 < score <= 2.3 and Result() == "C+") or
              (1.7 < score <= 2.0 and Result() == "C") or
              (1.3 < score <= 1.7 and Result() == "C-") or
              (1.0 < score <= 1.3 and Result() == "D+") or
              (0.7 < score <= 1.0 and Result() == "D") or
              (0.0 < score <= 0.7 and Result() == "D-") or
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
    
    return [to_letter_grade(x) for x in grades]