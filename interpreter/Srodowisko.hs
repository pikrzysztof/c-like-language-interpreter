module Srodowisko where
import Absgramatyka
import Typy
import Data.Map as Map

data Srodowisko = Srod { srod :: Map Ident Loc
                       } deriving (Show)

srodowiskoZero :: Srodowisko
srodowiskoZero = Srod { srod = Map.empty
                      }

zmien_srodowisko :: Ident -> Loc -> Srodowisko -> Srodowisko
zmien_srodowisko i l s = Srod { srod = insert i l (srod s)
                              }

daj_lokacje :: Ident -> Srodowisko -> Maybe Loc
daj_lokacje id s = Map.lookup id (srod s)
