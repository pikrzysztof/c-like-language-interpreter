module Srodowisko where
import Absgramatyka
import Data.Map as Map

data Srodowisko a = Srod { srod :: Map Ident a
                         } deriving (Show, Eq, Ord)

srodowiskoZero :: Srodowisko a
srodowiskoZero = Srod { srod = Map.empty
                      }

zmien_srodowisko :: [Ident] -> [a] -> Srodowisko a -> Srodowisko a
zmien_srodowisko i l s = Srod { srod = Map.union (Map.fromList $ zip i l)
                                       (srod s)
                              }

daj_lokacje :: Ident -> Srodowisko a -> Maybe a
daj_lokacje ident s = Map.lookup ident (srod s)
