module Stan where
import Srodowisko
import Typy
import Data.Complex as Complex
import Data.Void
import Absgramatyka
import Data.Map as Map

data Stan = Stan { stan :: Map Loc (TypQCL ProstyTypQCL),
                   funkcje :: Map Loc Funkcja,
                   wolna_lokacja :: Loc
                 } deriving (Show)

stanZero :: Stan
stanZero = Stan { stan = Map.empty,
                  wolna_lokacja = 0,
                  funkcje = Map.empty
                }

data Funkcja = Fn { srod :: Srodowisko,
                    argumenty :: [ArgDef],
                    cialo :: Body
                  } deriving (Show)

zwieksz_wolna_lok :: Stan -> Stan
zwieksz_wolna_lok st = Stan { stan = stan st,
                              wolna_lokacja = (wolna_lokacja st) + 1,
                              funkcje = funkcje st
                            }

daj_wolna_lok :: Stan -> Loc
daj_wolna_lok st = wolna_lokacja st

dodaj_wartosc :: Loc -> (TypQCL ProstyTypQCL) -> Stan -> Stan
dodaj_wartosc l t s = Stan { stan = insert l t (stan s),
                             wolna_lokacja = wolna_lokacja s,
                             funkcje = funkcje s
                           }

dodaj_funkcje :: Loc -> Funkcja -> Stan -> Stan
dodaj_funkcje l f s = Stan { stan = stan s,
                             wolna_lokacja = wolna_lokacja s,
                             funkcje = insert l f (funkcje s)
                           }

daj_wartosc :: Loc -> Stan -> Maybe (TypQCL ProstyTypQCL)
daj_wartosc l s = Map.lookup l (stan s)
