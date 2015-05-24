module SprawdzaczTypow (sprawdz_typy) where
import System.Exit ( exitFailure )
import Control.Monad.Except
import Control.Monad.Reader
import qualified Srodowisko as Sr
import TypyDlaSprawdzaczki
import Absgramatyka
import Rozmaitosci

  -- Bool oznacza, czy to stala (True) czy zmienna (False)
type Sprawdzacz a =
  ExceptT String (ReaderT (Sr.Srodowisko (TypQCL, Bool)) IO) a

sprawdz_typy :: Program -> Sprawdzacz ()
sprawdz_typy (QCLProgram defy stmt) = do {
  env <- lancuch_reader przetraw_definicje defy;
  local (const env) (mapM_ sprawdz_typ_stmt stmt);
  } `catchError` (obsluz_wyjatek)

obsluz_wyjatek :: String -> Sprawdzacz ()
obsluz_wyjatek blad = do
  lift $ lift $ putStrLn $ "Nie zgadza sie co do typow. " ++ blad;
  _ <- lift $ lift $ exitFailure
  return ()

przetraw_definicje :: Def -> Sprawdzacz (Sr.Srodowisko (TypQCL, Bool))
przetraw_definicje def = do
  case def of
   VarDefDef x -> do
     case x of
      JustVarDef t i -> do
        z <- ask
        return $ Sr.zmien_srodowisko [i] [(do_typu t, False)] z
      VarDefAss t i w -> do {
        env <- przetraw_definicje (VarDefDef (JustVarDef t i));
        (y, _) <- sprawdz_typ_expr w;
        if ((do_typu t) == y) then
          (return env)
        else
          (throwError $ "Przypisujemy na zmienna typu " ++
           (show $ do_typu t) ++ " wartosc typu " ++ (show y));
        }
      _ ->
        undefined
   DefConstDef d -> do
     case d of
      ClassicalConstDef i e -> do
        z <- ask
        (y, _) <- sprawdz_typ_expr e
        return $ Sr.zmien_srodowisko [i] [(y, True)] z
      _ ->
        undefined
   FunDef typ ident argumenty cialo -> do
     srod <- ask
     let
       -- srodowisko bez zadnych zmiennych
       srod_bez_zmiennych =
         Sr.wytnij_wszystkie_wartosci (\x -> case x of
                                              (Podpr (Fn _ _), _) -> True
                                              _ -> False
                                      )
         srod
       -- lista (Typ, identyfikator)
       lista_param = [(do_typu typ_param, identyf)
                     | (JustArgDef typ_param identyf) <- argumenty]
       fn = (ident, (Podpr $ Fn (do_typu typ) (map fst lista_param)))
       -- Srodowisko
       srod_po_funkcji = Sr.zmien_srodowisko
                         [fst fn]
                         [(snd fn, False)]
                         srod
       srod_funkcji = Sr.zmien_srodowisko
                      ((map snd lista_param) ++ [fst fn])
                      ([(param, False) | (param, _) <- lista_param] ++ [(snd fn, True)])
                      srod_bez_zmiennych
       in do
          _ <- local (const srod_funkcji) (sprawdz_funkcje (do_typu typ) cialo)
          return srod_po_funkcji
   _ -> undefined

sprawdz_typ_stmt :: Stmt -> Sprawdzacz (TypQCL, Bool)
sprawdz_typ_stmt stmt = do
  case stmt of
   ReturnExpr e -> do
     sprawdz_typ_expr e
   List ident -> do
     mapM_ sprawdz_typ_expr (map Variable ident)
     return undefined
   Expression e -> do
     sprawdz_typ_expr e
   Assignment e0 e1 -> do {
     x <- sprawdz_typ_w_expr e0;
     (y, _) <- sprawdz_typ_expr e1;
     if ((fst x) == y) && (not $ snd x) then
       (return (fst x, False))
     else
       throwError $ "Nie pasuje typ w " ++ (show stmt);
     }
   ForStepLoop ident e0 e1 e2 (JustBlock b) -> do
     _ <- sprawdz_typ_expr (EAdd e1 e2)
     _ <- mapM_ sprawdz_typ_stmt b
     sprawdz_typ_stmt (Assignment (Variable ident) e0)
   ForLoop ident e0 e1 (JustBlock stmtbl) -> do
     _ <- sprawdz_typ_stmt (Assignment (Variable ident) e0)
     x <- sprawdz_typ_expr (EAdd e0 e1)
     mapM_ sprawdz_typ_stmt stmtbl
     return x
   WhileLoop e0 (JustBlock stmtbl) -> do {
     x <- sprawdz_typ_expr e0;
     _ <- mapM_ sprawdz_typ_stmt stmtbl;
     if (fst x) == (Dane $ PT Logiczna) then
        (return x)
     else
        (throwError $ "Nie pasuje typ w " ++ (show stmt) ++
         " spodziewalem sie wartosci logicznej w warunku petli");
     }
   ConditionalBranch e (JustBlock b) -> do {
     bool <- sprawdz_typ_expr e;
     _ <- mapM_ sprawdz_typ_stmt b;
     if (fst bool) == (Dane $ PT Logiczna) then
       (return bool)
     else
       (throwError $ "Nie pasuje typ w " ++ (show stmt) ++
        " spodziewalem sie wartosci logicznej w warunku petli");
     }
   ConditionalBranchElse e b0 b1 -> do {
     _ <- sprawdz_typ_stmt (WhileLoop e b0);
     sprawdz_typ_stmt (WhileLoop e b1);
     }
   Print expr -> do
     mapM_ sprawdz_typ_expr expr
     return undefined
   Exit expr -> do {
     x <- sprawdz_typ_expr expr;
     if (fst x) == (Dane $ PT Calkowita) then
        (return x)
     else
       (throwError $ "Nie pasuje typ w " ++ (show stmt) ++
        "spodziewalem sie liczby.");
     }
   Semicolon -> do
     return undefined
   _ -> do
     return undefined


sprawdz_typ_expr :: Expr -> Sprawdzacz (TypQCL, Bool)
sprawdz_typ_expr e = do
  case e of
   EConst c -> do
     case c of
      CJustConst _ -> return (Dane $ PT Calkowita, True)
      CConstComplexPair _ _ -> return (Dane $ PT Zespolona, True)
      CBoolTrue -> return (Dane $ PT Logiczna, True)
      CBoolFalse -> return (Dane $ PT Logiczna, True)
      CString _ -> return (Dane $ PT Napis, True)
   EFCall ident argumenty -> do
     x <- ask
     arg <- mapM sprawdz_typ_expr argumenty
     fn_ident <- asks (Sr.daj_lokacje ident)
     lift $ lift $ putStrLn (show x)
     case fn_ident of
      Just (Podpr (Fn a b), _) -> do {
        if (map fst arg) == b then
          (return (a, True))
        else
          (throwError $ "Nie zgadza się typ argumentu w wyrażeniu " ++ (show e) ++ " to jest " ++ (show fn_ident));
        }
      _ -> throwError $
           "Nieprawidłowy identyfikator wołanej funkcji w wyrażeniu " ++
           (show e)
   ETableElement _ _ -> undefined
   EMatrixElement _ _ _ -> undefined
   EListaOdDo _ _ _ -> undefined
   ECalkowitaElementowListy _ _ _ -> undefined
   ETrzecieListy _ _ _ -> undefined
   EListyBez _ _ _ -> undefined
   EStringConcat _ _ -> undefined
   EMod _ _ -> undefined
   ESize _ -> undefined
   EEq e1 e2 -> do {
     (v1, _) <- sprawdz_typ_expr e1;
     (v2, _) <- sprawdz_typ_expr e2;
     if v1 == v2 then
       (return (Dane $ PT Logiczna, True))
     else
       (throwError $ "Wyrazenie " ++ (show e) ++ " jest niepoprawne typowo, " ++
       "to co jest po lewej nie moze zostac porownane z tym po prawej.");
     }
   ENeq e1 e2 -> sprawdz_typ_expr (EEq e1 e2)
                 `catchError` (
     rzuc_blad $ "Wyrazenie " ++ (show e) ++ "jest niepoprawne typowo. " ++
     "To co jest po lewej jest nieporownywalne z wyrazeniem po prawej stronie.")
   ELe e1 e2 -> sprawdz_typ_expr (EEq e1 e2)
                `catchError` (
     rzuc_blad $ "Wyrazenie " ++ (show e) ++ "jest niepoprawne typowo. " ++
     "To co jest po lewej jest nieporownywalne z wyrazeniem po prawej stronie.")
   ELEq e1 e2 -> sprawdz_typ_expr (EEq e1 e2)
                 `catchError` (
     rzuc_blad $ "Wyrazenie " ++ (show e) ++ "jest niepoprawne typowo. " ++
     "To co jest po lewej jest nieporownywalne z wyrazeniem po prawej stronie.")
   EGr e1 e2 -> sprawdz_typ_expr (EEq e1 e2)
                `catchError` (
     rzuc_blad $ "Wyrazenie " ++ (show e) ++ "jest niepoprawne typowo. " ++
     "To co jest po lewej jest nieporownywalne z wyrazeniem po prawej stronie.")
   EGrEq e1 e2 -> sprawdz_typ_expr (EEq e1 e2)
                  `catchError` (
     rzuc_blad $ "Wyrazenie " ++ (show e) ++ "jest niepoprawne typowo. " ++
     "To co jest po lewej jest nieporownywalne z wyrazeniem po prawej stronie.")
   EOr e1 e2 -> do {
     (x, _) <- sprawdz_typ_expr (EEq e1 e2);
     if x == (Dane $ PT Logiczna) then
        (return (x, True))
     else
        (throwError $ "Wyrazenie " ++ (show e) ++ " jest niepoprawne typowo.");
     }
   EAnd e1 e2 -> sprawdz_typ_expr (EOr e1 e2)
                 `catchError` (
     rzuc_blad $ "Wyrazenie " ++ (show e) ++ "jest niepoprawne typowo. ")
   EXor e1 e2 -> sprawdz_typ_expr (EOr e1 e2)
                 `catchError` (
     rzuc_blad $ "Wyrazenie " ++ (show e) ++ "jest niepoprawne typowo. ")
   ENot e0 -> do {
     (x, _) <- sprawdz_typ_expr e0;
     if x == (Dane $ PT Logiczna) then
       (return (x, True))
     else
       (throwError $ (show e) ++ "to nie jest wartosc logiczna nie mozna " ++
        "jej zanegowac.");
     }
   EAdd e0 e1 -> do {
     (x, _) <- sprawdz_typ_expr e0;
     (y, _) <- sprawdz_typ_expr e1;
     if (x == y) && ((x == (Dane $ PT Calkowita))
                     || x == (Dane $ PT Zespolona)) then
       (return (x, True))
     else
       (throwError $ "nie mozna dodac do siebie " ++ (show e));
     }
   ESubtract e0 e1 -> sprawdz_typ_expr (EAdd e0 e1)
                      `catchError` (rzuc_blad $ "Nie mozna wykonac odejmowania " ++ (show e))
   ETimes e0 e1 -> sprawdz_typ_expr (EAdd e0 e1)
                   `catchError` (rzuc_blad $ "Nie mozna wykonac mnozenia " ++ (show e))
   EDiv e0 e1 -> sprawdz_typ_expr (EAdd e0 e1)
                 `catchError` (rzuc_blad $ "Nie mozna wykonac dzielenia " ++ (show e))
   EPow e0 e1 -> sprawdz_typ_expr (ETimes e0 e1)
                 `catchError` (rzuc_blad $ "Nie mozna wykonac potegowania " ++ (show e))
   EUnaryMinus e0 -> sprawdz_typ_expr (EAdd e0 e0)
                     `catchError` (rzuc_blad $ "Wyrazenie " ++ (show e) ++
                                   " nie ma wartosci przeciwnej.")
   Variable i -> do
     x <- asks $ Sr.daj_lokacje i
     case x of
      Nothing -> throwError $ "Zmienna " ++ (show i) ++
                 " nie zostala zadeklarowana."
      Just z -> return z

-- w od write, czyli czy do typu mozna zapisac
sprawdz_typ_w_expr :: Expr -> Sprawdzacz (TypQCL, Bool)
sprawdz_typ_w_expr e = do
  case e of
   Variable ident -> do
     mozetyp <- asks $ Sr.daj_lokacje ident
     case mozetyp of
      Nothing -> throwError $ (show e) ++ " nie zostalo zadeklarowane!"
      Just x -> return x
   _ -> return undefined

rzuc_blad :: String -> a -> Sprawdzacz (TypQCL, Bool)
rzuc_blad a _ = do
  _ <- throwError a
  return undefined

mozna_wolac_z_funkcji :: Stmt -> Bool
mozna_wolac_z_funkcji stmt =
  case stmt of
   UnitaryOpInvCall _ _ -> False
   FanoutSugar _ _ _ -> False
   InputExpr _ _ -> False
   InputNoExpr _ -> False
   Print _ -> False
   Exit _ -> False
   MeasureIdent _ _ -> False
   MeasureNoIdent _ -> False
   Reset -> False
   LoadExpr _ -> False
   LoadNoExpr -> False
   Shell -> False
   SetExpr _ _ -> False
   _ -> True

mozna_definiowac_z_funkcji :: ConstOrVar -> Bool
mozna_definiowac_z_funkcji x =
  case x of
   ConstDefListItem y ->
     case y of
      ClassicalConstDef _ _-> True
      _ -> False
   VarDefListItem z ->
     case z of
      JustVarDef t _ -> klasyczny_typ t
      VarDefAss t _ _ -> klasyczny_typ t
      VarDefTable t _ _ -> klasyczny_typ t

ma_return :: [Stmt] -> Bool
ma_return [] = False
ma_return (stmt:stmty) =
  case stmt of
   ReturnExpr _ -> True
   UntilLoop (JustBlock b) _ -> ma_return b
   ConditionalBranchElse _ (JustBlock b1) (JustBlock b2) ->
     (ma_return b1) && (ma_return b2)
   _ -> ma_return stmty

sprawdz_funkcje :: TypQCL -> Body -> Sprawdzacz ()
sprawdz_funkcje ret_typ (JustBody definicje stmt) = do {
  if (any not (map mozna_wolac_z_funkcji stmt)) ||
     (any not (map mozna_definiowac_z_funkcji definicje)) then
    (throwError $ "Nie robić w funkcji rzeczy, które bazują na stanie programu"
    ++ " bądź go zmieniają.")
  else if (not $ ma_return stmt) then
      (throwError "Nie jest zapewniony return w funkcji.")
    else do {
      srod_ostateczne <- lancuch_reader przetraw_definicje
                       (map odpakuj_ConstOrVar definicje);
      local (const srod_ostateczne)
      (mapM_ (sprawdz_typ_stmt_funkcji ret_typ) stmt);
      }
  } `catchError` (obsluz_wyjatek)

sprawdz_typ_stmt_funkcji :: TypQCL -> Stmt -> Sprawdzacz ()
sprawdz_typ_stmt_funkcji typ stmt = do {
  let spr = (sprawdz_typ_stmt_funkcji typ) in
   case stmt of
    ReturnExpr e -> do {
      (ret, _) <- sprawdz_typ_expr e;
      if (ret == typ) then
        (return ())
      else
        (throwError $ "Nie zgadza się typ returna w funkcji!");
      }
    ForLoop i e0 e1 (JustBlock b) -> do
      _ <- sprawdz_typ_stmt (ForLoop i e0 e1 (JustBlock []))
      mapM_ spr b
    ForStepLoop i e0 e1 e2 (JustBlock b) -> do
      _ <- sprawdz_typ_stmt (ForStepLoop i e0 e1 e2 (JustBlock []))
      mapM_ spr b
    WhileLoop e (JustBlock b) -> do
      _ <- sprawdz_typ_stmt (WhileLoop e (JustBlock []))
      mapM_ spr b
    UntilLoop (JustBlock b) e -> do
      _ <- sprawdz_typ_stmt (UntilLoop (JustBlock []) e)
      mapM_ spr b
    ConditionalBranch e (JustBlock b) -> do
      _ <- sprawdz_typ_stmt (ConditionalBranch e (JustBlock []))
      mapM_ spr b
    ConditionalBranchElse e (JustBlock b0) (JustBlock b1) -> do
      _ <- sprawdz_typ_stmt (ConditionalBranchElse e (JustBlock []) (JustBlock []))
      mapM_ spr (b0 ++ b1)
    jak_nie -> do
      _ <- sprawdz_typ_stmt jak_nie
      return ()
  } `catchError` (obsluz_wyjatek . (const $ "Nie zgadza sie typ w " ++ (show stmt)))
