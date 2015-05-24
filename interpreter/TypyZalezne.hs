module TypyZalezne where

import Typy
import qualified Srodowisko as Sr
import qualified Stan as St

type Przetwarzacz a = PrzetwarzaczOgolny (Sr.Srodowisko Loc) (St.Stan) a
