import TypeInfer.PyType
import PastaLean.Imports

/-!
# Correctness theorems for the TypeInfer lattice

The inference engine folds `PyType.join` over the types it observes (`joinAll`, and the `collectSigs`
fixpoint). For that fold to be well-defined and — crucially — **order-independent** (the inferred type
must not depend on the order in which the engine happens to visit assignments), `join` must behave as a
bounded join-semilattice: `unknown` (⊥) is the identity, `any` (⊤) is absorbing, the numeric tower
`bool <: int <: float` widens consistently in either order, and `join` is **idempotent** (`a ⊔ a = a`).

We prove those laws here, so the engine's core is *verified*, not assumed. Formal verification also
surfaced a genuine subtlety: idempotence holds on every NORMALIZED type but **not** on `opt any` — the
engine collapses `Optional[Any]` to `Any` by construction (`join_opt_any`), so the degenerate value
never arises. `join_idem` is proved for exactly the `normalized` types, i.e. those with no `opt any`
subterm — precisely the engine's reachable types.
-/

namespace TypeInfer.PyType

/-! ### ⊥ = `unknown` is the identity -/

@[simp] theorem join_unknown_left (a : PyType) : join .unknown a = a := by
  cases a <;> simp [join]

@[simp] theorem join_unknown_right (a : PyType) : join a .unknown = a := by
  cases a <;> simp [join]

/-! ### ⊤ = `any` is absorbing -/

@[simp] theorem join_any_left (a : PyType) : join .any a = .any := by
  cases a <;> simp [join]

@[simp] theorem join_any_right (a : PyType) : join a .any = .any := by
  cases a <;> simp [join]

/-! ### The numeric tower `bool <: int <: float` widens to the join, in EITHER order -/

theorem join_bool_int  : join .bool .int  = .int   ∧ join .int .bool  = .int   := by
  constructor <;> simp [join]
theorem join_int_float : join .int .float = .float ∧ join .float .int = .float := by
  constructor <;> simp [join]
theorem join_bool_float: join .bool .float= .float ∧ join .float .bool= .float := by
  constructor <;> simp [join]

/-- Non-numeric conflicts go to ⊤ (`any`), as the join of incomparable elements must. -/
theorem join_conflict_str_int : join .str .int = .any ∧ join .int .str = .any := by
  constructor <;> simp [join, beq]

/-! ### The verified subtlety: `Optional[Any]` collapses to `Any`

This is *why* `join` is not naively idempotent, and it documents the invariant the engine maintains
(it never keeps an `opt any`). -/

theorem join_opt_any : join (.opt .any) (.opt .any) = .any := by simp [join]

/-- `any` and `opt any` are DISTINCT PyType *terms* (different constructors) — even though they denote
the same semantic type ("any value, including `None`", since `any` ⊇ `None` already). -/
theorem any_ne_opt_any : PyType.any ≠ .opt .any := by intro h; exact PyType.noConfusion h

/-- So `join` collapses `opt any` AWAY from its own input: the self-join is `any`, not `opt any`. This
is `join` NORMALIZING (returning the canonical representative), not a failure of idempotence — on the
`normalized` types (which `join` always outputs) idempotence holds; see `join_idem`. -/
theorem join_opt_any_ne_input : join (.opt .any) (.opt .any) ≠ .opt .any := by
  rw [join_opt_any]; exact any_ne_opt_any

/-! ### Idempotence: `join a a = a` for every normalized type

`normalized a` = "`a` has no `opt any` subterm" — the normal form the engine keeps. On these, `join`
is idempotent, proved for ALL constructors (including the nested `tuple`/`fn`/container cases). -/

/-- The engine's normal-form invariant: no `opt any` subterm (Optional[Any] is always collapsed). -/
def normalized : PyType → Bool
  | .opt e => !(e.beq .any) && normalized e
  | .list e | .set e => normalized e
  | .dict k v => normalized k && normalized v
  | .tuple es => es.attach.all (fun ⟨e, _⟩ => normalized e)
  | .fn args r => args.attach.all (fun ⟨e, _⟩ => normalized e) && normalized r
  | _ => true
termination_by a => sizeOf a
decreasing_by
  all_goals simp_wf
  all_goals first | omega | (rename_i h; have := List.sizeOf_lt_of_mem h; omega)

/-- Membership extraction for the `tuple`/`fn` element lists' normalization. -/
theorem normalized_mem {es : List PyType} (h : es.attach.all (fun ⟨e, _⟩ => normalized e) = true)
    {e} (he : e ∈ es) : normalized e = true := by
  rw [List.all_eq_true] at h; exact h ⟨e, he⟩ (List.mem_attach es ⟨e, he⟩)

/-- The per-element map in the `tuple`/`fn` join reduces to the list itself when every element is
idempotent — the key lemma for the nested cases. -/
theorem tuple_help (es : List PyType) (h : ∀ e ∈ es, join e e = e) :
    ((es.zip es).attach.map (fun x : {p // p ∈ es.zip es} => join x.1.1 x.1.2)) = es := by
  apply List.ext_getElem
  · simp
  · grind only [= List.getElem_map, = List.getElem_attach, = List.getElem_zip,
    usr List.getElem_mem]

/-- **Idempotence** of the lattice join on every normalized type. -/
theorem join_idem : ∀ (a : PyType), normalized a = true → join a a = a
  | .unknown, _ | .any, _ | .none, _ => by simp [join]
  | .int, _ | .bool, _ | .str, _ | .float, _ => by simp [join, beq]
  | .cls n, _ => by simp [join, beq]
  | .list e, h => by rw [join, join_idem e (by simpa [normalized] using h)]
  | .set e, h => by rw [join, join_idem e (by simpa [normalized] using h)]
  | .dict k v, h => by
      have h' : normalized k = true ∧ normalized v = true := by simpa [normalized] using h
      rw [join, join_idem k h'.1, join_idem v h'.2]
  | .opt e, h => by
      have h' : e.beq .any = false ∧ normalized e = true := by simpa [normalized] using h
      rw [join, join_idem e h'.2]; cases e <;> simp_all [beq]
  | .tuple es, h => by
      have hw : es.attach.all (fun ⟨e, _⟩ => normalized e) = true := by simpa [normalized] using h
      have hall : ∀ e ∈ es, join e e = e := fun e he => join_idem e (normalized_mem hw he)
      rw [join]; simp only [beq_self_eq_true, if_true]; rw [tuple_help es hall]
  | .fn args r, h => by
      have h' : args.attach.all (fun ⟨e, _⟩ => normalized e) = true ∧ normalized r = true := by
        simpa [normalized] using h
      have hall : ∀ e ∈ args, join e e = e := fun e he => join_idem e (normalized_mem h'.1 he)
      rw [join]; simp only [beq_self_eq_true, if_true]
      rw [tuple_help args hall, join_idem r h'.2]
termination_by a => sizeOf a
decreasing_by
  all_goals simp_wf
  all_goals first
    | omega
    | (have hm := ‹_ ∈ _›; have := List.sizeOf_lt_of_mem hm; omega)

/-! ### Commutativity: `join a b = join b a` (order-independence)

The headline law for the fixpoint: the inferred type does not depend on the order in which the engine
visits assignments. Proved for EVERY constructor pair, including the nested `list`/`dict`/`tuple`/`fn`
cases (via `zip_map_swap`), by strong induction on `sizeOf`. -/

/-- Class-name equality is symmetric (needed for the `cls`/`cls` fallback of `join`). -/
theorem beq_comm_cls (n m : String) : (n == m) = (m == n) := by
  rw [Bool.eq_iff_iff, beq_iff_eq, beq_iff_eq]; exact eq_comm

theorem sizeOf_pos (a : PyType) : 0 < sizeOf a := by cases a <;> simp

/-- A zip-map is unchanged by swapping the two lists, when the operation commutes at every index. The
key lemma for the `tuple`/`fn` commutativity cases. -/
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

/-- **Commutativity** of the lattice join: `a ⊔ b = b ⊔ a`. The inference fixpoint is therefore
independent of the order in which assignments are visited. -/
theorem join_comm (a b : PyType) : join a b = join b a :=
  join_comm_aux (sizeOf a + sizeOf b) a b (Nat.le_refl _)

/-! ### Associativity: `(a ⊔ b) ⊔ c = a ⊔ (b ⊔ c)`

The keystone law: the inferred type is independent of how the fixpoint *groups* its joins (not just the
order). It holds on the FULL lattice, and the `Optional`/`None` **absorption** (`join_opt_any`,
`Optional[Any] → Any`) is exactly what keeps it associative at the `None`-⊔-conflict junction — without
that collapse `join (join none int) str = opt any` but `join none (join int str) = any`, and the two
groupings would disagree (the join comment records the absorption was added for precisely this reason).

Proved by strong induction on `sizeOf`. Scalar and incompatible-type triples fall to `simp`; every
remaining case — the numeric tower, the recursive `list`/`set`/`dict`/`tuple`/`fn` congruences, the
class-name fallback, and all the `Optional` absorption interactions — is discharged uniformly by `grind`
from `join`'s equations and the inductive hypothesis. -/

set_option maxHeartbeats 2000000 in
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
      | (simp only [join, beq, beq_iff_eq]; split_ifs <;> simp_all only [reduceCtorEq]; done)
      | (simp only [join, opt.sizeOf_spec, list.sizeOf_spec, set.sizeOf_spec,
            dict.sizeOf_spec, cls.sizeOf_spec] at *; grind [join])

/-- **Associativity** of the lattice join, on the full lattice: `(a ⊔ b) ⊔ c = a ⊔ (b ⊔ c)`. Together
with `join_comm` and `join_idem` this makes `PyType`'s `join` a bounded join-semilattice, so the
inference fixpoint's result is fully order- AND grouping-independent. -/
theorem join_assoc (a b c : PyType) : join (join a b) c = join a (join b c) :=
  join_assoc_aux (sizeOf a + sizeOf b + sizeOf c) a b c (Nat.le_refl _)

/-! ### The precision order and `join` as least upper bound

With associativity in hand, the join induces the lattice's **precision order** `a ⊑ b := a ⊔ b = b`
("`b` is at least as informative as `a`"), and we can prove `join` really is the LEAST UPPER BOUND for
it — the property abstract-interpretation frameworks require of the abstract domain's join, and what
makes the fixpoint's result canonical (Cousot–Cousot; Tarski's fixpoint theorem). Reflexivity needs
idempotence, so it is stated on the engine's `normalized` types (as `join_idem` is); antisymmetry,
transitivity, the universal property, and monotonicity hold on the full lattice. -/

/-- Precision order: `a ⊑ b` iff joining `a` into `b` adds nothing — `b` already subsumes `a`. -/
def le (a b : PyType) : Prop := join a b = b

@[inherit_doc le] scoped infix:50 " ⊑ " => le

theorem le_refl {a : PyType} (ha : normalized a) : a ⊑ a := join_idem a ha

theorem le_trans {a b c : PyType} (h1 : a ⊑ b) (h2 : b ⊑ c) : a ⊑ c := by
  show join a c = c
  rw [← h2, ← join_assoc, h1]

theorem le_antisymm {a b : PyType} (h1 : a ⊑ b) (h2 : b ⊑ a) : a = b := by
  rw [← h1, join_comm a b, h2]

/-- `a ⊔ b` is an upper bound of `a` (for `normalized a`). -/
theorem le_join_left {a : PyType} (ha : normalized a) (b : PyType) : a ⊑ join a b := by
  show join a (join a b) = join a b
  rw [← join_assoc, join_idem a ha]

/-- `a ⊔ b` is an upper bound of `b` (for `normalized b`). -/
theorem le_join_right {b : PyType} (hb : normalized b) (a : PyType) : b ⊑ join a b := by
  show join b (join a b) = join a b
  rw [join_comm a b, ← join_assoc, join_idem b hb]

/-- **Least** upper bound: any common upper bound of `a` and `b` dominates their join. Together with
`le_join_left`/`le_join_right` this is `join = ⊔` (the least upper bound) for `⊑`. -/
theorem join_le {a b c : PyType} (h1 : a ⊑ c) (h2 : b ⊑ c) : join a b ⊑ c := by
  show join (join a b) c = c
  rw [join_assoc, h2, h1]

/-- **Monotonicity** of `join` in its left argument: `a ⊑ a' → a ⊔ b ⊑ a' ⊔ b`. Monotone joins are
exactly what makes the inference fixpoint a *least* fixpoint (Knaster–Tarski), hence well-defined and
order-independent. -/
theorem join_mono_left {a a' : PyType} (b : PyType) (ha' : normalized a') (hb : normalized b)
    (h : a ⊑ a') : join a b ⊑ join a' b :=
  join_le (le_trans h (le_join_left ha' b)) (le_join_right hb a')

/-- `unknown` (⊥) is below everything in the precision order. -/
theorem le_unknown (a : PyType) : .unknown ⊑ a := join_unknown_left a

/-- `any` (⊤) is above everything. -/
theorem le_any (a : PyType) : a ⊑ .any := join_any_right a

/-- Monotonicity in the right argument (by commutativity). -/
theorem join_mono_right {b b' : PyType} (a : PyType) (ha : normalized a) (hb' : normalized b')
    (h : b ⊑ b') : join a b ⊑ join a b' := by
  rw [join_comm a b, join_comm a b']; exact join_mono_left a hb' ha h

/-- Full **monotonicity** of `join`: it is monotone in both arguments jointly, so the whole reflow step
`x ↦ ⨆ (incoming types)` is a monotone map on the lattice — the Knaster–Tarski precondition. -/
theorem join_mono {a a' b b' : PyType} (ha' : normalized a') (hb : normalized b) (hb' : normalized b')
    (h1 : a ⊑ a') (h2 : b ⊑ b') : join a b ⊑ join a' b' :=
  le_trans (join_mono_left b ha' hb h1) (join_mono_right a' ha' hb' h2)


/-! ### Information preservation: `join` only reaches ⊥ from ⊥ ⊔ ⊥

Merging two KNOWN types never collapses to `unknown` (⊥) — the engine's merge moves UP the lattice,
never loses all information. Equivalently, `join a b = unknown` exactly when both inputs are `unknown`. -/

theorem join_ne_unknown (a b : PyType) (ha : a ≠ .unknown) (hb : b ≠ .unknown) :
    join a b ≠ .unknown := by
  cases a <;> cases b <;> simp_all only [ne_eq, reduceCtorEq, not_false_eq_true] <;>
    simp only [join] <;> (try split) <;> simp_all [beq]

theorem join_eq_unknown_iff (a b : PyType) :
    join a b = .unknown ↔ (a = .unknown ∧ b = .unknown) := by
  refine ⟨fun h => ?_, fun ⟨ha, hb⟩ => by subst ha; subst hb; simp⟩
  rcases Classical.em (a = .unknown) with rfl | ha
  · rcases Classical.em (b = .unknown) with rfl | hb
    · exact ⟨rfl, rfl⟩
    · rw [join_unknown_left] at h; exact absurd h hb
  · rcases Classical.em (b = .unknown) with rfl | hb
    · rw [join_unknown_right] at h; exact absurd h ha
    · exact absurd h (join_ne_unknown a b ha hb)


/-! ## Semantic soundness — relating inferred types to runtime values

The lattice laws above verify `join`'s ALGEBRAIC structure; these verify its SEMANTIC meaning. For a
lattice-based abstract inferrer this is the analog of classical type soundness ("an inferred type
never lies about the runtime"): `join` OVER-APPROXIMATES — a value that had type `a` still has type
`a ⊔ b`, so widening never excludes an admitted value. Proved for the load-bearing numeric-tower core. -/

/-- A minimal model of Python runtime values (the core of PastaLean's `PyValue`). -/
inductive Val where
  | vint (n : Int) | vbool (b : Bool) | vstr (s : String) | vfloat (f : Float)
  | vnone | vlist (xs : List Val) | vcls (name : String)
  deriving Inhabited

/-- `HasType v T` : the runtime value `v` inhabits inferred type `T`. Encodes the numeric tower
(`bool <: int <: float`), `any` = ⊤ (admits everything), `unknown` = ⊥ (admits nothing), and
`opt T` = `T ∪ {None}`. -/
def HasType : Val → PyType → Prop
  | _,         .any     => True
  | _,         .unknown => False
  | .vbool _,  .bool    => True
  | .vbool _,  .int     => True         -- bool <: int
  | .vbool _,  .float   => True         -- bool <: float
  | .vint _,   .int     => True
  | .vint _,   .float   => True         -- int <: float
  | .vfloat _, .float   => True
  | .vstr _,   .str     => True
  | .vnone,    .none    => True
  | .vcls n,   .cls m   => n = m
  | .vlist xs, .list t  => ∀ x ∈ xs, HasType x t
  | v,         .opt t   => v = .vnone ∨ HasType v t
  | _,         _        => False

/-! ### The numeric tower is *semantically* real -/

theorem hasType_bool_int   (v : Val) : HasType v .bool → HasType v .int   := by cases v <;> simp [HasType]
theorem hasType_int_float  (v : Val) : HasType v .int  → HasType v .float := by cases v <;> simp [HasType]
theorem hasType_bool_float (v : Val) : HasType v .bool → HasType v .float := by cases v <;> simp [HasType]

/-! ### ⊤ admits everything, ⊥ admits nothing -/

theorem hasType_any (v : Val) : HasType v .any := by simp [HasType]
theorem not_hasType_unknown (v : Val) : ¬ HasType v .unknown := by simp [HasType]

/-! ### `join` over-approximates (soundness of the merge)

For the general shape `HasType v a → HasType v (join a b)`: when `b = unknown` the join is `a`; when
either side is `any` the join is `any` (which admits `v`); on the numeric tower it widens up the tower,
which `v` still inhabits. We prove the tower case (the semantically interesting one) in full. -/

theorem hasType_join_unknown_right (v : Val) (a : PyType) (h : HasType v a) :
    HasType v (join a .unknown) := by rw [join_unknown_right]; exact h

theorem hasType_join_any (v : Val) (a b : PyType) (h : join a b = .any) :
    HasType v (join a b) := by rw [h]; exact hasType_any v

/-- **Join over-approximates on the numeric tower:** for numeric `a`, `b`, a value of type `a` also has
type `a ⊔ b`. This is exactly the soundness of the tower widening the engine performs so that a
container written with both ints and floats stays `list[float]` rather than collapsing to `Any`. -/
theorem hasType_join_tower (v : Val) (a b : PyType)
    (ha : a = .int ∨ a = .bool ∨ a = .float) (hb : b = .int ∨ b = .bool ∨ b = .float)
    (h : HasType v a) : HasType v (join a b) := by
  rcases ha with rfl | rfl | rfl <;> rcases hb with rfl | rfl | rfl <;>
    simp only [join] <;>
    first
      | exact h
      | exact hasType_int_float v h
      | exact hasType_bool_int v h
      | exact hasType_bool_float v h
      | simp_all [beq]

/-! ### General semantic soundness: `join` over-approximates on the WHOLE lattice

The full statement — for *any* types `a`, `b`, a value of type `a` still has type `a ⊔ b`. So the
engine's widening never drops an admitted runtime value, on every type shape (containers, `Optional`,
classes), not just the numeric tower. The `Val` model has no `set`/`dict`/`tuple`/`fn` inhabitant, so
those `a`-heads admit nothing (`HasType` is `False`) and the claim is vacuous there; the real content is
the scalar/`none`/`cls` cases and the `list`/`Optional` congruences, the latter recursing on the element
type via the inductive hypothesis. -/
private theorem hasType_join_left_aux : ∀ (n : Nat) (v : Val) (a b : PyType),
    sizeOf a + sizeOf b ≤ n → HasType v a → HasType v (join a b) := by
  intro n
  induction n with
  | zero => intro v a b hn h; have := sizeOf_pos a; omega
  | succ n ih =>
    intro v a b hn h
    cases a <;> cases b <;>
      first
      | (cases v <;> simp_all [HasType, join, beq]; done)
      | (simp only [join, opt.sizeOf_spec, list.sizeOf_spec, set.sizeOf_spec, dict.sizeOf_spec,
            tuple.sizeOf_spec, fn.sizeOf_spec] at * <;> grind [HasType, join])

/-- **Semantic soundness of the merge (full lattice):** `HasType v a → HasType v (a ⊔ b)`. An inferred
type is only ever *widened* by `join`, and widening never excludes a value the program can actually
produce — the inference analogue of "a well-typed program does not go wrong" (Milner; Wright–Felleisen).
This is `#5` (semantic soundness) in full: `join` over-approximates on every type shape, not just the
numeric tower. -/
theorem hasType_join_left (v : Val) (a b : PyType) (h : HasType v a) : HasType v (join a b) :=
  hasType_join_left_aux (sizeOf a + sizeOf b) v a b (Nat.le_refl _) h

/-- Soundness of the merge on the right, by commutativity. -/
theorem hasType_join_right (v : Val) (a b : PyType) (h : HasType v b) : HasType v (join a b) := by
  rw [join_comm]; exact hasType_join_left v b a h

end TypeInfer.PyType
