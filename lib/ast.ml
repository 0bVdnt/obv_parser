(* This file implements the types and functions promised in ast.mli. *)

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
(* <function> ::= "int" <identifier> "(" [ "void" ] ")" "{" <statement> "}" *)
(* Here [ "void" ] is the notation from EBNF - Extended Backus-Naur Form representing that it is optional*)
type func = {
    name: string;
    body: statement;
}
(* <program> ::= <function> *)
type program =
    | P_PROGRAM of func

(* III. Exceptions *)
(* A custom exception for errors during JSON-to-token conversion. *)
exception DeserializationError of string
(* A custom exception for errors during the parsing phase (violating grammar rules). *)
exception SyntaxError of string

(* IV. Pretty Printer and Main Executable *)
(* `let string_of_exp indent exp = ...` : This defines a function named `string_of_exp`.
   `let` is the keyword for defining variables and functions.
   `indent` and `exp` are the two arguments to the function.
   The `=` sign separates the function definition from its body.
   This function is PRIVATE because it is not listed in `ast.mli`. *)
let string_of_exp indent exp =
    (* `let i = ...` : Defines a local variable `i`. *)
    let i = String.make indent ' ' in
    (* `match exp with ...` : This is OCaml's pattern matching construct.
       It inspects the value of `exp` and executes the code for the first pattern that matches. *)
    match exp with
    (* `| E_Constant n -> ...` : This is a pattern. It reads as: "If `exp` is an
       `E_Constant` value, then bind the integer it holds to the new variable `n`."
       The `->` arrow separates the pattern from the code to execute if it matches. *)
    | E_Constant n -> 
        (* `^` is the string concatenation operator. `string_of_int` is a built-in
           function that converts an integer to a string. *)
        i ^ "Constant(" ^ (string_of_int n) ^ ")"

(* Another private helper function for the pretty-printer. *)
let string_of_statement indent stmt =
    let i = String.make indent ' ' in
    match stmt with
    | S_Return exp ->
        "Return(\n" ^
        (* Makes a recursive call to the other private helper function. *)
        (string_of_exp (indent + 2) exp) ^ "\n" ^
        i ^ ")"

(* `let string_of_program prog = ...` : This is the PUBLIC function.
   It implements the `val string_of_program` that was promised in the `.mli` file. *)
let string_of_program prog =
    match prog with
    | P_PROGRAM func ->
        (* This pattern deconstructs the `P_PROGRAM` to get the `func` record inside. *)
        "Program(\n" ^
        "  Function(\n" ^
        (* `func.name` uses dot-notation to access a field of a record. *)
        "    name=\"" ^ func.name ^ "\",\n" ^
        "    body=" ^ (string_of_statement 4 func.body) ^ "\n" ^
        "  )\n" ^
        ")"

