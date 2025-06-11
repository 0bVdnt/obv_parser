(* This opens the top-level module of our library, making Ast, Parser, etc. available *)
open Obv_parser_lib 

let () =
    try
        (* I. Read the entire standard input into a string buffer *)
        let input_json = In_channel.input_all stdin in
        
        (* II. Deserialize the JSON from the lexer into a list of tokens 
               Call the function from our Token_stream module *)
        let tokens = Token_stream.token_from_string input_json in

        (* III. Run the parser on the token stream
                Call the function from our Parser module *)
        let ast = Parser.parse_program tokens in

        (* IV. If successful, pretty-print the AST to standard output
               Call the function from our Ast module *)
        print_endline (Ast.string_of_program ast)

    with
    (* V. Handle all possible errors gracefully 
          The exceptions are defined in Ast, so we qualify them *)
    | Ast.DeserializationError msg ->
        Printf.eprintf "[PARSER ERROR] Failed to read tokens: %s\n" msg;
        exit 1
    | Ast.SyntaxError msg ->
        Printf.eprintf "[PARSER ERROR] Syntax error: %s\n" msg;
        exit 1
    | e ->
        Printf.eprintf "[PARSER ERROR] An unknown error occurred: %s\n" (Printexc.to_string e);
        exit 1

