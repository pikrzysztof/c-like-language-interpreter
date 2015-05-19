module SprawdzaczTypow (sprawdz_typy) where
import System.Exit ( exitFailure )
import Control.Monad.Except
import Control.Monad.Reader
import qualified Srodowisko as Sr
import qualified TypyDlaSprawdzaczki as TDS
import Absgramatyka

  -- Bool oznacza, czy to stala (True) czy zmienna (False)
type Sprawdzacz a = ExceptT String (ReaderT (Sr.Srodowisko (TDS.TypQCL, Bool)) IO) a

sprawdz_typy :: Program -> Sprawdzacz ()
sprawdz_typy (QCLProgram (def:defy) stmt) = do {
  env <- przetraw_definicje def;
  local (const env) (sprawdz_typy (QCLProgram defy stmt));
  } `catchError` (obsluz_wyjatek_def def)

sprawdz_typy (QCLProgram [] stmt) = do {
  mapM_ sprawdz_typ_stmt stmt;
  } `catchError` obsluz_wyjatek

obsluz_wyjatek :: String -> Sprawdzacz ()
obsluz_wyjatek s = do
  lift $ lift $ putStrLn s
  _ <- lift $ lift $ exitFailure
  return ()

obsluz_wyjatek_def :: Def -> String -> Sprawdzacz ()
obsluz_wyjatek_def s _ = do
  lift $ lift $ putStrLn $ "Definicja " ++ (show s) ++
    " nie zgadza sie co do typow.";
  _ <- lift $ lift $ exitFailure
  return ()

przetraw_definicje :: Def -> Sprawdzacz (Sr.Srodowisko (TDS.TypQCL, Bool))
przetraw_definicje def = do
  case def of
   VarDefDef x -> do
     case x of
      JustVarDef t i -> do
        z <- ask
        return $ Sr.zmien_srodowisko [i] [(TDS.do_typu t, False)] z
      VarDefAss t i w -> do {
        env <- przetraw_definicje (VarDefDef (JustVarDef t i));
        (y, _) <- sprawdz_typ_expr w;
        if ((TDS.do_typu t) == y) then
          (return env)
        else
          (throwError $ "Przypisujemy na zmienna typu " ++ (show $ TDS.do_typu t) ++
           " wartosc typu " ++ (show y));
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
   _ -> undefined

sprawdz_typ_stmt :: Stmt -> Sprawdzacz (TDS.TypQCL, Bool)
sprawdz_typ_stmt stmt = do
  case stmt of
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
   ForStepLoop ident e0 e1 e2 b -> do
     _ <- sprawdz_typ_stmt (ForLoop ident e0 e1 b)
     sprawdz_typ_expr (EAdd e0 e2)
   ForLoop ident e0 e1 (JustBlock stmtbl) -> do
     _ <- sprawdz_typ_stmt (Assignment (Variable ident) e0)
     x <- sprawdz_typ_expr (EAdd e0 e1)
     mapM_ sprawdz_typ_stmt stmtbl
     return x
   WhileLoop e0 (JustBlock stmtbl) -> do {
     x <- sprawdz_typ_expr e0;
     _ <- mapM sprawdz_typ_stmt stmtbl;
     if (fst x) == (TDS.PT TDS.Logiczna) then
        (return x)
     else
        (throwError $ "Nie pasuje typ w " ++ (show stmt) ++
         " spodziewalem sie wartosci logicznej w warunku petli");
     }
   ConditionalBranch e b -> do
     sprawdz_typ_stmt (WhileLoop e b)
   ConditionalBranchElse e b0 b1 -> do {
     _ <- sprawdz_typ_stmt (WhileLoop e b0);
     sprawdz_typ_stmt (WhileLoop e b1);
     }
   Print expr -> do
     mapM_ sprawdz_typ_expr expr
     return undefined
   Exit expr -> do {
     x <- sprawdz_typ_expr expr;
     if (fst x) == (TDS.PT TDS.Calkowita) then
        (return x)
     else
       (throwError $ "Nie pasuje typ w " ++ (show stmt) ++
        "spodziewalem sie liczby.");
     }
   Semicolon -> do
     return undefined
   _ -> do
     return undefined


sprawdz_typ_expr :: Expr -> Sprawdzacz (TDS.TypQCL, Bool)
sprawdz_typ_expr e = do
  case e of
   EConst c -> do
     case c of
      CJustConst _ -> return (TDS.PT TDS.Calkowita, True)
      CConstComplexPair _ _ -> return (TDS.PT TDS.Zespolona, True)
      CBoolTrue -> return (TDS.PT TDS.Logiczna, True)
      CBoolFalse -> return (TDS.PT TDS.Logiczna, True)
      CString _ -> return (TDS.PT TDS.Napis, True)
   EFCall _ _ -> undefined
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
       (return (TDS.PT TDS.Logiczna, True))
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
     if x == (TDS.PT TDS.Logiczna) then
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
     if x == (TDS.PT TDS.Logiczna) then
       (return (x, True))
     else
       (throwError $ (show e) ++ "to nie jest wartosc logiczna nie mozna " ++
        "jej zanegowac.");
     }
   EAdd e0 e1 -> do {
     (x, _) <- sprawdz_typ_expr e0;
     (y, _) <- sprawdz_typ_expr e1;
     if (x == y) && ((x == (TDS.PT TDS.Calkowita))
                     || x == (TDS.PT TDS.Zespolona)) then
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

sprawdz_typ_w_expr :: Expr -> Sprawdzacz (TDS.TypQCL, Bool)
sprawdz_typ_w_expr e = do
  case e of
   Variable ident -> do
     mozetyp <- asks $ Sr.daj_lokacje ident
     case mozetyp of
      Nothing -> throwError $ (show e) ++ "nie zostalo zadeklarowane!"
      Just x -> return x
   _ -> return undefined

rzuc_blad :: String -> a -> Sprawdzacz (TDS.TypQCL, Bool)
rzuc_blad a _ = do
  _ <- throwError a
  return undefined
