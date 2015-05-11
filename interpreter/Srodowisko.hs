module Srodowisko where
import Absgramatyka
import Typy
import Data.Map as Map

data Srodowisko a = Srod { srod :: Map Ident a
                         } deriving (Show)

srodowiskoZero :: Srodowisko a
srodowiskoZero = Srod { srod = Map.empty
                      }

zmien_srodowisko :: Ident -> a -> Srodowisko a -> Srodowisko a
zmien_srodowisko i l s = Srod { srod = insert i l (srod s)
                              }

daj_lokacje :: Ident -> Srodowisko a -> Maybe a
daj_lokacje id s = Map.lookup id (srod s)
