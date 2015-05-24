module Stan where
import qualified Srodowisko as Sr
import Typy
import Absgramatyka
import Data.Map as Map

data Stan = Stan { stan :: Map Loc TypQCL,
                   podprogramy :: Map Loc Podprogram,
                   wolna_lokacja :: Loc,
                   wynik_funkcji :: TypQCL
                 } deriving (Show)

stanZero :: Stan
stanZero = Stan {
                  stan = Map.empty,
                  wolna_lokacja = 0,
                  podprogramy = Map.empty,
                  wynik_funkcji = PT Nic
                }

data Podprogram = Podpr { arg_ident :: [Ident],
                          srod :: Sr.Srodowisko Loc,
                          cialo :: Body
                        } deriving(Show, Ord, Eq)

zajmij_wolne_lok :: [Loc] -> Stan -> Stan
zajmij_wolne_lok lokacje st = Stan { stan = stan st,
                                     wolna_lokacja = max
                                                     (wolna_lokacja st)
                                                     (1 + (maximum lokacje)),
                                     podprogramy = podprogramy st,
                                     wynik_funkcji = wynik_funkcji st
                                   }

daj_wolne_lok :: Integer -> Stan -> [Loc]
daj_wolne_lok ile st = [(wolna_lokacja st) .. (wolna_lokacja st) + ile - 1]

dodaj_wartosci :: [Loc] -> [TypQCL] -> Stan -> Stan
dodaj_wartosci l t s = Stan { stan = union (fromList $ zip l t) (stan s),
                              wolna_lokacja = wolna_lokacja s,
                              podprogramy = podprogramy s,
                              wynik_funkcji = wynik_funkcji s
                            }
dodaj_wartosc_kom :: Komorka -> TypQCL -> Stan -> Stan
dodaj_wartosc_kom (KomZm x) t s = Stan { stan = insert x t (stan s),
                                         wolna_lokacja = wolna_lokacja s,
                                         podprogramy = podprogramy s,
                                         wynik_funkcji = wynik_funkcji s
                                       }

dodaj_wartosc_kom _ _ _ = undefined

dodaj_podprogram :: Loc -> Podprogram -> Stan -> Stan
dodaj_podprogram l f s = Stan { stan = stan s,
                                wolna_lokacja = wolna_lokacja s,
                                podprogramy = insert l f (podprogramy s),
                                wynik_funkcji = wynik_funkcji s
                              }

daj_wartosc :: Loc -> Stan -> Maybe TypQCL
daj_wartosc l s = Map.lookup l (stan s)

daj_wynik_funkcji :: Stan -> TypQCL
daj_wynik_funkcji = wynik_funkcji

usun_wynik_funkcji :: Stan -> Stan
usun_wynik_funkcji s = Stan { stan = stan s,
                              podprogramy = podprogramy s,
                              wolna_lokacja = wolna_lokacja s,
                              wynik_funkcji = PT Nic
                            }

wloz_wynik_funkcji :: TypQCL -> Stan -> Stan
wloz_wynik_funkcji wyn st = Stan { stan = stan st,
                                   podprogramy = podprogramy st,
                                   wolna_lokacja = wolna_lokacja st,
                                   wynik_funkcji = wyn
                                 }

daj_podprogram :: Loc -> Stan -> Maybe Podprogram
daj_podprogram l s = Map.lookup l (podprogramy s)
