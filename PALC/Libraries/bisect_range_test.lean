import Libraries

open Libraries.bisect

-- Lazy keyed bisect over a range (no materialization): binary-search-on-answer idioms.
-- `bisect_left(range(1, 100), True, key=λ x. x*x ≥ 50)` = first i where (1+i)² ≥ 50 → i=6 (7²=49<50, 8²=64≥50 → x=8 → i=7). Recheck: range=1..99, key(x)=decide(x*x≥50), x=True.
#guard pyBisectLeftRangeKey (1 : Int) 100 1 true (fun x => decide (x * x ≥ 50)) == 7
-- perfect-square style: first x in [1, n+1) with x*x ≥ num.
#guard pyBisectLeftRangeKey (1 : Int) 26 1 25 (fun x => x * x) == 4   -- range[4]=5, 5*5=25
-- lazy over a huge range must be instant (would OOM if materialized).
#guard pyBisectLeftRangeKey (1 : Int) 1000000000 1 true (fun x => decide (x ≥ 500)) == 499
