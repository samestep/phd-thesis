-- Instance arguments: `{{Pool}}` is found by instance search.
{-# OPTIONS --guardedness #-}
module Expr where

open import Data.List using (List; []; _∷_; _++_; length)
open import Data.Nat using (ℕ; zero; suc; _+_; _*_)
open import Data.Nat.Show using (show)
open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Data.String using (String)
open import IO using (Main; run; putStrLn; _>>_)

data Node : Set where
  Lit : ℕ → Node
  Add Mul : ℕ → ℕ → Node

record Pool : Set where
  constructor pool
  field nodes : List Node

at : List Node → ℕ → Node
at [] _ = Lit 0
at (n ∷ _) zero = n
at (_ ∷ ns) (suc i) = at ns i

{-# TERMINATING #-}
eval : {{Pool}} → ℕ → ℕ
eval {{p}} e with at (Pool.nodes p) e
... | Lit n = n
... | Add l r = eval l + eval r
... | Mul l r = eval l * eval r

-- Building threads the pool through; `eval` reads it implicitly.
Build = List Node → List Node × ℕ

node : Node → Build
node n ns = ns ++ (n ∷ []) , length ns

lit : ℕ → Build
lit n = node (Lit n)

add mul : Build → Build → Build
add l r ns = let (ns₁ , x) = l ns ; (ns₂ , y) = r ns₁ in node (Add x y) ns₂
mul l r ns = let (ns₁ , x) = l ns ; (ns₂ , y) = r ns₁ in node (Mul x y) ns₂

outer inner : String
outer = show (eval e)
  where
    built = mul (add (lit 1) (lit 2)) (add (lit 3) (lit 4)) []
    e = proj₂ built
    instance
      a : Pool
      a = pool (proj₁ built)
inner = show (eval f)
  where
    built = add (lit 4) (lit 4) []
    f = proj₂ built
    instance
      b : Pool
      b = pool (proj₁ built)

main : Main
main = run (putStrLn outer >> (putStrLn inner >> putStrLn outer))
