def dict_views():
    d = {"a": 1, "b": 2, "c": 3}
    its = d.items()
    ks = d.keys()
    vs = d.values()
    return its, ks, vs

def dict_len():
    d = {"x": 10, "y": 20}
    return len(d)

def dict_spread_merge():
    # `{**d1, **d2}` merges dicts (later wins on duplicate keys); a bare `k: v` mixed with spreads
    # overrides too. Here "b" resolves to 20 (from d2), "d" to 99.
    d1 = {"a": 1, "b": 2}
    d2 = {"b": 20, "c": 3}
    return {**d1, **d2, "d": 99}
