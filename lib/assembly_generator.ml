(** This module converts the C Abstract Syntax Tree (from Ast.ml) into
    an Assembly Abstract Syntax Tree (from Assembly_ast.ml). This process is
    often called the "instruction selection" phase of a compiler. *)

(* Open the Ast and Assembly_ast modules to have direct access to their types
   (e.g., using `E_Constant` instead of `Ast.E_Constant`). *)
open Ast
open Assembly_ast

(* --- Private Helper Functions for AST Traversal --- *)

(** [generate_exp exp] converts a C expression AST node into an assembly operand.
    @param e The C expression AST node of type [Ast.exp].
    @return The corresponding assembly operand of type [Assembly_ast.operand]. *)
let generate_exp (e: Ast.exp) : Assembly_ast.operand =
  match e with
  (* For Chapter 1, a constant C expression `E_Constant n` maps directly
     to an immediate assembly operand `A_Imm n`. *)
  | E_Constant n -> A_Imm n

(** [generate_statement stmt] converts a C statement AST node into a list of assembly instructions.
    @param s The C statement AST node of type [Ast.statement].
    @return A list of assembly instructions of type [Assembly_ast.instruction list]. *)
let generate_statement (s: Ast.statement) : Assembly_ast.instruction list =
  match s with
  (* A C return statement `S_Return e` is translated into two assembly instructions:
     1. Move the result of the expression `e` into the return register (`%eax`).
     2. Return from the function. *)
  | S_Return e ->
      (* First, generate the assembly operand for the expression `e`. *)
      let source_operand = generate_exp e in
      (* The resulting list of instructions. The order is significant. *)
      [ I_Mov (source_operand, A_Register); (* movl $val, %eax *)
        I_Ret ]                             (* ret *)

(* --- Public API --- *)

(** [generate_program prog] converts a top-level C AST into a top-level Assembly AST.
    This is the main entry point for the assembly generation stage.
    @param p The complete C program AST of type [Ast.program].
    @return The corresponding assembly program AST of type [Assembly_ast.program]. *)
let generate_program (p: Ast.program) : Assembly_ast.program =
  match p with
  (* Deconstruct the C program to get the function definition inside. *)
  | P_PROGRAM c_func ->
      (* Generate the list of instructions from the C function's body. *)
      let instructions = generate_statement c_func.body in
      (* Construct the assembly function definition record. *)
      let asm_func = { name = c_func.name; instructions = instructions } in
      (* Wrap it in the top-level assembly program constructor to complete the transformation. *)
      P_Program asm_func
