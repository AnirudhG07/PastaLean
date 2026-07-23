from contracts import *

def buildArray(target: List[int], n: int) -> List[str]:
    Requires(all(1 <= x <= n for x in target))
    Requires(all(target[i] < target[i+1] for i in range(len(target)-1)))
    ans = []
    cur = 1
    for x in target:
        while cur < x:
            ans.extend(['Push', 'Pop'])
            cur += 1
        ans.append('Push')
        cur += 1
    return ans