(* Export all type definitions *)

type token =
    | T_KW_RETURN
    | T_KW_INT
    | T_KW_VOID
    | T_LPAREN
    | T_RPAREN
    | T_LBRACE
    | T_RBRACE
    | T_SEMICOLON
    | T_IDENTIFIER of string
    | T_CONSTANT of int

type exp = 
    | E_Constant of int

type statement =
    | S_Return of exp

type func = {
    name: string;
    body: statement;
}

type program =
    | P_PROGRAM of func

(* Export exceptions *)
exception DeserializationError of string
exception SyntaxError of string

(* Export the pretty-printer *)
val string_of_program : program -> string
