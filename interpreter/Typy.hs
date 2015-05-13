{-# LANGUAGE TypeSynonymInstances #-}
{-# LANGUAGE FlexibleInstances #-}

module Typy where
import Data.Default
import Data.Complex
import Data.Matrix
import Data.Bits
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
                  | Calkowita Integer
                  | Logiczna Bool
                  | Zespolona (Complex Double)
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
    Calkowita i -> show i
    Logiczna b -> show b
    Zespolona zz -> show zz

instance Show TypQCL where
  show x = case x of
    PT c -> show c
    ZT x -> show x

{- Fragment napisany przez P. Patryka Czarnika w ramach konsultacji -}
class Pakowalny a where
  pak :: a -> TypQCL
  odpak :: TypQCL -> a

instance Pakowalny Integer where
  pak i = PT (Calkowita i)
  odpak (PT (Calkowita i)) = i

instance Pakowalny (Complex Double) where
  pak i = PT (Zespolona i)
  odpak (PT (Zespolona i)) = i

instance Pakowalny String where
  pak s = (PT (Napis s))
  odpak (PT (Napis s)) = s

instance Pakowalny Bool where
  pak i = PT (Logiczna i)
  odpak (PT (Logiczna i)) = i

instance Pakowalny TypQCL where
  pak = id
  odpak = id

{- Koniec fragmentu napisanego przez P. Patryka Czarnika -}

instance Num TypQCL where
  negate (PT (Calkowita a)) = pak $ negate a
  negate (PT (Zespolona a)) = pak $ negate a
  negate (PT (Logiczna a)) = pak $ not a
  (+) (PT (Calkowita a)) (PT (Calkowita b)) = pak $ a + b
  (+) (PT (Zespolona a)) (PT (Zespolona b)) = pak $ a * b
  (+) (PT (Napis a)) (PT (Napis b)) = pak $ a ++ b
  abs (PT (Calkowita a)) = pak $ abs a
  abs (PT (Zespolona a)) = pak $ abs a
  (*) (PT (Calkowita a)) (PT (Calkowita b)) = pak $ a * b
  (*) (PT (Zespolona a)) (PT (Zespolona b)) = pak $ a * b
  signum (PT (Zespolona a)) = pak $ signum a
  signum (PT (Calkowita a)) = pak $ signum a
  fromInteger a = pak a

instance Bits TypQCL where
  (.&.) (PT (Calkowita a)) (PT (Calkowita b)) = pak $ (.&.) a  b
  (.&.) (PT (Logiczna a))  (PT (Logiczna b)) = pak $ (.&.) a  b
  (.|.) (PT (Calkowita a)) (PT (Calkowita b)) = pak $ (.|.) a  b
  (.|.) (PT (Logiczna a))  (PT (Logiczna b)) = pak $ (.|.) a  b
  (complement) (PT (Calkowita a)) = pak $ (complement) a
  (complement) (PT (Logiczna a)) = pak $ (complement) a
  shift (PT (Logiczna a)) b = pak $ shift a b
  shift (PT (Calkowita a)) b = pak $ shift a b
  rotate (PT (Calkowita a)) b = pak $ rotate a b
  rotate (PT (Logiczna a)) b = pak $ rotate a b
  bitSizeMaybe (PT (Calkowita a)) = bitSizeMaybe a
  bitSizeMaybe (PT (Logiczna a)) = bitSizeMaybe a
  isSigned (PT (Calkowita a)) = isSigned a
  isSigned (PT (Logiczna a)) = isSigned a
  xor (PT (Calkowita a)) (PT (Calkowita b)) = pak $ xor a b
  xor (PT (Logiczna a)) (PT (Logiczna b)) = pak $ xor a b
  popCount (PT (Calkowita a)) = popCount a
  popCount (PT (Logiczna a)) = popCount a
  testBit (PT (Calkowita a)) = testBit a
  testBit (PT (Logiczna a)) = testBit a
  bitSize (PT (Calkowita a)) =
    case bitSizeMaybe a of
     Just x -> x
     Nothing -> undefined
  bitSize (PT (Logiczna a)) =
    case bitSizeMaybe a of
     Just x -> x
     Nothing -> undefined
