module Stan where
import qualified Srodowisko as Sr
import Typy
import Absgramatyka
import Data.Map as Map
import System.Random


data StanMaszyny = SM { losowe :: [Double],
                        kubity :: [Ket Integer]
                      } deriving (Ord, Eq)

data Stan = Stan { stan_klasyczny :: Map Loc TypQCL,
                   podprogramy :: Map Loc Podprogram,
                   wolna_lokacja :: Loc,
                   wynik_funkcji :: TypQCL,
                   stan_kwantowy :: StanMaszyny
                 } deriving (Show)

stanZero :: Stan
stanZero = Stan {
                  stan_klasyczny = Map.empty,
                  wolna_lokacja = 0,
                  podprogramy = Map.empty,
                  wynik_funkcji = PT Nic,
                  stan_kwantowy = SM {
                    losowe = randomRs (0 :: Double, 1 :: Double) (mkStdGen 9),
                    kubity = []
                    }
                }

data Podprogram = Podpr { arg_ident :: [Ident],
                          srod :: Sr.Srodowisko Loc,
                          cialo :: Body
                        } deriving(Show, Ord, Eq)


zajmij_wolne_lok :: [Loc] -> Stan -> Stan
zajmij_wolne_lok lokacje st = st { wolna_lokacja =
                                      max
                                      (wolna_lokacja st)
                                      (1 + maximum lokacje)
                                 }
-- daje posortowana niemalejaco liste
daj_wolne_lok :: Integer -> Stan -> [Loc]
daj_wolne_lok ile st = [(wolna_lokacja st) .. (wolna_lokacja st) + ile - 1]

dodaj_wartosci :: [Loc] -> [TypQCL] -> Stan -> Stan
dodaj_wartosci l t s = s { stan_klasyczny = union
                                             (fromList $ zip l t)
                                             (stan_klasyczny s)
                          }

dodaj_wartosc_kom :: Komorka -> TypQCL -> Stan -> Stan
dodaj_wartosc_kom (KomZm x) t s = s { stan_klasyczny =
                                            insert x t (stan_klasyczny s)
                                       }

dodaj_wartosc_kom _ _ _ = undefined

dodaj_podprogram :: Loc -> Podprogram -> Stan -> Stan
dodaj_podprogram l f s = s { podprogramy = insert l f (podprogramy s)
                           }

daj_wartosc :: Loc -> Stan -> Maybe TypQCL
daj_wartosc l s = Map.lookup l (stan_klasyczny s)

daj_wynik_funkcji :: Stan -> TypQCL
daj_wynik_funkcji = wynik_funkcji

usun_wynik_funkcji :: Stan -> Stan
usun_wynik_funkcji s = s { wynik_funkcji = PT Nic
                         }

wloz_wynik_funkcji :: TypQCL -> Stan -> Stan
wloz_wynik_funkcji wyn st = st { wynik_funkcji = wyn
                               }

daj_podprogram :: Loc -> Stan -> Maybe Podprogram
daj_podprogram l s = Map.lookup l (podprogramy s)

-- zaklada, ze lista jest posortowana niemalejaco.
usun_lokacje_i_nowsze :: [Loc] -> Stan -> Stan
usun_lokacje_i_nowsze [] st = st
usun_lokacje_i_nowsze (l:_) st = st { stan_klasyczny =
                                         fst $ Map.split l $ stan_klasyczny st,
                                      podprogramy =
                                        fst $ Map.split l $ podprogramy st
                                    }



instance Show StanMaszyny where
  show sm = "SM { losowe = "
            ++ (show $ head $ losowe sm)
            ++ " kubity = "
            ++ (show $ kubity sm)
            ++ "}"
