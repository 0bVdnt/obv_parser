(** This module defines the data types for an Abstract Syntax Tree
    representing a simple x64 Assembly program. *) 

(** The type for operands in assembly instructions. *)
type operand =
  | A_Imm of int        (** An immediate (constant) integer value, e.g., `$5`. *)
  | A_Register          (** A CPU register. For this simple compiler stage, it implicitly represents `%eax`. *)

(** The type for the different kinds of assembly instructions that can be generated. *)
type instruction =
  | I_Mov of operand * operand  (** Represents the `movl src, dst` instruction. *)
  | I_Ret                       (** Represents the `ret` instruction to return from a function. *)

(** The type for a function definition in assembly. *)
type func = {
  name: string;                   (** The name of the function, e.g., `"main"`. *)
  instructions: instruction list; (** The ordered sequence of instructions in the function body. *)
}

(** The type for the top-level assembly program structure. *)
type program =
  | P_Program of func         (** A program consists of a single function definition. *)
