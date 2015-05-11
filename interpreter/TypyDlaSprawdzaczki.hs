module TypyDlaSprawdzaczki where
import qualified Absgramatyka as A
data OgolnyTypQCL a = PT ProstyTypQCL
                    | ZT (ZlozonyTypQCL a)
                    deriving (Eq, Ord, Read, Show)

data ProstyTypQCL = Napis
                  | Liczba
                  | ZmiennaLogiczna
                  | ZmiennaZespolona
                  deriving (Eq, Ord, Read, Show)

data ZlozonyTypQCL a = Tablica a
                     | Wektor a
                     | Macierz a
                     | Tensor a
                       deriving (Eq, Ord, Read, Show)

type TypQCL = OgolnyTypQCL ProstyTypQCL

do_typu_prostego :: A.Type -> ProstyTypQCL
do_typu_prostego (A.SimpleType x) =
  case x of
   A.TString -> Napis
   A.TBoolean -> ZmiennaLogiczna
   A.TInt -> Liczba
   A.TComplex -> ZmiennaZespolona

do_typu_prostego_z_ST :: A.ST -> ProstyTypQCL
do_typu_prostego_z_ST x = do_typu_prostego (A.SimpleType x)

do_typu :: A.Type -> TypQCL
do_typu t =
  case t of
   A.Vector x -> ZT (Tablica $ do_typu_prostego_z_ST x)
   A.Matrix x -> ZT (Macierz $ do_typu_prostego_z_ST x)
   A.Tensor x _ -> ZT (Tensor $ do_typu_prostego_z_ST x)
   _ -> PT $ do_typu_prostego t
