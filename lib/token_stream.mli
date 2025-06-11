(* `open Ast` : The `open` keyword makes all the public definitions from another
   module available in the current scope. Here, the `Ast` module is being opened
   in order to use the token type in the function signature below. 
   Without this, the compiler would not know
   what `token` means. *)
open Ast

(** 
 * This is the documentation comment. It describes the function
 * `token_from_string` that is declared immediately after it.
 * @raise is a standard tag used in OCaml documentation to indicate what
   exceptions a function might raise.
    
 ** [token_from_string s] attempts to deserialize a JSON string [s] into a list of tokens.
    @raise Ast.DeserializationError if the JSON is malformed, reports a lexer error,
        or is not in the expected format.
*)
val token_from_string : string -> token list

