(** This module converts the C Abstract Syntax Tree (from Ast.ml) into
    an Assembly Abstract Syntax Tree (from Assembly_ast.ml). *)

open Ast
open Assembly_ast

(** [generate_exp exp] converts a C expression AST node into an assembly operand. *)
let generate_exp (e: Ast.exp) : Assembly_ast.operand =
  match e with
  (* A constant C expression `E_Constant n` maps directly
     to an immediate assembly operand `A_Imm n`. *)
  | E_Constant n -> A_Imm n

(** [generate_statement stmt] converts a C statement AST node into a list of assembly instructions. *)
let generate_statement (s: Ast.statement) : Assembly_ast.instruction list =
  match s with
  (* A C return statement `S_Return e` is translated into two assembly instructions:
     1. Move the result of the expression `e` into the return register (`%eax`).
     2. Return from the function. *)
  | S_Return e ->
      let source_operand = generate_exp e in
      [ I_Mov (source_operand, A_Register); I_Ret ]

(** [generate_program prog] converts a top-level C AST into a top-level Assembly AST. *)
let generate_program (p: Ast.program) : Assembly_ast.program =
  match p with
  (* Deconstruct the C program to get the function definition inside. *)
  | P_PROGRAM c_func ->
      (* Generate the list of instructions from the C function's body. *)
      let instructions = generate_statement c_func.body in
      (* Construct the assembly function definition. *)
      let asm_func = { name = c_func.name; instructions = instructions } in
      (* Wrap it in the top-level assembly program constructor. *)
      P_Program asm_func
