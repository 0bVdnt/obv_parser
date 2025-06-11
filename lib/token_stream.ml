(* The two modules needed here are opened. `Ast` for the types (`token`, `DeserializationError`)
   and `Yojson.Basic.Util` for helper functions from the `yojson` library.
   `Yojson.Basic.Util` provides functions like `to_string` and `to_int`
   that extract values from JSON objects. *)
open Ast
open Yojson.Basic.Util

(* `let token_from_json (json: Yojson.Basic.t) : token = ...` :
   This defines a PRIVATE helper function. It's private because it's not listed in `token_stream.mli`.
   - `json: Yojson.Basic.t`: This is the function's argument. `json` is the argument name,
     and `Yojson.Basic.t` is its type. `.t` is a common convention in OCaml for naming the
     primary type defined by a module. So this is the main type for a JSON value from Yojson.
   - `: token`: This is an explicit type annotation for the function's return value. It states
     that this function MUST return a value of type `token`. This helps with type-checking and clarity.
*)
let token_from_json (json: Yojson.Basic.t) : token =
    (* Performs pattern match on the structure of the JSON value. Yojson uses variant types
       that look very similar to types declared in the module Ast. *)
    match json with
    (* `| `String s` : The backtick ` before a capitalized name indicates a "polymorphic variant".
       This is a different kind of variant from the ones defined in other libs. For this purposes,
       it can be considered as just another pattern. This one matches a JSON string value, and
       binds the OCaml string content to the variable `s`. *)
    | `String s -> (
        (* Using nested pattern match to check what the string value is. *)
        match s with
        | "KwInt" -> T_KW_INT (* If the string is "KwInt", return the OCaml token `T_KW_INT`. *)
        | "KwVoid" -> T_KW_VOID
        | "KwReturn" -> T_KW_RETURN
        | "OpenParen" -> T_LPAREN
        | "CloseParen" -> T_RPAREN
        | "OpenBrace" -> T_LBRACE
        | "CloseBrace" -> T_RBRACE
        | "Semicolon" -> T_SEMICOLON
        (* `| other -> ...` : A catch-all pattern. If `s` doesn't match any of the strings above,
           it will be bound to the variable `other`. *)
        | other -> 
            (* `raise (DeserializationError ...)` : Raises the custom exception if a string that
               isn't recognized is found. `raise` immediately stops execution and passes the exception
               up the call stack. *)
            raise (DeserializationError ("Unknown string token: " ^ other))
        ) 
    (* `| `Assoc [ (key, value) ]` : This pattern matches a JSON object. Specifically:
       - `` `Assoc [ ... ]``: Matches an object. `Assoc` stands for "association list".
       - `[ (key, value) ]`: This pattern matches a list that contains EXACTLY ONE element.
         That element is a pair (a tuple), which is deconstructed into `key` and `value`.
         This is how the objects like `{"Identifier": "main"}` are matched here. *)
    | `Assoc [ (key, value) ] -> (
        match key with
        | "Identifier" -> T_IDENTIFIER (to_string value)
        | "Constant" -> T_CONSTANT (to_int value)
        | other -> raise (DeserializationError ("Unknown object key token: " ^ other))
        )
    (* `| _ -> ...` : The underscore `_` is a wildcard pattern. It matches ANYTHING that
       hasn't been matched by the patterns above (e.g., a JSON number, a JSON list,
       an object with more than one key, etc.). This ensures the match is exhaustive. *)
    | _ ->
        raise
            (DeserializationError
                ("Invalid JSON token format: " ^ Yojson.Basic.to_string json)
            )

(* This is the PUBLIC function promised in the `.mli` file. *)

let token_from_string (s: string) : token list =
    (* `try ... with ...` : This is an exception handling block. The code inside the `try`
       is executed. If any part of it `raises` an exception, OCaml immediately stops
       and looks for a matching handler in the `with` block. *)
    try
        (* `let json = ...` : Calls the `yojson` library to parse the raw string `s`.
           This function itself can raise an exception (`Yojson.Json_error`), which the
           `with` block below is prepared to catch. *)
        let json = Yojson.Basic.from_string s in
        match json with
        | `Assoc [ ("Success", `List tokens_json) ] ->
            (* `List.map foo lst` is a standard library function. It creates a new list by
               applying the function `foo` to every element of the original list `lst`.
               Here, apply the private helper function `token_from_json` is applied to 
               every item in the `tokens_json` list, converting a list of JSON objects 
               into a list of the OCaml `token` type from the module Ast. *)
            List.map token_from_json tokens_json
        | `Assoc [ ("Error", error_json) ] ->
            (* `Yojson.Basic.pretty_to_string` is a helper to format JSON with indentation. *)
            let err_str = Yojson.Basic.pretty_to_string error_json in
            raise (DeserializationError ("The lexer reported an error:\n" ^ err_str))
        | _ ->
            let err_str = Yojson.Basic.to_string json in
            raise (DeserializationError ("Expected a 'Success' or 'Error' object, but got:" ^ err_str) )
    with
    (* `| Yojson.Json_error msg -> ...` : This is an exception handler. It reads:
       "If the exception raised was a `Yojson.Json_error`, then bind its string
       payload to the variable `msg` and execute this code." here the more specific
       `DeserializationError` is used to hide the details of the `yojson` library
       from the outside world. *)
    | Yojson.Json_error msg -> raise (DeserializationError ("JSON parsing failed: " ^ msg))

