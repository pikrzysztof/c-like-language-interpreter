module Rozmaitosci where
import Absgramatyka
import Control.Monad.Reader


lancuch_reader :: MonadReader m b =>  (a -> b m) -> [a] -> b m
lancuch_reader _ [] = do
  ask

lancuch_reader f (x:xy) = do
  tmp <- f x
  local (const $ tmp) (lancuch_reader f xy)

odpakuj_ConstOrVar :: ConstOrVar -> Def
odpakuj_ConstOrVar x =
  case x of
   ConstDefListItem cd -> DefConstDef cd
   VarDefListItem vd -> VarDefDef vd
