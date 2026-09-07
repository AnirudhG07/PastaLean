"""A prefix Trie: the canonical case AUTO-DETECTED as needing reference (`--heap`) semantics.

`insert` walks a `node` cursor and BUILDS the structure through it — `node.children[idx] = Trie()`
(a container-element write through the cursor's field) plus `node = node.children[idx]`. Value
semantics copies the cursor, so the built nodes are lost and `search` sees nothing; the driver's
`_module_needs_heap` detects the advance+structural-mutation pair and switches this program to the
heap tier, where the cursor aliases the shared structure and the writes persist. No `--heap` flag.
"""


class Trie:
    def __init__(self):
        self.children = [None] * 26
        self.is_end = False

    def insert(self, w):
        node = self
        for c in w:
            idx = ord(c) - ord('a')
            if node.children[idx] is None:
                node.children[idx] = Trie()
            node = node.children[idx]
        node.is_end = True

    def search(self, w):
        node = self
        for c in w:
            idx = ord(c) - ord('a')
            if node.children[idx] is None:
                return False
            node = node.children[idx]
        return node.is_end


def has_words(words: list[str], queries: list[str]) -> list[bool]:
    trie = Trie()
    for w in words:
        trie.insert(w)
    out = []
    for q in queries:
        out.append(trie.search(q))
    return out
