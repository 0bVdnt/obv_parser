(* `open Obv_parser_lib` : This kind of declaration is done with the help of dune. 
   - `(public_name obv_parser.lib)` in `lib/dune` tells dune to create a top-level module
     from the library.
   - Dune converts the name `obv_parser.lib` into the OCaml module name `Obv_parser_lib`
     (capitalizing segments and replacing '.' with '_').
   - `open` makes all the public modules INSIDE the library (`Ast`, `Parser`, `Token_stream`)
     directly available in this file. Without this, it would be required to write:
     `Obv_parser_lib.Ast.SyntaxError` everywhere. *)
open Obv_parser_lib 

(* `let () = ...` : This is the standard idiom for defining the main executable block in OCaml.
   - `let () =`: Defines a value named `()`. The `()` pattern is special; it matches only the
     `()` value (called "unit"). Unit is a type with only one value, used to represent the
     absence of a meaningful value, similar to `void` in C/Java.
   - The entire block on the right-hand side of the `=` is executed when the program starts.
     Since its final result is `()` (e.g., from `print_endline` or `exit`), the `let () =`
     binding succeeds, and the program's "main" work is done. *)
let () =
    (* `try ... with ...` : The entire program logic is wrapped in an exception handler
       to gracefully catch any errors that might be raised by the library. *)
    try
        (* I. Read from stdin *)
        (* `In_channel.input_all` is a function from OCaml's standard library.
           `In_channel` is a module for handling input channels, and `stdin` is the
           pre-defined channel for standard input. This function reads everything
           from stdin until the end-of-file and returns it as a single string. *)
        let input_json = In_channel.input_all stdin in
        
        (* II. Deserialize the JSON *)
        (* The public function from `Token_stream` module is called.
           Note that because of the statement`open Obv_parser_lib`, writing `Token_stream`
           instead of the full `Obv_parser_lib.Token_stream` is allowed. *)
        let tokens = Token_stream.token_from_string input_json in

        (* III. Run the parser *)
        (* The public function from the `Parser` module is called. *)
        let ast = Parser.parse_program tokens in

        (* IV. Print the result *)
        (* The public function from the `Ast` module is called to pretty-print the result.
           `print_endline` is a standard function that prints a string to standard output,
           followed by a newline character. *)
        print_endline (Ast.string_of_program ast)

    (* V. Handle errors *)
    (* The `with` block contains a series of "handlers". OCaml will try to match the
       raised exception against each pattern in order. *)
    with
    (* `| Ast.DeserializationError msg -> ...` : This pattern matches the custom exception.
       It is qualified with the `Ast.` to be explicit about where it's defined.
       The pattern also deconstructs the exception to bind its string payload to `msg`. *)
    | Ast.DeserializationError msg ->
        (* `Printf.eprintf` is like `printf`, but it prints to standard error (`stderr`),
           which is the correct place for error messages. The format string `"%s\n"`
           tells it to print a string followed by a newline. *)
        Printf.eprintf "[PARSER ERROR] Failed to read tokens: %s\n" msg;
        (* `exit 1` terminates the program immediately with a non-zero exit code.
           By convention, an exit code of 0 means success, and any other number means failure.
           This is crucial for scripting and automated testing. *)
        exit 1
    | Ast.SyntaxError msg ->
        Printf.eprintf "[PARSER ERROR] Syntax error: %s\n" msg;
        exit 1
    (* `| e -> ...` : This is a catch-all handler. The variable `e` will be bound to
       *any* other exception that wasn't caught by the previous handlers. *)
    | e ->
        (* `Printexc.to_string e` is a utility that converts any exception `e` into a
           human-readable string representation. This is useful for debugging unknown errors. *)
        Printf.eprintf "[PARSER ERROR] An unknown error occurred: %s\n" (Printexc.to_string e);
        exit 1

