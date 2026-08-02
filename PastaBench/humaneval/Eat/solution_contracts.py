from contracts import *

def eat(number, need, remaining):
    """
    You're a hungry rabbit, and you already have eaten a certain number of carrots,
    but now you need to eat more carrots to complete the day's meals.
    you should return an array of [ total number of eaten carrots after your meals,
                                    the number of carrots left after your meals ]
    if there are not enough remaining carrots, you will eat all remaining carrots, but will still be hungry.
    
    Example:
    * eat(5, 6, 10) -> [11, 4]
    * eat(4, 8, 9) -> [12, 1]
    * eat(1, 10, 10) -> [11, 0]
    * eat(2, 11, 5) -> [7, 0]
    
    Variables:
    @number : integer
        the number of carrots that you have eaten.
    @need : integer
        the number of carrots that you need to eat.
    @remaining : integer
        the number of remaining carrots thet exist in stock
    
    Constrain:
    * 0 <= number <= 1000
    * 0 <= need <= 1000
    * 0 <= remaining <= 1000

    Have fun :)
    """
    Requires(0 <= number <= 1000)
    Requires(0 <= need <= 1000)
    Requires(0 <= remaining <= 1000)

    # The number of carrots eaten in this meal is the minimum of what is needed and what is available.
    # The postconditions precisely define the result based on this logic.
    Ensures(Result()[0] == number + (need if need <= remaining else remaining))
    Ensures(Result()[1] == remaining - (need if need <= remaining else remaining))

    # Also, as a consequence, the total number of carrots (eaten + remaining) is conserved.
    Ensures(Result()[0] + Result()[1] == number + remaining)


    if need <= remaining:
        return [number + need, remaining - need]
    else:
        return [number + remaining, 0]