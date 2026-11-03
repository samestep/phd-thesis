{-# LANGUAGE AllowAmbiguousTypes, ScopedTypeVariables, TypeApplications #-}

-- Type classes, with `compensated`'s `Compensated Double` as the
-- double-double. Literals already follow the type: `10000000.2` means
-- `fromRational (100000002 % 10)` at whatever type is wanted, rounded to
-- that type's precision, and `0` is `fromInteger 0`. So the routine needed
-- only its signatures: class constraints instead of `Double` (one
-- `:: Double` or `[Double]` in the call tree and it would no longer
-- type-check at another type). `readings` gets its type from the one
-- wanted, but nothing passed to `report` has it, so `report`'s type is
-- ambiguous, which takes `AllowAmbiguousTypes`, and its callers choose
-- with `@Double`. Lifting the f64 readings is `realToFrac`, exact. In one
-- module like this, GHC's optimizer specializes `sd` at both types (its
-- Core has an unboxed loop for each), but that is an optimization rather
-- than a guarantee: across modules it passes class dictionaries at run
-- time unless the functions are marked `INLINABLE` or `SPECIALIZE`d.
import Data.List (foldl')
import Numeric.Compensated (Compensated)

type DoubleDouble = Compensated Double

-- NIST StRD NumAcc4: 10000000.2, then 10000000.1 and 10000000.3 in turn.
readings :: Fractional a => [a]
readings = 10000000.2 : take 1000 (cycle [10000000.1, 10000000.3])

-- The schoolbook one-pass formula, as PostgreSQL's `stddev` computed it
-- until version 12, clamp included.
sd :: (Ord a, Floating a) => [a] -> a
sd xs = if numerator <= 0 then 0 else sqrt (numerator / (n * (n - 1)))
  where
    (n, total, totalSq) = foldl' step (0, 0, 0) xs
    step (k, s, ss) x = (k + 1, s + x, ss + x * x)
    numerator = n * totalSq - total * total

showSd :: RealFrac a => a -> IO ()
showSd sd = print (round (sd * 1000000000) :: Integer)

report :: forall a. (RealFrac a, Floating a) => IO ()
report = showSd (sd (readings @a))

main :: IO ()
main = do
  report @Double
  let xs = readings @Double
  showSd (sd (map realToFrac xs :: [DoubleDouble]))
  report @DoubleDouble
