(** This module defines the data types for an Abstract Syntax Tree
    representing a simple x64 Assembly program. *) 

(** Operands for assembly instructions. *)
type operand =
  | A_Imm of int        (** An immediate (constant) integer value, e.g., $5 *)
  | A_Register          (** A register. For now, only %eax is used implicitly. *)

(** The different kinds of assembly instructions we can generate. *)
type instruction =
  | I_Mov of operand * operand  (** Represents `movl src, dst` *)
  | I_Ret                       (** Represents the `ret` instruction *)

(** A function definition in assembly, containing a name and a list of instructions. *)
type func = {
  name: string;                (** The name of the function, e.g., "main" *)
  instructions: instruction list; (** The sequence of instructions in the function body *)
}

(** The top-level assembly program structure, containing a single function. *)
type program =
  | P_Program of func
