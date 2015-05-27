{-# LANGUAGE FlexibleInstances #-}
module AlgebraLiniowa where
import Data.Complex
import Eigensystem
import QuantumVector
-- Dwuwymiarowa przestrzeń
-- ket to pionowe wektory

type QKet = Ket Integer
type QBra = Bra Integer

class Rzutowalny a where
  rzutuj :: Integer -> a -> Complex Double

instance Rzutowalny QKet where
  rzutuj wsp = (<>) (Bra wsp)

instance Rzutowalny QBra where
  rzutuj wsp = (flip (<>)) (Ket wsp)

-- pierwszy argument to jaki ma byc rozmiar operatora.
zrob_operator :: Integer -> Ket Integer -> Bra Integer -> [[Scalar]]
zrob_operator rozmiar ket bra =
  [
    [ (rzutuj wspolrzedna_ket ket) * (rzutuj wspolrzedna_bra bra) |
      wspolrzedna_ket <- [0 .. rozmiar - 1]]
  | wspolrzedna_bra <- [0 .. rozmiar - 1]
  ]


-- ket *><* bra = undefined
  -- operator [Ket (0 :: Integer), Ket (1 :: Integer)]

-- (*><*) :: Ket Integer -> Bra Integer -> [Ket Integer]
-- ket *><* bra =
--   [(x1 :|> Ket 0) +> (y1 :|> Ket 1),
--    (x2 :|> Ket 0) +> (y2 :|> Ket 1)] where
--   x1 = ((Bra (0 :: Integer)) <> ket) * (bra <> (Ket (0 :: Integer)))
--   y1 = ((Bra (1 :: Integer)) <> ket) * (bra <> (Ket (0 :: Integer)))
--   x2 = ((Bra (0 :: Integer)) <> ket) * (bra <> (Ket (1 :: Integer)))
--   y2 = ((Bra (1 :: Integer)) <> ket) * (bra <> (Ket (1 :: Integer)))

-- funkcja_z_macierzy :: [Ket Integer] -> Ket Integer -> Ket Integer
-- funkcja_z_macierzy [k1, k2] ket = (x :|> Ket 0) +> (y :| Ket 1) where
--   x =
--   y =
