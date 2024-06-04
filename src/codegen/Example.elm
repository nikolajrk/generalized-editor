module Example exposing (..)

import Conditionals exposing (..)
import DecomposeFun exposing (..)
import Elm
import Elm.Annotation as Type exposing (..)
import Gen.Decomposable
import Gen.Substitutable
import GetCursorPath exposing (..)
import Movement exposing (..)
import Parent exposing (..)
import Parser exposing (..)
import RawSyntaxP exposing (parseRawSyntax)
import Substitution exposing (..)
import Syntax exposing (..)
import ToCCtx exposing (..)
import ToCLess exposing (..)



-- exampleFiles : List Elm.File
-- exampleFiles =
--     [ Elm.file [ "Ops" ] <| getTypeDecls exampleAddOperators
--     , Elm.file [ "Ops_CLess" ] <| getTypeDecls <| addHoleOps <| exampleSyntax
--     , Elm.file [ "Ops_CCtx" ] <| getTypeDecls <| addCCtxOp <| addCCtxSort <| addCCtxOps <| addHoleOps <| exampleSyntax
--     , Elm.file [ "Ops_Wellformed" ] <|
--         getTypeDecls <|
--             addCursorSortAndOps <|
--                 addHoleOps <|
--                     exampleSyntax
--     ]
-- typeClassExample : List Elm.File
-- typeClassExample =
--     [ Elm.file [ "TypeClass" ] <|
--         [ Elm.declaration "myFun" <|
--             Elm.fn
--                 ( "myArg"
--                 , Just
--                     (Type.namedWith
--                         Gen.Substitutable.moduleName_
--                         "Substitutable"
--                         [ Type.var "a" ]
--                     )
--                 )
--                 (\arg -> arg)
--         , Elm.declaration "myFun2" <|
--             Elm.fn
--                 ( "myArg"
--                 , Just
--                     (Type.namedWith
--                         Gen.Decomposable.moduleName_
--                         "Decomposable"
--                         [ Type.named [] "E", Type.named [] "S", Type.named [] "S" ]
--                     )
--                 )
--                 (\arg -> Elm.val "\"Hello")
--         ]
--             ++ createBaseSyntaxSorts exampleSyntax
--     ]


exampleFiles : List Elm.File
exampleFiles =
    [ Elm.file [ "Main" ] <|
        createBaseSyntaxSorts
            (addCursorHoleOps <| exampleSyntax)
            ++ createCursorlessSyntaxSorts exampleSyntax
            ++ (fromCLessToCCtxSyntaxSorts <| createCursorlessSyntax exampleSyntax)
            ++ (fromCLessToWellFormedSorts <| createCursorlessSyntax exampleSyntax)
            ++ [ createBindType ]
            ++ [ createGetCursorPath <| addCursorHoleOps <| exampleSyntax ]
            ++ createToCLessFuns (addCursorHoleOps exampleSyntax)
            ++ createToCCtxFuns (addCursorHoleOps exampleSyntax)
            ++ createDecomposeFuns (addCursorHoleOps exampleSyntax)
            ++ [ createReplaceCCtxHoleFun
                    (addCursorHoleOps <| exampleSyntax)
                    (createCursorlessSyntax exampleSyntax)
                    (fromCLessToCCtxSyntax <| createCursorlessSyntax exampleSyntax)
               ]
            ++ [ createChildFun
                    (addCursorHoleOps <| exampleSyntax)
                    (createCursorlessSyntax exampleSyntax)
                    (fromCLessToCCtxSyntax <| createCursorlessSyntax exampleSyntax)
                    (fromCLessToWellFormedSyntax <| createCursorlessSyntax exampleSyntax)
               ]
            ++ [ createSubFun (fromCLessToWellFormedSyntax <| createCursorlessSyntax exampleSyntax)
               ]
            ++ createParentFuns
                (filterCLess <| createCursorlessSyntax exampleSyntax)
                (filterCctx <| fromCLessToCCtxSyntax <| createCursorlessSyntax exampleSyntax)
            ++ createEditorCondDecls (filterCLess <| createCursorlessSyntax exampleSyntax)
                (filterWellformed <| fromCLessToWellFormedSyntax <| createCursorlessSyntax exampleSyntax)

    -- ++ [createDecomposeFun <| addCursorHoleOps <| exampleSyntax]
    -- ++ [ createToCursorLessFun <| addCursorHoleOps <| exampleSyntax ]
    -- ++ [ decomposableInstance <| addCursorHoleOps <| exampleSyntax ]
    -- ++ convertableInstances (addCursorHoleOps exampleSyntax)
    ]


exampleSyntax : Syntax
exampleSyntax =
    case parseRawSyntax rawSyntax of
        Ok syntax ->
            fromRawSyntax syntax

        Err err ->
            Debug.todo "Error parsing syntax"


rawSyntax : String
rawSyntax =
    "p in Prog\ns in Stmt\nvd in VariableDecl\nfd in FunDecl\nt in Type\nid in Id\ne in Exp\nb in Block\nbi in BlockItem\nfa in Funarg\ncond in Conditional\n\np ::= fd # (fd)p # program\nb ::= bi # (bi)b # block\nbi ::= vd # (vd)bi # blockdecls | s # (s)bi # blockstmts | epsilon # ()bi # blockdone\nvd ::= t id \"=\" e; bi # (t,e,id.bi)vd # vardecl\nfd ::= t_1 id_1 \"(\" t_2 id_2 \")\" \"{\" b \"}\" # (t,id.fd,t,id.b)fd # fundecl1 | t_1 id_1 \"(\" t_2 id_2, t_3 id_3 \")\" \"{\" b \"}\" # (t,id.fd,t,t,id.id.b)fd # fundecl2 | epsilon # ()fd # fundecldone\ns ::= id \"=\" e \";\" # (id,e)s # assignment | id \"(\" fa \")\";\" # (id,fa)s # stmtfuncall | \"return \" e \";\" # (e)s # return | cond # (cond)s # conditional | s s # (s,s)s # compstmt\nfa ::= t id # (t,id)fa # funarg | t id, fa # (t,id,fa)fa # funargs\ncond ::= \"if (\" e \")\" \"{\" b_1 \"} else {\" b_2 \"}\" # (e,b,b)cond # ifelse\nt ::= \"int\" # ()t # tint | \"char\" # ()t # tchar | \"bool\" # ()t # tbool\ne ::= %int # ()e # int[Int] | %char # ()e # char[Char] | %bool # ()e # bool[Bool] | e_1 \"+\" e_2 # (e,e)e # plus | e_1 \"==\" e_2 # (e,e)e # equals | id \"(\" fa \")\" # (id,fa)e # expfuncall | id # (id)e # expident\nid ::= %string # ()id # ident[String]"


filterCctx : Syntax -> Syntax
filterCctx syntax =
    { synCats = List.filter (\x -> x.exp == "cctx") syntax.synCats
    , synCatOps = List.filter (\x -> x.synCat == "cctx") syntax.synCatOps
    }


filterWellformed : Syntax -> Syntax
filterWellformed syntax =
    { synCats = List.filter (\x -> x.exp == "wellformed") syntax.synCats
    , synCatOps = List.filter (\x -> x.synCat == "wellformed") syntax.synCatOps
    }


filterCLess : Syntax -> Syntax
filterCLess syntax =
    { synCats = List.filter (\x -> String.endsWith "_CLess" x.exp) syntax.synCats
    , synCatOps = List.filter (\x -> String.endsWith "_CLess" x.synCat) syntax.synCatOps
    }



-- samplegetCLessSortOfCCtxOp : String
-- samplegetCLessSortOfCCtxOp =
--     getCLessSortOfCCtxOp (createCursorlessSyntax exampleSyntax)
--         { term = "TODO"
--         , arity = [ ( [], "Bind E_CLess S_CLess" ) ]
--         , name = "program_CLess_cctx1"
--         , synCat = "Cctx"
--         , literal = Nothing
--         }
-- sampleOp : Elm.Declaration
-- sampleOp =
--     Elm.declaration "sampleOp" <|
--         Elm.val ""
-- exampleSynCats : List SynCat
-- exampleSynCats =
--     [ { exp = "p", set = "Prog" }
--     , { exp = "s", set = "Stmt" }
--     , { exp = "vd", set = "VariableDecl" }
--     , { exp = "fd", set = "FunDecl" }
--     , { exp = "t", set = "Type" }
--     , { exp = "id", set = "Id" }
--     , { exp = "e", set = "Exp" }
--     , { exp = "b", set = "Block" }
--     , { exp = "bi", set = "BlockItem" }
--     , { exp = "fa", set = "FunArg" }
--     , { exp = "cond", set = "Conditional" }
--     ]
-- exampleSynCatRules : List SynCatOps
-- exampleSynCatRules =
--     [ { ops =
--             [ { term = "fd"
--               , arity = [ ( [], "fd" ) ]
--               , name = "program"
--               , synCat = "p"
--               }
--             ]
--       , synCat = "p"
--       }
--     , { ops =
--             [ { term = "bi"
--               , arity = [ ( [], "bi" ) ]
--               , name = "block"
--               , synCat = "b"
--               }
--             ]
--       , synCat = "b"
--       }
--     , { ops =
--             [ { term = "vd"
--               , arity = []
--               , name = "blockdecls"
--               , synCat = "bi"
--               }
--             , { term = "s"
--               , arity = [ ( [], "s" ) ]
--               , name = "blockstmts"
--               , synCat = "bi"
--               }
--             , { term = ""
--               , arity = []
--               , name = "blockdone"
--               , synCat = "bi"
--               }
--             ]
--       , synCat = "bi"
--       }
--     , { ops =
--             [ { term = "todo"
--               , arity = [ ( [], "t" ), ( [], "e" ), ( [ "id" ], "bi" ) ]
--               , name = "vardecl"
--               , synCat = "vd"
--               }
--             ]
--       , synCat = "vd"
--       }
--     , { ops =
--             [ { term = "todo"
--               , arity = [ ( [], "t" ), ( [ "id" ], "fd" ), ( [], "t" ), ( [ "id" ], "b" ) ]
--               , name = "fundecl1"
--               , synCat = "fd"
--               }
--             , { term = "todo"
--               , arity = [ ( [], "t" ), ( [ "id" ], "fd" ), ( [], "t" ), ( [], "t" ), ( [ "id", "id" ], "b" ) ]
--               , name = "fundecl2"
--               , synCat = "fd"
--               }
--             ]
--       , synCat = "fd"
--       }
--     , { ops =
--             [ { term = "todo"
--               , arity = [ ( [], "id" ), ( [], "e" ) ]
--               , name = "assignment"
--               , synCat = "s"
--               }
--             , { term = "todo"
--               , arity = [ ( [], "id" ), ( [], "fa" ) ]
--               , name = "stmtfuncall"
--               , synCat = "s"
--               }
--             , { term = "todo"
--               , arity = [ ( [], "e" ) ]
--               , name = "return"
--               , synCat = "s"
--               }
--             , { term = "todo"
--               , arity = [ ( [], "cond" ) ]
--               , name = "conditional"
--               , synCat = "s"
--               }
--             , { term = "todo"
--               , arity = [ ( [], "s" ), ( [], "s" ) ]
--               , name = "compstmt"
--               , synCat = "s"
--               }
--             ]
--       , synCat = "s"
--       }
--     , { ops =
--             [ { term = "todo"
--               , arity = [ ( [], "t" ), ( [], "id" ) ]
--               , name = "funarg"
--               , synCat = "fa"
--               }
--             , { term = "todo"
--               , arity = [ ( [], "t" ), ( [], "id" ), ( [], "fa" ) ]
--               , name = "funargs"
--               , synCat = "fa"
--               }
--             ]
--       , synCat = "fa"
--       }
--     , { ops =
--             [ { term = "todo"
--               , arity = [ ( [], "e" ), ( [], "b" ), ( [], "b" ) ]
--               , name = "ifelse"
--               , synCat = "cond"
--               }
--             ]
--       , synCat = "cond"
--       }
--     , { ops =
--             [ { term = "todo"
--               , arity = []
--               , name = "tint"
--               , synCat = "t"
--               }
--             , { term = "todo"
--               , arity = []
--               , name = "tchar"
--               , synCat = "t"
--               }
--             , { term = "todo"
--               , arity = []
--               , name = "tbool"
--               , synCat = "t"
--               }
--             ]
--       , synCat = "t"
--       }
--     , { ops =
--             [ { term = "todo"
--               , arity = []
--               , name = "cint"
--               , synCat = "e"
--               }
--             , { term = "todo"
--               , arity = []
--               , name = "cchar"
--               , synCat = "e"
--               }
--             , { term = "todo"
--               , arity = []
--               , name = "cbool"
--               , synCat = "e"
--               }
--             , { term = "todo"
--               , arity = [ ( [], "e" ), ( [], "e" ) ]
--               , name = "plus"
--               , synCat = "e"
--               }
--             , { term = "todo"
--               , arity = [ ( [], "e" ), ( [], "e" ) ]
--               , name = "equals"
--               , synCat = "e"
--               }
--             , { term = "todo"
--               , arity = [ ( [], "id" ), ( [], "fa" ) ]
--               , name = "expfuncall"
--               , synCat = "e"
--               }
--             , { term = "todo"
--               , arity = [ ( [], "id" ) ]
--               , name = "expident"
--               , synCat = "e"
--               }
--             ]
--       , synCat = "e"
--       }
--     , { ops =
--             [ { term = "todo"
--               , arity = []
--               , name = "ident"
--               , synCat = "id"
--               , literal = Just "String"
--               }
--             ]
--       , synCat = "id"
--       }
--     ]
-- exampleSyntax : Syntax
-- exampleSyntax =
--     { synCats = exampleSynCats
--     , synCatOps = exampleSynCatRules
--     }
-- exampleAddOperators : Syntax
-- exampleAddOperators =
--     addCursorHoleOps exampleSyntax
-- -- Cursor stuff
-- {-| Well-formed sorts and operators
-- -}
-- type Wellformed
--     = Root_s_CLess S_CLess
--     | Root_e_CLess E_CLess
--     | Let_CLess_cursor1 E_CLess (Bind E_CLess S_CLess)
--     | Let_CLess_cursor2 E_CLess (Bind E_CLess S_CLess)
--     | Exp_CLess_cursor1 E_CLess
--     | Plus_CLess_cursor1 E_CLess E_CLess
--     | Plus_CLess_cursor2 E_CLess E_CLess
-- type WellFormedSyntax
--     = S_CLess_WellFormed S_CLess
--     | E_CLess_WellFormed E_CLess
--     | Wellformed_WellFormed Wellformed
-- {-| Cursor context / CCtx / C sorts and operators
-- -}
-- type Cctx
--     = Hole
--     | Let_CLess_cctx1 Cctx (Bind E_CLess S_CLess)
--     | Let_CLess_cctx2 E_CLess (Bind E_CLess Cctx)
--     | Exp_CLess_cctx1 Cctx
--     | Plus_CLess_cctx1 Cctx E_CLess
--     | Plus_CLess_cctx2 E_CLess Cctx
-- type CctxSyntax
--     = S_CLess_CCtx S_CLess
--     | E_CLess_CCtx E_CLess
--     | Cctx_CCtx Cctx
-- {-| Cursorless sorts and operators
-- -}
-- type S_CLess
--     = Let_CLess E_CLess (Bind E_CLess S_CLess)
--     | Exp_CLess E_CLess
--     | Hole_s_CLess
-- type E_CLess
--     = Plus_CLess E_CLess E_CLess
--     | Num_CLess
--     | Var_CLess
--     | Hole_e_CLess
-- type CursorlessSyntax
--     = S_CLess S_CLess
--     | E_CLess E_CLess
-- {-| "Normal"/initial/clean sorts and operators
-- -}
-- type S
--     = Let E (Bind E S)
--     | Exp E
--     | Hole_s
--     | Cursor_s S
-- type E
--     = Plus E E
--     | Num
--     | Var
--     | Hole_e
--     | Cursor_e E
-- type BaseSyntax
--     = S S
--     | E E
-- type alias Bind a b =
--     ( List a, b )
-- toWellFormed : List Int -> BaseSyntax -> Maybe ( CctxSyntax, WellFormedSyntax )
-- toWellFormed pos syntax =
--     case ( pos, syntax ) of
--         ( [], _ ) ->
--             case syntax of
--                 S s ->
--                     Just ( Cctx_CCtx Hole, Root_s_CLess s )
-- toCursorLessOp : BaseSyntax -> Maybe CursorlessSyntax
-- toCursorLessOp syntax =
--     case syntax of
--         S s ->
--             Just (S_CLess s)
--         E e ->
--             Just (E_CLess e)
--         _ ->
--             Nothing
