(**
 * @module Code_emitter
 * This module is responsible for the final stage of the compilation process:
 * converting a structured Assembly Abstract Syntax Tree (Assembly_ast.program)
 * into a final, formatted assembly string, ready to be written to a .s file.
 * It handles platform-specific details, such as function name mangling for macOS
 * and security directives for Linux.
*)

(* The `open` keyword brings the type definitions from the `Assembly_ast` module
   into the current scope. This allows us to use types like `operand`, `instruction`,
   and `program` directly, without having to prefix them with `Assembly_ast.`
   (e.g., `operand` instead of `Assembly_ast.operand`). *)
open Assembly_ast

(* --- Private Helper Functions for Formatting --- *)

(**
 * [format_operand op] converts an operand data type into its textual
 * assembly representation. For example, an immediate value `A_Imm 5` becomes
 * the string `"$5"`.
 *
 * @param op The operand data type from the Assembly AST.
 * @return A string formatted for x64 assembly.
 *)
let format_operand (op: operand) : string =
  (* `match op with` is OCaml's pattern matching construct. It inspects
     the structure of the `op` value and executes the code corresponding to the
     first matching pattern. It is exhaustive, meaning the compiler will warn
     if a variant of the `operand` type is not handled. *)
  match op with
  (* `| A_Imm n -> ...`: This is a "match arm" or "case".
     The pattern `A_Imm n` deconstructs the `A_Imm` variant of the `operand` type.
     It binds the integer value contained within the variant to the variable `n`.
     The `->` symbol separates the pattern from the expression to execute if the pattern matches. *)
  | A_Imm n ->
      (* `^` is the string concatenation operator in OCaml.
         `string_of_int n` is a standard library function that converts an integer `n`
         to its string representation. The logic here is to prefix all immediate
         (constant) values with a '$', as required by AT&T assembly syntax. *)
      "$" ^ string_of_int n
  (* `| A_Register -> ...`: This pattern matches the `A_Register` variant.
     Since `A_Register` doesn't carry any extra data, we just match the constructor itself. *)
  | A_Register ->
      (* For this stage of the compiler, we are only using a single register, `%eax`,
         for all calculations and return values, so we can hardcode it here. *)
      "%eax"

(**
 * [format_instruction instr] converts an instruction data type into its
 * textual, indented string representation.
 *
 * @param instr The instruction data type from the Assembly AST.
 * @return A single line of formatted assembly code as a string.
 *)
let format_instruction (instr: instruction) : string =
  match instr with
  (* `| I_Mov (src, dst) -> ...`: This pattern matches the `I_Mov` variant.
     It deconstructs the variant to bind its two `operand` payloads to the
     variables `src` (source) and `dst` (destination). *)
  | I_Mov (src, dst) ->
      (* This line constructs the final `movl` instruction string.
         - `"    movl "`: The instruction itself, indented with 4 spaces for readability.
         - `format_operand src`: A recursive call to format the source operand.
         - `format_operand dst`: A recursive call to format the destination operand.
         - `^`: The string concatenation operator joins all the parts together. *)
      "    movl " ^ format_operand src ^ ", " ^ format_operand dst
  (* `| I_Ret -> ...`: This pattern matches the simple `I_Ret` variant. *)
  | I_Ret ->
      (* It returns the string for the `ret` instruction, also indented. *)
      "    ret"

(* --- Public API --- *)

(**
 * [emit_program prog is_macos] converts a top-level Assembly AST into a
 * single string containing the full, formatted assembly code. This is the
 * main entry point for this module.
 *
 * @param p The complete Assembly AST program.
 * @param is_macos A boolean flag to indicate if the target platform is macOS,
 *   which requires different formatting from Linux.
 * @return A complete, multi-line string of the final assembly code.
 *)
let emit_program (p: program) (is_macos: bool) : string =
  (* We pattern match on the top-level program to get the function definition inside. *)
  match p with
  (* `| P_Program asm_func -> ...`: Deconstructs the `P_Program` variant to bind
     the `func` record it contains to the variable `asm_func`. *)
  | P_Program asm_func ->
      (* `let <name> = <expression>` defines a new local variable.
         Here, we determine the correct function name based on the operating system. *)
      let func_name =
        (* `if ... then ... else ...` is a standard conditional expression in OCaml. *)
        if is_macos then
          (* On macOS, all C function names are prefixed with an underscore `_` in
             the final assembly file by convention. *)
          "_" ^ asm_func.name
        else
          (* On Linux and other systems, the name is used as-is. *)
          asm_func.name
      in
      (* `List.map` is a higher-order function. It takes a function `f` and a list `l`.
         It applies `f` to every element of `l` and returns a new list containing the results.
         Here, we apply `format_instruction` to every instruction in our `asm_func.instructions`
         list to produce a list of formatted instruction strings. *)
      let instruction_strings = List.map format_instruction asm_func.instructions in
      (* On Linux, we must add a directive to mark the stack as non-executable for security.
         We create a list that is either empty (for macOS) or contains the directive string.
         This makes it easy to concatenate with other lines later. *)
      let gnu_stack_note =
        if is_macos then [] (* Return an empty list for macOS. *)
        else [ ".section .note.GNU-stack,\"\",@progbits" ] (* A list with one string for Linux. *)
      in
      (* This `let` binding assembles the final list of all lines for the assembly file.
         - `[...]`: OCaml syntax for creating a list of elements.
         - `^`: The string concatenation operator.
         - `@`: The list concatenation operator. It appends two lists together. *)
      let all_lines =
        [ "    .globl " ^ func_name; (* The `.globl` directive makes the function visible to the linker. *)
          func_name ^ ":"             (* The function label, where execution will jump to. *)
        ]
        @ instruction_strings (* Append the list of formatted instruction strings. *)
        @ gnu_stack_note      (* Append the list containing the GNU stack note (which is empty on macOS). *)
      in
      (* `String.concat separator list` joins all strings in a list into a single string,
         with the `separator` string placed between each element. Here, we use newline `\n`.
         We add a final `^ "\n"` to ensure the file ends with a newline, which is a
         standard convention for text files on POSIX systems. *)
      String.concat "\n" all_lines ^ "\n"
