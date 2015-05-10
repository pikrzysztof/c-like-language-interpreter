module Typy where
import Data.Complex
import Data.Void
type Loc = Integer
data TypQCL a = PT ProstyTypQCL
              | ZT (ZlozonyTypQCL a)
              deriving (Eq, Ord, Show, Read)

instance (RealFloat a) => Ord (Complex a) where
  x <= y = (magnitude x)  <= (magnitude y)

data ProstyTypQCL = Napis String
                  | Liczba Num
                  | ZmiennaLogiczna Bool
                  | ZmiennaZespolona (Complex Double)
                  | Nic
                  deriving (Eq, Ord, Show, Read)
                  -- | LiczbaCalkowita Integer
                  -- | Ulamek Double


data ZlozonyTypQCL a = Tab { tablica :: [a],
                             rozmiar :: Integer
                           } deriving (Eq, Ord, Show, Read)
                                          -- | Wektor a
                                          -- | Tensor a
                                          -- | Macierz a

typ_int :: (TypQCL ProstyTypQCL) -> Num
typ_int (PT (Liczba x)) = x

zrob_tablice :: Integer -> (TypQCL ProstyTypQCL)
zrob_tablice dlugosc = ZT (Tab { tablica = [],
                                 rozmiar = dlugosc
                               })

-- wykonaj_operacje op

-- podziel :: (TypQCL ProstyTypQCL) -> (TypQCL (ProstyTypQCL) -> (TypQCL (ProstyTypQCL)
-- podziel
