(* I. The Input: Tokens *)
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

(* II. The Output: Abstract Syntax Tree (AST) *)

(* <exp> ::= <integer_literal> *)
type exp = 
    | E_Constant of int

(* <statement> ::= "return" <exp> ";" *)
type statement =
    | S_Return of exp

(* <function> ::= "int" <identifier> ... { <statement> } *)
type func = {
    name: string;
    body: statement;
}

(* <program> ::= <function> *)
type program =
    | P_PROGRAM of func

(* III. Parser Infrastructure *)

(* A custom exception for errors during JSON-to-token conversion. *)
exception DeserializationError of string

(* A custom exception for errors during the parsing phase (violating grammar rules). *)
exception SyntaxError of string

open Yojson.Basic.Util

let token_from_json (json: Yojson.Basic.t) : token =
    match json with
    | `String s -> (
        match s with
        | "KwInt" -> T_KW_INT
        | "KwVoid" -> T_KW_VOID
        | "KwReturn" -> T_KW_RETURN
        | "OpenParen" -> T_LPAREN
        | "CloseParen" -> T_RPAREN
        | "OpenBrace" -> T_LBRACE
        | "CloseBrace" -> T_RBRACE
        | "Semicolon" -> T_SEMICOLON
        | other -> raise (DeserializationError ("Unknown string token: " ^ other))
        ) 
    | `Assoc [ (key, value) ] -> (
        match key with
        | "Identifier" -> T_IDENTIFIER (to_string value)
        | "Constant" -> T_CONSTANT (to_int value)
        | other -> raise (DeserializationError ("Unknown object key token: " ^ other))
        )
    | _ ->
        raise
            (DeserializationError
                ("Invalid JSON token format: " ^ Yojson.Basic.to_string json)
            )

let tokens_from_string (s: string) : token list =
    try
        let json = Yojson.Basic.from_string s in
        match json with
            | `Assoc [ ("Success", `List tokens_json) ] ->
                List.map token_from_json tokens_json
            | `Assoc [ ("Error", error_json) ] ->
                let err_str = Yojson.Basic.pretty_to_string error_json in
                raise (DeserializationError ("The lexer reported an error:\n" ^ err_str))
            | _ ->
                let err_str = Yojson.Basic.to_string json in
                raise (DeserializationError ("Expected a 'Success' or 'Error' object, but got:" ^ err_str) )
    with
        | Yojson.Json_error msg -> raise (DeserializationError ("JSON parsing failed: " ^ msg))

let string_of_token = function
    | T_KW_INT -> "'int'" 
    | T_KW_VOID -> "'void'"
    | T_KW_RETURN -> "'return'"
    | T_LPAREN -> "'('"
    | T_RPAREN -> "')'"
    | T_LBRACE -> "'{'"
    | T_RBRACE -> "'}'"
    | T_SEMICOLON -> "';'"
    | T_IDENTIFIER s -> "identifier '" ^ s ^ "'"
    | T_CONSTANT i -> "constant '" ^ string_of_int i ^ "'"

let take_token (tokens : token list) : token * (token list) = 
    match tokens with
    | [] -> raise (SyntaxError "Unexpected end of file. Expected more tokens.")
    | hd :: tl -> (hd, tl)

let expect (expected : token) (tokens : token list) : token list =
    let (actual, rest) = take_token tokens in
    if actual = expected then
        rest
    else
        let msg = "Expected " ^ (string_of_token expected) ^ " but found " ^ (string_of_token actual) in
        raise (SyntaxError msg)
