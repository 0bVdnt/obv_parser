(* Token type from the Ast module's interface is needed here*)
open Ast

(** [token_from_string s] attempts to deserialize a JSON string [s] into a list of tokens.
    @raise Ast.DeserializationError if the JSON is malformed, reports a lexer error,
           or is not in the expected format.
*)
val token_from_string : string -> token list
