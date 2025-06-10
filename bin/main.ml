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

(* IV. Recursive Descent Parser *)
(* Each function here corresponds to a non-terminal symbol in the grammar. *)

(* parse_exp
   Grammar: <exp> ::= <constant>
   Consumes a constant token and returns an 'exp' AST node.
*)

let parse_exp (tokens : token list) : exp * token list =
    let token, rest_of_tokens = take_token tokens in
    match token with
        | T_CONSTANT i -> (E_Constant i, rest_of_tokens)
        | other ->
            let msg = "Expected a constant expression but found " ^ string_of_token other in
            raise (SyntaxError msg)

(* parse_statement
   Grammar: <statement> ::= "return" <exp> ";"
   Consumes a return statement and returns a 'statement' AST node.
*)

let parse_statement (tokens : token list) : statement * token list =
    let tokens_after_return = expect T_KW_RETURN tokens in

    let exp_node, tokens_after_exp = parse_exp tokens_after_return in

    let tokens_after_semicolon = expect T_SEMICOLON tokens_after_exp in

    (S_Return exp_node, tokens_after_semicolon)

(* parse_function
   Grammar: <function> ::= "int" <identifier> "(" ")" "{" <statement> "}"
   Consumes a full function definition and returns a 'func' AST node.
*)

let parse_function (tokens : token list) : func * token list =
    let tokens = expect T_KW_INT tokens in

    let (func_name, tokens) =
        let (token, rest) = take_token tokens in
        match token with 
        | T_IDENTIFIER s -> (s, rest)
        | other -> 
            let msg = "Expected an identifier for function name, but found " ^ string_of_token other in
            raise (SyntaxError msg)
    in
    let tokens = expect T_LPAREN tokens in
    let tokens = expect T_RPAREN tokens in
    let tokens = expect T_LBRACE tokens in

    let (body_node, tokens) = parse_statement tokens in
    let tokens = expect T_RBRACE tokens in
    let func_node = { name = func_name; body = body_node } in
    (func_node, tokens)

(* parse_program
   Grammar: <program> ::= <function>
   This is the top-level entry point for parsing. It consumes an entire
   token stream and returns a single 'program' AST node.
*)

let parse_program (tokens : token list) : program =
    let (func_node, remaining_tokens) = parse_function tokens in
    
    match remaining_tokens with
    | [] ->
        P_PROGRAM func_node
    | hd :: _ ->
        let msg = "Expected end of file but found unexpected token: " ^ (string_of_token hd) in
        raise(SyntaxError msg)

(* V. Pretty Printer and Main Executable *)

let string_of_exp indent exp =
    let i = String.make indent ' ' in
    match exp with
    | E_Constant n -> i ^ "Constant(" ^ (string_of_int n) ^ ")"

let string_of_statement indent stmt =
    let i = String.make indent ' ' in
    match stmt with
    | S_Return exp ->
        i ^ "Return(\n" ^
        (string_of_exp (indent + 2) exp) ^ "\n" ^
        i ^ ")"

let string_of_program prog =
    match prog with
    | P_PROGRAM func ->
        "Program(\n" ^
        "  Function(\n" ^
        "    name=\"" ^ func.name ^ "\",\n" ^
        "    body=" ^ (string_of_statement 4 func.body) ^ "\n" ^
        "  )\n" ^
        ")"

let () =
    try
        (* 1. Read the entire standard input into a string buffer *)
        let input_json = In_channel.input_all stdin in
        
        (* 2. Deserialize the JSON from the lexer into a list of tokens *)
        let tokens = tokens_from_string input_json in
        
        (* 3. Run the parser on the token stream *)
        let ast = parse_program tokens in

        (* 4. If successful, pretty-print the AST to standard output *)
        print_endline (string_of_program ast)

        (* 5. Handle all possible errors gracefully *)
    with
    | DeserializationError msg ->
        Printf.eprintf "[PARSER ERROR] Failed to read tokens: %s\n" msg;
        exit 1
    | SyntaxError msg ->
        Printf.eprintf "[PARSER ERROR] Syntax error: %s\n" msg;
        exit 1
    | e ->
        Printf.eprintf "[PARSER ERROR] An unknown error occurred: %s\n" (Printexc.to_string e);
        exit 1
