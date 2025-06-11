(* Open the `Ast` module to get access to all the types (`token`, `exp`, `SyntaxError`, etc.)
   and the type constructors (`T_KW_INT`, `E_Constant`, etc.). *)
open Ast

(* --- I. Private Helper Functions --- *)
(* These functions are not in the .mli file, so they are private to this module. *)

(* `let string_of_token = function ...` : This defines a function `string_of_token`.
   The `function` keyword is a shortcut for `fun x -> match x with ...`.
   It creates an anonymous function that immediately pattern matches on its single argument.
   This is a common and concise idiom in OCaml. *)
let string_of_token = function
    | T_KW_INT -> "'int'" 
    | T_KW_VOID -> "'void'"
    | T_KW_RETURN -> "'return'"
    | T_LPAREN -> "'('"
    | T_RPAREN -> "')'"
    | T_LBRACE -> "'{'"
    | T_RBRACE -> "'}'"
    | T_SEMICOLON -> "';'"
    (* `| T_IDENTIFIER s -> ...` : Here the token is deconstructed to get the string `s` inside. *)
    | T_IDENTIFIER s -> "identifier '" ^ s ^ "'"
    | T_CONSTANT i -> "constant '" ^ string_of_int i ^ "'"

(* `let take_token (tokens : token list) : token * (token list) = ...`
   - This function takes one argument, `tokens`, of type `token list`.
   - `: token * (token list)`: This is the return type annotation. The `*` indicates a "tuple".
     A tuple is an ordered, fixed-size collection of values of potentially different types.
     This function returns a pair: the first element is a `token`, the second is a `token list`. *)
let take_token (tokens : token list) : token * (token list) = 
    match tokens with
    (* `| [] -> ...` : Matches an empty list. *)
    | [] -> raise (SyntaxError "Unexpected end of file. Expected more tokens.")
    (* `| hd :: tl -> ...` : This is the fundamental pattern for list deconstruction.
       It matches a non-empty list, binding the first element (the "head") to the variable `hd`
       and the rest of the list (the "tail") to the variable `tl`. *)
    | hd :: tl -> (hd, tl)

(* `let expect (expected : token) (tokens : token list) : token list = ...`
   This is a core utility of the parser. It enforces the grammar rules. *)
let expect (expected : token) (tokens : token list) : token list =
    (* Here helper function is being used to get the next token and the remaining list. *)
    let (actual, rest) = take_token tokens in
    (* The `actual` token is compared with the `expected` one. The `token` type can be
       compared with `=` because it is a variant type. *)
    if actual = expected then
        rest (* Success: return the list of remaining tokens. *)
    else
        (* Failure: construct a helpful error message and raise the `SyntaxError` exception. *)
        let msg = "Expected " ^ (string_of_token expected) ^ " but found " ^ (string_of_token actual) in
        raise (SyntaxError msg)

(* --- II. The Recursive Descent Parsing Functions (Private) --- *)
(* Each function here corresponds to a non-terminal symbol in the grammar. *)

(* `let rec ... and ...` : This syntax defines a group of mutually recursive functions.
   All functions defined between the `let rec` and the next `let` at the top level
   can call each other, even if a function is called before it is textually defined.
   This is essential for parsing, as grammar rules are often mutually recursive. *)

(* parse_exp
   Grammar: <exp> ::= <constant>
   Consumes a constant token and returns an 'exp' AST node.
*)
let rec parse_exp tokens =
    let token, rest_of_tokens = take_token tokens in
    match token with
        (* The rule for <exp> is just a constant. Here it is matched and an AST node
           `E_Constant i` is built, and returned along with the remaining tokens. *)
        | T_CONSTANT i -> (E_Constant i, rest_of_tokens)
        | other ->
            let msg = "Expected a constant expression but found " ^ string_of_token other in
            raise (SyntaxError msg)

(* NOTE: the `and` keyword. This continues the `let rec` block. *)

(* parse_statement
   Grammar: <statement> ::= "return" <exp> ";"
   Consumes a return statement and returns a 'statement' AST node.
*)
and parse_statement tokens =
    let tokens_after_return = expect T_KW_RETURN tokens in
    (* Another parsing function, `parse_exp`, is called to handle the <exp> non-terminal. *)
    let exp_node, tokens_after_exp = parse_exp tokens_after_return in
    let tokens_after_semicolon = expect T_SEMICOLON tokens_after_exp in
    (* Construt the `S_Return` AST node, wrapping the `exp_node` obtained from `parse_exp`. *)
    (S_Return exp_node, tokens_after_semicolon)

(* parse_function
   Grammar:<function> ::= "int" <identifier> "(" [ "void" ] ")" "{" <statement> "}" 
   Consumes a full function definition and returns a 'func' AST node.
*)
and parse_function tokens =
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
    (* Check for the OPTIONAL 'void' keyword. *)
    let tokens =
        (* This is a "peek" operation. Looking at the next token without consuming it.
           Deconstruct the result of `take_token` but immediately ignore the tail (`_`). *)
        let (next_token, _) = take_token tokens in
        if next_token = T_KW_VOID then
            expect T_KW_VOID tokens (* If `void` is present consume it using expect. *)
        else
            tokens (* Otherwise, do nothing and proceed. *)
    in
    let tokens = expect T_RPAREN tokens in
    let tokens = expect T_LBRACE tokens in
    let (body_node, tokens) = parse_statement tokens in
    let tokens = expect T_RBRACE tokens in
    (* Construct the `func` record using the `{...}` syntax. *)
    let func_node = { name = func_name; body = body_node } in
    (func_node, tokens)

(* This is the PUBLIC function defined in the `.mli` file. It's the entry point.
   Note that it's defined with `let`, not `and`, which ends the `let rec` block. *)
(* parse_program
   Grammar: <program> ::= <function>
   This is the top-level entry point for parsing. It consumes an entire
   token stream and returns a single 'program' AST node.
*)
let parse_program (tokens : token list) : program =
    (* The whole process is started by calling the top-level non-terminal parser. *)
    let (func_node, remaining_tokens) = parse_function tokens in
    
    (* This is a crucial final check. A valid program should not have any leftover
       tokens at the end. *)
    match remaining_tokens with
    | [] ->
        (* Success. Construct the final `P_PROGRAM` AST node. *)
        P_PROGRAM func_node
    | hd :: _ ->
        (* Failure. Extra tokens were found after a valid function. *)
        let msg = "Expected end of file but found unexpected token: " ^ (string_of_token hd) in
        raise(SyntaxError msg)

