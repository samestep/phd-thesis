-- The standard numeric classes: `Dual a` is an instance of `Num` and
-- `Fractional` whenever `a` is, so duals nest, and an integer or decimal
-- literal means `fromInteger` or `fromRational` at whatever type is expected,
-- which for a dual is a constant. So `f` is written once with plain literals,
-- and every function is polymorphic, its signature naming the class it needs
-- (`Num a =>`, or `RealFrac a =>` to round); the compiler infers the instance
-- at each call. `Dual (Dual a)` and `Dual a` are different types, so `nested`
-- has to lift the outer variable into the inner differentiation (`still x`):
-- adding it as it is (`x + variable y0`) is a compile-time error, since the
-- inner derivative then has the outer base type `a`, and `x * inner` would
-- multiply a `Dual a` by an `a`. `Prelude.show` is taken, so `show` is
-- `showFloat`. Instances are dictionaries passed at run time, but here, with
-- `-O`, GHC specializes every function at `Double` and passes none.
data Dual a = Dual {v :: a, d :: a}

f :: (Num a) => a -> a
f x = x * x * x - 2 * x - 5

constant :: (Num a) => Integer -> Dual a
constant n = Dual (fromInteger n) 0

variable :: (Num a) => a -> Dual a
variable x = Dual x 1

still :: (Num a) => a -> Dual a
still x = Dual x 0

instance (Num a) => Num (Dual a) where
  Dual a a' + Dual b b' = Dual (a + b) (a' + b')
  Dual a a' - Dual b b' = Dual (a - b) (a' - b')
  Dual a a' * Dual b b' = Dual (a * b) (a' * b + a * b')
  fromInteger = constant
  -- Not differentiable everywhere, and unused.
  abs = error "abs"
  signum = error "signum"

instance (Fractional a) => Fractional (Dual a) where
  Dual a a' / Dual b b' = Dual (a / b) ((a' * b - a * b') / (b * b))
  fromRational r = still (fromRational r)

-- `round` rounds half to even.
showFloat :: (RealFrac a) => a -> IO ()
showFloat x = print (round (x * 1000000) :: Integer)

derivatives :: (RealFrac a) => a -> IO ()
derivatives x = do
  showFloat (f x)
  showFloat (d (f (variable x)))
  showFloat (d (d (f (variable (variable x)))))

newton :: (RealFrac a) => a -> Int -> IO ()
newton _ 0 = pure ()
newton x steps = do
  let y = f (variable x)
      x' = x - v y / d y
  showFloat x'
  newton x' (steps - 1)

-- d/dx (x * d/dy (x + y)) at x = 1, y = 1.
nested :: (Fractional a) => a -> a
nested at = d (x * inner)
  where
    x = variable at
    y0 = 1
    inner = d (still x + variable y0)

main :: IO ()
main = do
  derivatives (2 :: Double)
  newton 2 4
  showFloat (nested 1)
