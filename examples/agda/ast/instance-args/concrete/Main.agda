-- Instance arguments: `{{ExprPool}}` is found by instance search.
{-# OPTIONS --guardedness #-}
module Main where

open import Data.List using (List; []; _∷_; _++_; length)
open import Data.Nat using (ℕ; zero; suc)
open import Data.Nat.DivMod using (_/_)
open import Data.Integer using (ℤ; +_; _+_; _-_; _*_; ∣_∣; sign; _◃_)
open import Data.Integer.Show using (show)
open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Data.Sign as Sign using ()
open import Data.String using (String)
open import IO using (Main; run; putStrLn; _>>_)

data BinOp : Set where
  Add Sub Mul Div : BinOp

data ExprRef : Set where
  ref : ℕ → ExprRef

data Expr : Set where
  Binary : BinOp → ExprRef → ExprRef → Expr
  Literal : ℤ → Expr

record ExprPool : Set where
  constructor pool
  field exprs : List Expr

get : {{ExprPool}} → ExprRef → Expr
get {{p}} (ref i) = at (ExprPool.exprs p) i
  where
    at : List Expr → ℕ → Expr
    at [] _ = Literal (+ 0)
    at (e ∷ _) zero = e
    at (_ ∷ es) (suc j) = at es j

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
interp : {{ExprPool}} → ExprRef → ℤ
interp e with get e
... | Binary op lhs rhs = apply op (interp lhs) (interp rhs)
... | Literal num = num

-- Building threads the pool through; `interp` reads it implicitly.
Build = List Expr → List Expr × ExprRef

add : Expr → Build
add e es = es ++ (e ∷ []) , ref (length es)

lit : ℤ → Build
lit n = add (Literal n)

bin : BinOp → Build → Build → Build
bin op l r es = let (es₁ , x) = l es ; (es₂ , y) = r es₁ in add (Binary op x y) es₂

outer inner : String
outer = show (interp e)
  where
    built = bin Div (bin Mul (bin Sub (lit (+ 7)) (lit (+ 10))) (lit (+ 7))) (lit (+ 2)) []
    e = proj₂ built
    instance
      a : ExprPool
      a = pool (proj₁ built)
inner = show (interp f)
  where
    built = bin Div (bin Add (lit (+ 4)) (lit (+ 4))) (bin Sub (lit (+ 4)) (lit (+ 4))) []
    f = proj₂ built
    instance
      b : ExprPool
      b = pool (proj₁ built)

main : Main
main = run (putStrLn outer >> (putStrLn inner >> putStrLn outer))
