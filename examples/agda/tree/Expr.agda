-- The tree Sampson starts from: each node holds its children as nested values
-- of an inductive type, so nothing needs a pool and `interp` is structural.
{-# OPTIONS --guardedness #-}
module Expr where

open import Data.Nat using (zero; suc)
open import Data.Nat.DivMod using (_/_)
open import Data.Integer using (ℤ; +_; _+_; _-_; _*_; ∣_∣; sign; _◃_)
open import Data.Integer.Show using (show)
open import Data.Sign as Sign using ()
open import Data.String using (String)
open import IO using (Main; run; putStrLn; _>>_)

data BinOp : Set where
  Add Sub Mul Div : BinOp

data Expr : Set where
  Binary : BinOp → Expr → Expr → Expr
  Literal : ℤ → Expr

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

interp : Expr → ℤ
interp (Binary op lhs rhs) = apply op (interp lhs) (interp rhs)
interp (Literal num) = num

lit : ℤ → Expr
lit = Literal

bin : BinOp → Expr → Expr → Expr
bin = Binary

outer inner : String
outer = show (interp e)
  where
    e = bin Div (bin Mul (bin Sub (lit (+ 7)) (lit (+ 10))) (lit (+ 7))) (lit (+ 2))
inner = show (interp f)
  where
    f = bin Div (bin Add (lit (+ 4)) (lit (+ 4))) (bin Sub (lit (+ 4)) (lit (+ 4)))

main : Main
main = run (putStrLn outer >> (putStrLn inner >> putStrLn outer))
