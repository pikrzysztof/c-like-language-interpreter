module TypyDlaSprawdzaczki where
import qualified Absgramatyka as A

data OgolnyTypQCL a = PT ProstyTypQCL
                    | ZT (ZlozonyTypQCL a)
                    deriving (Eq, Ord, Read, Show)

data ProstyTypQCL = Napis
                  | Calkowita
                  | Logiczna
                  | Zespolona
                  | Nic
                  deriving (Eq, Ord, Read, Show)

data ZlozonyTypQCL a = Tablica a
                     | Wektor a
                     | Macierz a
                     | Tensor a
                     deriving (Eq, Ord, Read, Show)

data Podprogram = Fn TypQCL [TypQCL]
                | Proc [TypQCL]
                deriving (Eq, Ord, Show)

data TypQCL = Dane (OgolnyTypQCL ProstyTypQCL)
            | Podpr Podprogram
            deriving (Eq, Ord, Show)

do_typu_prostego :: A.Type -> ProstyTypQCL
do_typu_prostego (A.SimpleType x) =
  case x of
   A.TString -> Napis
   A.TBoolean -> Logiczna
   A.TInt -> Calkowita
   A.TComplex -> Zespolona
   _ -> undefined
do_typu_prostego _ = undefined

do_typu_prostego_z_ST :: A.ST -> ProstyTypQCL
do_typu_prostego_z_ST x = do_typu_prostego (A.SimpleType x)

do_typu :: A.Type -> TypQCL
do_typu t =
  case t of
   A.Vector x -> Dane $ ZT (Tablica $ do_typu_prostego_z_ST x)
   A.Matrix x -> Dane $ ZT (Macierz $ do_typu_prostego_z_ST x)
   A.Tensor x _ -> Dane $ ZT (Tensor $ do_typu_prostego_z_ST x)
   _ -> Dane $ PT $ do_typu_prostego t

klasyczny_typ :: A.Type -> Bool
klasyczny_typ t =
  case t of
   A.SimpleType st ->
     case st of
      A.TString -> True
      A.TBoolean -> True
      A.TInt -> True
      A.TReal -> True
      A.TComplex -> True
      A.TQureg -> False
      A.TQuvoid -> False
      A.TQuConst -> False
      A.TQuscratch -> False
      A.TQucond -> False
   A.Vector st -> klasyczny_typ (A.SimpleType st)
   A.Matrix st -> klasyczny_typ (A.SimpleType st)
   A.Tensor st _ -> klasyczny_typ (A.SimpleType st)
