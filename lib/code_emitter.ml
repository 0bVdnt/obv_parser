(** This module converts an Assembly Abstract Syntax Tree (Assembly_ast.program)
    into a final, formatted assembly string, ready to be written to a .s file. *)

open Assembly_ast

(** [format_operand op] converts an operand data type into its string representation. *)
let format_operand (op: operand) : string =
  match op with
  | A_Imm n -> "$" ^ string_of_int n (* Immediate values are prefixed with '$' *)
  | A_Register -> "%eax"             (* For now, we hardcode the %eax register *)

(** [format_instruction instr] converts an instruction data type into its string representation.
    Instructions are indented with 4 spaces for readability. *)
let format_instruction (instr: instruction) : string =
  match instr with
  | I_Mov (src, dst) ->
      "    movl " ^ format_operand src ^ ", " ^ format_operand dst
  | I_Ret ->
      "    ret"

(** [emit_program prog is_macos] converts a top-level Assembly AST into a
    single string containing the full, formatted assembly code. *)
let emit_program (p: program) (is_macos: bool) : string =
  match p with
  | P_Program asm_func ->
      (* On macOS, function names in assembly are prefixed with an underscore. *)
      let func_name =
        if is_macos then "_" ^ asm_func.name
        else asm_func.name
      in
      (* Convert the list of instructions into a list of formatted strings. *)
      let instruction_strings = List.map format_instruction asm_func.instructions in
      (* On Linux, we must add a directive to mark the stack as non-executable. *)
      let gnu_stack_note =
        if is_macos then []
        else [ ".section .note.GNU-stack,\"\",@progbits" ]
      in
      (* Assemble all parts of the output into a list of lines. *)
      let all_lines =
        [ "    .globl " ^ func_name;
          func_name ^ ":"
        ]
        @ instruction_strings
        @ gnu_stack_note
      in
      (* Join all lines with newlines and add a final newline for POSIX compliance. *)
      String.concat "\n" all_lines ^ "\n"
