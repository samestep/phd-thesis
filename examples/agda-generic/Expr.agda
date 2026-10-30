-- Instance arguments over a representation: `{{Ast Pool Ref}}` is found by instance search from
-- the pool or index type, and the built pool is a second instance, `{{Current Pool}}`.
{-# OPTIONS --guardedness #-}
module Expr where

open import Data.List using (List; []; _∷_; _++_; _∷ʳ_; length; drop)
open import Data.Nat as ℕ using (ℕ; zero; suc)
open import Data.Nat.DivMod using (_/_)
open import Data.Integer using (ℤ; +_; _+_; _-_; _*_; ∣_∣; sign; _◃_)
open import Data.Integer.Show using (show)
open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Data.Sign as Sign using ()
open import Data.String using (String)
open import IO using (Main; run; putStrLn; _>>_)

data BinOp : Set where
  Add Sub Mul Div : BinOp

data Expr (Ref : Set) : Set where
  Binary : BinOp → Ref → Ref → Expr Ref
  Literal : ℤ → Expr Ref

variable Pool Ref : Set

record Ast (Pool Ref : Set) : Set where
  field
    add : Expr Ref → Pool → Pool × Ref
    get : Pool → Ref → Expr Ref
open Ast {{...}}

record Current (Pool : Set) : Set where
  constructor current
  field pool : Pool
open Current {{...}}

-- Division truncating toward zero, and 0 for a zero divisor.
quot : ℤ → ℤ → ℤ
quot l r with ∣ r ∣
... | zero = + 0
... | suc k = (sign l Sign.* sign r) ◃ (∣ l ∣ / suc k)

apply : BinOp → ℤ → ℤ → ℤ
apply Add l r = l + r
apply Sub l r = l - r
apply Mul l r = l * r
apply Div l r = quot l r

{-# TERMINATING #-}
interp : {{Ast Pool Ref}} → {{Current Pool}} → Ref → ℤ
interp e with get pool e
... | Binary op lhs rhs = apply op (interp lhs) (interp rhs)
... | Literal num = num

-- Building threads the pool through; `interp` reads it implicitly.
Build : Set → Set → Set
Build Pool Ref = Pool → Pool × Ref

lit : {{Ast Pool Ref}} → ℤ → Build Pool Ref
lit n = add (Literal n)

bin : {{Ast Pool Ref}} → BinOp → Build Pool Ref → Build Pool Ref → Build Pool Ref
bin op l r p = let (p₁ , x) = l p ; (p₂ , y) = r p₁ in add (Binary op x y) p₂

code : BinOp → ℤ
code Add = + 1
code Sub = + 2
code Mul = + 3
code Div = + 4

opOf : ℤ → BinOp
opOf (+ 1) = Add
opOf (+ 2) = Sub
opOf (+ 3) = Mul
opOf _ = Div

at : List ℤ → ℕ → ℤ
at [] _ = + 0
at (x ∷ _) zero = x
at (_ ∷ xs) (suc i) = at xs i

-- Representation 1: a node is an index into parallel lists.
data Idx : Set where
  idx : ℕ → Idx

record Columns : Set where
  constructor columns
  field ops lhs rhs : List ℤ

instance
  columnsAst : Ast Columns Idx
  Ast.add columnsAst (Binary op (idx l) (idx r)) (columns os ls rs) =
    columns (os ∷ʳ code op) (ls ∷ʳ + l) (rs ∷ʳ + r) , idx (length os)
  Ast.add columnsAst (Literal num) (columns os ls rs) =
    columns (os ∷ʳ + 0) (ls ∷ʳ num) (rs ∷ʳ + 0) , idx (length os)
  Ast.get columnsAst (columns os ls rs) (idx i) with at os i
  ... | + 0 = Literal (at ls i)
  ... | op = Binary (opOf op) (idx ∣ at ls i ∣) (idx ∣ at rs i ∣)

-- Representation 2: a node is an index into one list of triples.
data Slot : Set where
  slot : ℕ → Slot

record Triples : Set where
  constructor triples
  field cells : List ℤ

instance
  triplesAst : Ast Triples Slot
  Ast.add triplesAst (Binary op (slot l) (slot r)) (triples t) =
    triples (t ++ code op ∷ + l ∷ + r ∷ []) , slot (length t / 3)
  Ast.add triplesAst (Literal num) (triples t) =
    triples (t ++ + 0 ∷ num ∷ + 0 ∷ []) , slot (length t / 3)
  Ast.get triplesAst (triples t) (slot i) with drop (3 ℕ.* i) t
  ... | + 0 ∷ num ∷ _ = Literal num
  ... | op ∷ l ∷ r ∷ _ = Binary (opOf op) (slot ∣ l ∣) (slot ∣ r ∣)
  ... | _ = Literal (+ 0)

outer inner : String
outer = show (interp e)
  where
    built = bin Div (bin Mul (bin Sub (lit (+ 7)) (lit (+ 10))) (lit (+ 7))) (lit (+ 2))
                (columns [] [] [])
    e = proj₂ built
    instance
      a : Current Columns
      a = current (proj₁ built)
inner = show (interp f)
  where
    built = bin Div (bin Add (lit (+ 4)) (lit (+ 4))) (bin Sub (lit (+ 4)) (lit (+ 4)))
                (triples [])
    f = proj₂ built
    instance
      b : Current Triples
      b = current (proj₁ built)

main : Main
main = run (putStrLn outer >> (putStrLn inner >> putStrLn outer))
