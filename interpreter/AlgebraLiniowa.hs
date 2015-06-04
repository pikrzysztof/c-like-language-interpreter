{-# LANGUAGE FlexibleInstances #-}
module AlgebraLiniowa where
import Data.Complex
import Eigensystem
import QuantumVector
-- Dwuwymiarowa przestrzeń
-- ket to pionowe wektory

type QKet = Ket Integer
type QBra = Bra Integer
type Macierz = [[Scalar]]

class Rzutowalny a where
  rzutuj :: Integer -> a -> Complex Double

instance Rzutowalny QKet where
  rzutuj wsp = (<>) (Bra wsp)

instance Rzutowalny QBra where
  rzutuj wsp = (flip (<>)) (Ket wsp)

-- pierwszy argument to jaki ma byc rozmiar operatora.
zrob_operator :: Integer -> QKet -> QBra -> Macierz
zrob_operator rozmiar ket bra =
  [
    [ (rzutuj wspolrzedna_ket ket) * (rzutuj wspolrzedna_bra bra) |
      wspolrzedna_ket <- [0 .. rozmiar - 1]]
  | wspolrzedna_bra <- [0 .. rozmiar - 1]
  ]

-- konstruktory liczb zespolonych
i :: Double -> Scalar
i = (:+) 0
r :: Double -> Scalar
r = (flip (:+)) 0

    -- bp od Bramek Pauliego
x_bp :: Macierz
x_bp = [[r 0, r 1], [r 1, r 0]]
y_bp :: Macierz
y_bp = [[r 0, i 1], [i (-1), r 0]]
z_bp :: Macierz
z_bp = [[r 1, r 0], [r 0, r (-1)]]

-- bramka hadamarda
h :: Macierz
h = map (map $ (*) $ sqrt 1 / 2 ) [[r 1, r 1], [r 1, r (-1)]]

-- bramka fazowa
s = map (map sqrt) z_bp

-- bramka pi/8
t = map (map sqrt) s
