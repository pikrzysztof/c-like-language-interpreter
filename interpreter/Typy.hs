{-# LANGUAGE TypeSynonymInstances #-}
{-# LANGUAGE FlexibleInstances #-}

module Typy where
import Data.Complex
import Data.Bits
import Control.Monad.RWS
import Control.Monad.Except
type Loc = Integer

type PrzetwarzaczOgolny env st a = ExceptT String (RWST env () st IO) a

instance (RealFloat a) => Ord (Complex a) where
  x <= y = (magnitude x)  <= (magnitude y)

data Komorka = KomTab { lok :: Loc,
                        poz :: Integer
                      }
             | KomZm { lok :: Loc
                     }
               deriving (Eq, Ord, Read, Show)
data OgolnyTypQCL a = PT ProstyTypQCL
                    | ZT (ZlozonyTypQCL a)
                    deriving (Eq, Ord, Read)

type TypQCL = OgolnyTypQCL ProstyTypQCL



data ProstyTypQCL = Napis String
                  | Calkowita Integer
                  | Logiczna Bool
                  | Zespolona (Complex Double)
                  | Nic
                  deriving (Eq, Ord, Read)

data ZlozonyTypQCL a = Wektor { tablica :: [a],
                                wymiar :: Integer
                     }
                     | Tensor {}
                     | Macierz {}
                     deriving (Eq, Ord, Show, Read)



instance Show ProstyTypQCL where
  show x = case x of
    Napis s -> s
    Calkowita i -> show i
    Logiczna b -> show b
    Zespolona zz -> show zz
    Nic -> "nic"
instance Show TypQCL where
  show x = case x of
    PT c -> show c
    ZT z -> show z

{- Fragment napisany przez P. Patryka Czarnika w ramach konsultacji -}
class Pakowalny a where
  pak :: a -> TypQCL
  odpak :: TypQCL -> a

instance Pakowalny Integer where
  pak i = PT (Calkowita i)
  odpak (PT (Calkowita i)) = i
  odpak _ = undefined

instance Pakowalny (Complex Double) where
  pak i = PT (Zespolona i)
  odpak (PT (Zespolona i)) = i
  odpak _ = undefined

instance Pakowalny String where
  pak s = (PT (Napis s))
  odpak (PT (Napis s)) = s
  odpak _ = undefined

instance Pakowalny Bool where
  pak i = PT (Logiczna i)
  odpak (PT (Logiczna i)) = i
  odpak _ = undefined

instance Pakowalny TypQCL where
  pak = id
  odpak = id

instance Pakowalny (ZlozonyTypQCL a) where
  pak = undefined
  odpak = undefined
{- Koniec fragmentu napisanego przez P. Patryka Czarnika -}

instance Num TypQCL where
  negate (PT (Calkowita a)) = pak $ negate a
  negate (PT (Zespolona a)) = pak $ negate a
  negate (PT (Logiczna a)) = pak $ not a
  negate _ = undefined

  (+) (PT (Calkowita a)) (PT (Calkowita b)) = pak $ a + b
  (+) (PT (Zespolona a)) (PT (Zespolona b)) = pak $ a * b
  (+) (PT (Napis a)) (PT (Napis b)) = pak $ a ++ b
  (+) _ _ = undefined

  abs (PT (Calkowita a)) = pak $ abs a
  abs (PT (Zespolona a)) = pak $ abs a
  abs _ = undefined

  (*) (PT (Calkowita a)) (PT (Calkowita b)) = pak $ a * b
  (*) (PT (Zespolona a)) (PT (Zespolona b)) = pak $ a * b
  (*) _ _ = undefined

  signum (PT (Zespolona a)) = pak $ signum a
  signum (PT (Calkowita a)) = pak $ signum a
  signum _ = undefined

  fromInteger a = pak a

instance Bits TypQCL where
  (.&.) (PT (Calkowita a)) (PT (Calkowita b)) = pak $ (.&.) a  b
  (.&.) (PT (Logiczna a))  (PT (Logiczna b)) = pak $ (.&.) a  b
  (.&.) _ _ = undefined

  (.|.) (PT (Calkowita a)) (PT (Calkowita b)) = pak $ (.|.) a  b
  (.|.) (PT (Logiczna a))  (PT (Logiczna b)) = pak $ (.|.) a  b
  (.|.) _ _ = undefined

  (complement) (PT (Calkowita a)) = pak $ (complement) a
  (complement) (PT (Logiczna a)) = pak $ (complement) a
  (complement) _ = undefined

  shift (PT (Logiczna a)) b = pak $ shift a b
  shift (PT (Calkowita a)) b = pak $ shift a b
  shift _ _ = undefined

  rotate (PT (Calkowita a)) b = pak $ rotate a b
  rotate (PT (Logiczna a)) b = pak $ rotate a b
  rotate _ _ = undefined

  bitSizeMaybe (PT (Calkowita a)) = bitSizeMaybe a
  bitSizeMaybe (PT (Logiczna a)) = bitSizeMaybe a
  bitSizeMaybe _ = Nothing

  isSigned (PT (Calkowita a)) = isSigned a
  isSigned (PT (Logiczna a)) = isSigned a
  isSigned _ = undefined

  xor (PT (Calkowita a)) (PT (Calkowita b)) = pak $ xor a b
  xor (PT (Logiczna a)) (PT (Logiczna b)) = pak $ xor a b
  xor _ _ = undefined

  popCount (PT (Calkowita a)) = popCount a
  popCount (PT (Logiczna a)) = popCount a
  popCount _ = undefined

  testBit (PT (Calkowita a)) = testBit a
  testBit (PT (Logiczna a)) = testBit a
  testBit _ = undefined

  bitSize (PT (Calkowita a)) =
    case bitSizeMaybe a of
     Just x -> x
     Nothing -> undefined
  bitSize (PT (Logiczna a)) =
    case bitSizeMaybe a of
     Just x -> x
     Nothing -> undefined
  bitSize _ = undefined

  bit _ = undefined
