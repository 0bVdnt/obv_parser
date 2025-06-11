(* This file defines the PUBLIC API of the Ast module.
   Anything NOT listed here is PRIVATE to ast.ml. *)

(* `type token = ...` : The `type` keyword begins a type definition.
   this is a definition of a "variant type" (also called a sum type or tagged union).
   This means a value of type `token` can be EXACTLY ONE of the possibilities listed below. *)
type token =
   (* `| T_KW_RETURN` : The `|` bar separates the different possible variants.
   `T_KW_RETURN` is a "constructor" for the `token` type. It's a named value
   that takes no arguments. It can be considered as an enum value in other languages. *)
   | T_KW_RETURN
   | T_KW_INT
   | T_KW_VOID
   | T_LPAREN
   | T_RPAREN
   | T_LBRACE
   | T_RBRACE
   | T_SEMICOLON
   (* `| T_IDENTIFIER of string` : This is a constructor that CARRIES DATA.
   The `of string` part means that a `T_IDENTIFIER` token isn't just a name;
   it holds an actual OCaml `string` value inside it (e.g., the function name "main"). *)
   | T_IDENTIFIER of string
   (* Similarly, this constructor carries an `int` value. *)
   | T_CONSTANT of int

(* Exports the types for the nodes of the Abstract Syntax Tree.
   These types directly model the grammar of the language. *)
type exp = 
   | E_Constant of int

type statement =
   | S_Return of exp

(* `type func = { ... }` defines a "record type".
   It's like a C struct, a collection of named fields. *)
type func = {
   (* `name: string;` : This declares a field named `name` that must hold a `string`.
       The semicolon separates the fields. *)
   name: string;
   body: statement;
}
   
type program =
   | P_PROGRAM of func

(* `exception ...` : This keyword defines a new, custom kind of exception.
   Exceptions are used for error handling. When `raised`, they interrupt the
   normal flow of the program until they are `caught` by a `try...with` block. *)
exception DeserializationError of string (* This exception also carries a string message. *)
exception SyntaxError of string

(* `val string_of_program : program -> string` :
   The `val` keyword in an `.mli` file declares that a value (or function) with this
   name and type signature exists in the corresponding `.ml` file.
   `program -> string` is the type of a function that takes one argument of type
   `program` and returns a value of type `string`. The `->` separates arguments
   and the final return type. *)
(* Exports the pretty-printer *)
val string_of_program : program -> string

