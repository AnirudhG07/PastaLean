import PastaLean.Imports
import TypeInfer.PyType

/-!
# Associativity of the type-lattice join (isolated)

`join_assoc` — `(a ⊔ b) ⊔ c = a ⊔ (b ⊔ c)` on the FULL lattice — is proved here on its own because it
is by far the slowest proof in the development: it case-splits over all constructor *triples* and closes
each with `grind`. It lives in its own file so the rest of `TypeInfer.Theorems` can be checked without
paying that cost, and so this proof can be (re)built on demand.

No `maxHeartbeats` cap: the triple split is genuinely long-running, and a finite budget makes `grind`
*deterministically time out* on the `Optional`-absorption triples rather than finish. `0` means unlimited.

`join_comm` and the ⊥/⊤ absorption lemmas are proved here too and handed to `grind`, because the
`Optional` triples specifically need them (the two groupings differ by a commutation and by an `x ⊔ any`
/ `x ⊔ unknown` that must collapse); `grind` cannot rediscover them on its own.
-/

namespace TypeInfer.PyType

set_option maxHeartbeats 0

theorem sizeOf_pos (a : PyType) : 0 < sizeOf a := by cases a <;> simp

@[simp] theorem join_unknown_left (a : PyType) : join .unknown a = a := by cases a <;> simp [join]
@[simp] theorem join_unknown_right (a : PyType) : join a .unknown = a := by cases a <;> simp [join]
@[simp] theorem join_any_left (a : PyType) : join .any a = .any := by cases a <;> simp [join]
@[simp] theorem join_any_right (a : PyType) : join a .any = .any := by cases a <;> simp [join]

/-! ### Commutativity (needed by the associativity `grind`) -/

/-- Class-name equality is symmetric (needed for the `cls`/`cls` fallback of `join`). -/
theorem beq_comm_cls (n m : String) : (n == m) = (m == n) := by
  rw [Bool.eq_iff_iff, beq_iff_eq, beq_iff_eq]; exact eq_comm

/-- A zip-map is unchanged by swapping the two lists, when the operation commutes at every index. -/
theorem zip_map_swap {α} (as bs : List PyType) (f : PyType → PyType → α) (hlen : as.length = bs.length)
    (hf : ∀ i (h1 : i < as.length) (h2 : i < bs.length), f as[i] bs[i] = f bs[i] as[i]) :
    (as.zip bs).attach.map (fun x : {p // p ∈ as.zip bs} => f x.1.1 x.1.2)
    = (bs.zip as).attach.map (fun x : {p // p ∈ bs.zip as} => f x.1.1 x.1.2) := by
  apply List.ext_getElem
  · simp [hlen]
  · grind only [= List.length_map, = List.getElem_map, = List.length_attach, = List.getElem_attach,
    = List.length_zip, = List.getElem_zip]

private theorem join_comm_aux : ∀ (n : Nat) (a b : PyType), sizeOf a + sizeOf b ≤ n →
    join a b = join b a := by
  intro n
  induction n with
  | zero => intro a b h; have := sizeOf_pos a; omega
  | succ n ih =>
    intro a b hn
    cases a <;> cases b <;>
      try (first
            | rfl
            | (simp [join, beq]; done)
            | (rw [join, join]; rw [ih _ _ (by
                simp only [PyType.list.sizeOf_spec, PyType.set.sizeOf_spec, PyType.opt.sizeOf_spec]
                  at hn; omega)]))
    case cls.cls n m =>
      grind only [join, beq]
    case dict.dict k1 v1 k2 v2 =>
      simp only [join]
      rw [ih k1 k2 (by simp only [PyType.dict.sizeOf_spec] at hn; omega),
          ih v1 v2 (by simp only [PyType.dict.sizeOf_spec] at hn; omega)]
    case tuple.tuple as bs =>
      simp only [join]
      by_cases hl : as.length = bs.length
      · rw [if_pos (by simpa using hl), if_pos (by simpa using hl.symm)]; congr 1
        apply zip_map_swap as bs _ hl
        intro i h1 h2
        refine ih as[i] bs[i] ?_
        have := List.sizeOf_lt_of_mem (List.getElem_mem (l := as) h1)
        have := List.sizeOf_lt_of_mem (List.getElem_mem (l := bs) h2)
        simp only [PyType.tuple.sizeOf_spec] at hn; omega
      · rw [if_neg (by simpa using hl), if_neg (by simpa using fun h => hl h.symm)]
    case fn.fn as r1 bs r2 =>
      simp only [join]
      by_cases hl : as.length = bs.length
      · rw [if_pos (by simpa using hl), if_pos (by simpa using hl.symm)]
        rw [ih r1 r2 (by simp only [PyType.fn.sizeOf_spec] at hn; omega)]; congr 1
        apply zip_map_swap as bs _ hl
        intro i h1 h2
        refine ih as[i] bs[i] ?_
        have := List.sizeOf_lt_of_mem (List.getElem_mem (l := as) h1)
        have := List.sizeOf_lt_of_mem (List.getElem_mem (l := bs) h2)
        simp only [PyType.fn.sizeOf_spec] at hn; omega
      · rw [if_neg (by simpa using hl), if_neg (by simpa using fun h => hl h.symm)]

/-- **Commutativity** of the lattice join: `a ⊔ b = b ⊔ a`. -/
theorem join_comm (a b : PyType) : join a b = join b a :=
  join_comm_aux (sizeOf a + sizeOf b) a b (Nat.le_refl _)

/-! ### Associativity -/

private theorem join_assoc_aux : ∀ (n : Nat) (a b c : PyType), sizeOf a + sizeOf b + sizeOf c ≤ n →
    join (join a b) c = join a (join b c) := by
  intro n
  induction n with
  | zero => intro a b c h; have := sizeOf_pos a; omega
  | succ n ih =>
    intro a b c hn
    cases a <;> cases b <;> cases c <;>
      first
      | (simp only [join, beq, reduceCtorEq, ite_true, ite_false, ite_self]; done)
      | (simp only [join, beq, reduceIte, reduceCtorEq]; split_ifs <;> simp_all only [reduceCtorEq]; done)
      -- `grind`, but handed commutativity, the ⊥/⊤ absorption lemmas, and the size specs so it can
      -- reduce the `Optional` combinator's `match` and apply the IH inside it.
      | (simp_all only [join, opt.sizeOf_spec, list.sizeOf_spec, set.sizeOf_spec, dict.sizeOf_spec,
            tuple.sizeOf_spec, fn.sizeOf_spec, cls.sizeOf_spec]
         grind [join, join_comm, join_any_left, join_any_right, join_unknown_left, join_unknown_right])

/-- **Associativity** of the lattice join, on the full lattice: `(a ⊔ b) ⊔ c = a ⊔ (b ⊔ c)`. -/
theorem join_assoc (a b c : PyType) : join (join a b) c = join a (join b c) :=
  join_assoc_aux (sizeOf a + sizeOf b + sizeOf c) a b c (Nat.le_refl _)

end TypeInfer.PyType
