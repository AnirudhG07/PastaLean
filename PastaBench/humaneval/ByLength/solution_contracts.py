from contracts import *


def by_length(arr):
    """
    Given an array of integers, sort the integers that are between 1 and 9 inclusive,
    reverse the resulting array, and then replace each digit by its corresponding name from
    "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine".

    For example:
      arr = [2, 1, 1, 4, 5, 8, 2, 3]   
            -> sort arr -> [1, 1, 2, 2, 3, 4, 5, 8] 
            -> reverse arr -> [8, 5, 4, 3, 2, 2, 1, 1]
      return ["Eight", "Five", "Four", "Three", "Two", "Two", "One", "One"]
    
      If the array is empty, return an empty array:
      arr = []
      return []
    
      If the array has any strange number ignore it:
      arr = [1, -1 , 55] 
            -> sort arr -> [-1, 1, 55]
            -> reverse arr -> [55, 1, -1]
      return = ['One']
    """

    def to_word(x: int) -> str:
      Requires(1 <= x <= 9)
      if x == 1:
        return "One"
      elif x == 2:
        return "Two"
      elif x == 3:
        return "Three"
      elif x == 4:
        return "Four"
      elif x == 5:
        return "Five"
      elif x == 6:
        return "Six"
      elif x == 7:
        return "Seven"
      elif x == 8:
        return "Eight"
      else:
        return "Nine"
        
    # Full functional specification, stated without reference to the nested `to_word`:
    # the result has exactly one entry per in-range element of `arr`, and entry i is the
    # name of the i-th largest such element (descending order).
    Ensures(len(Result()) == len([y for y in arr if 1 <= y <= 9]))
    Ensures(all(
        Result()[i] == ["One", "Two", "Three", "Four", "Five",
                        "Six", "Seven", "Eight", "Nine"][
            sorted([y for y in arr if 1 <= y <= 9], reverse=True)[i] - 1]
        for i in range(len([y for y in arr if 1 <= y <= 9]))))

    sorted_list, ans = sorted(arr)[::-1], []
    for x in sorted_list:
      if 1 <= x <= 9:
        ans.append(to_word(x))
    return ans