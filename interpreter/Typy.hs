{-# LANGUAGE TypeSynonymInstances #-}
{-# LANGUAGE FlexibleInstances #-}

module Typy where
import Data.Complex
import Data.Matrix
type Loc = Integer
data Komorka = KomTab { lok :: Loc,
                        poz :: Integer
                      }
             | KomZm { lok :: Loc
                     }
data OgolnyTypQCL a = PT ProstyTypQCL
                    | ZT (ZlozonyTypQCL a)
                    deriving (Eq, Ord, Read)

type TypQCL = OgolnyTypQCL ProstyTypQCL

instance (RealFloat a) => Ord (Complex a) where
  x <= y = (magnitude x)  <= (magnitude y)

data ProstyTypQCL = Napis String
                  | Liczba Integer
                  | ZmiennaLogiczna Bool
                  | ZmiennaZespolona (Complex Double)
                  | Nic
                  deriving (Eq, Ord, Read)

data ZlozonyTypQCL a = Tab { tablica :: [a],
                             rozmiar :: Integer
                           }
                     | Wektor { tablica :: [a],
                                wymiar :: Integer
                     }
                     | Tensor { costam :: Integer
                              }
                     | Macierz {}
                     deriving (Eq, Ord, Show, Read)
                                          -- | Tensor a
                                          -- | Macierz a

zrob_tablice :: Integer -> TypQCL
zrob_tablice dlugosc = ZT (Tab { tablica = [],
                                 rozmiar = dlugosc
                               })


instance Show ProstyTypQCL where
  show x = case x of
    Napis s -> s
    Liczba i -> show i
    ZmiennaLogiczna b -> show b
    ZmiennaZespolona zz -> show zz

instance Show TypQCL where
  show x = case x of
    PT c -> show c
    ZT x -> show x

{- Fragment napisany przez P. Patryka Czarnika w ramach konsultacji -}
class Pakowalny a where
  pak :: a -> TypQCL
  odpak :: TypQCL -> a

instance Pakowalny Integer where
  pak i = PT (Liczba i)
  odpak (PT (Liczba i)) = i

instance Pakowalny (Complex Double) where
  pak i = PT (ZmiennaZespolona i)
  odpak (PT (ZmiennaZespolona i)) = i

instance Pakowalny String where
  pak s = (PT (Napis s))
  odpak (PT (Napis s)) = s

instance Pakowalny Bool where
  pak i = PT (ZmiennaLogiczna i)
  odpak (PT (ZmiennaLogiczna i)) = i
