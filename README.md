# OBV Compiler: From C to x64 Assembly

A multi-language, multi-stage compiler that transforms a minimal C-like language into platform-aware x64 assembly.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![OCaml](https://img.shields.io/badge/OCaml-5.1-orange.svg)](https://ocaml.org)
[![Build with Dune](https://img.shields.io/badge/build-dune-ff69b4.svg)](https://dune.build/)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS-lightgrey.svg)]()

This project demonstrates parsing of tokens, assembly generation and x64 assembly code emission, which is a part of a full compiler pipeline, starting from a C source file and ending with a runnable assembly file. It is composed of two main repositories working in concert:

1.  **Lexer (Rust):** A [sister Rust-based project (obv_lexer)](https://github.com/0bVdnt/obv_lexer.git) handles the initial scanning of the source code.
2.  **Parser & Code Generator (OCaml):** This repository consumes the lexer's output and performs all subsequent stages: parsing, semantic analysis, and assembly code generation.

The primary goal is to build and understand a complete, working toolchain, leveraging the strengths of both Rust (for performance-critical I/O) and OCaml (for its powerful type system and elegance in Abstract Syntax Tree transformations).

---

## 📜 Table of Contents

- [The Compiler Pipeline](#the-compiler-pipeline)
- [The Compilation Stages](#the-compilation-stages)
  - [Stage 1: Lexical Analysis (in Rust)](#stage-1-lexical-analysis-in-rust)
  - [Stage 2: Syntactic Analysis (Parsing in OCaml)](#stage-2-syntactic-analysis-parsing-in-ocaml)
  - [Stage 3: Assembly Generation (in OCaml)](#stage-3-assembly-generation-in-ocaml)
  - [Stage 4: Code Emission (in OCaml)](#stage-4-code-emission-in-ocaml)
- [Current Compiler Capabilities](#-current-compiler-capabilities)
- [Project Architecture](#-project-architecture)
- [Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation & Building](#installation--building)
  - [Execution](#execution)
- [Error Handling](#-error-handling)
- [Potential Extensions](#-potential-extensions)
- [License](#-license)

---

## The Compiler Pipeline

This project implements a classic sequential pipeline, where the output of each stage becomes the input for the next, transforming the code from a high-level language into low-level machine instructions.

```mermaid
graph TD
    A[C Source File (.c)] -->|1. Lexing (Rust)| B(Token Stream JSON);
    B -->|2. Parsing (OCaml)| C{C Language AST};
    C -->|3. Assembly Generation (OCaml)| D{x64 Assembly AST};
    D -->|4. Code Emission (OCaml)| E[Formatted Assembly File (.s)];
    E -->|5. Assembling (GCC/Clang)| F(Executable);
```

---

## The Compilation Stages

Each stage performs a distinct transformation on the program's representation.

### Stage 1: Lexical Analysis (in Rust)

The process begins with the **lexer** ([obv_lexer](https://github.com/0bVdnt/obv_lexer.git)). Its job is to scan the raw source text and break it into a stream of atomic units called **tokens**.
-   **Input:** C source code (e.g., `int main() { ... }`).
-   **Process:** Identifies keywords (`int`), identifiers (`main`), punctuation (`{`, `}`), and literals (`42`).
-   **Output:** A JSON array of these tokens, ready for the next stage.

### Stage 2: Syntactic Analysis (Parsing in OCaml)

The **parser** gives structure to the flat stream of tokens. It verifies that the tokens conform to the language's formal grammar and builds a hierarchical representation of the code.

#### Core Parsing Concepts

The parser's primary responsibilities are:
-   **Input:** To consume a linear sequence of tokens produced by the lexer.
-   **Syntactic Analysis:** To verify that this sequence of tokens conforms to the formal grammar of the source language. If it does not, the parser reports a **syntax error**.
-   **Output:** To produce a tree-like data structure called an **Abstract Syntax Tree (AST)** that represents the hierarchical structure and meaning of the source code.

This project implements a **recursive descent parser**, which is a top-down parsing strategy. The core idea is to create a set of mutually recursive functions, where each function is responsible for parsing one non-terminal symbol from the language's grammar. This approach makes the parser code a direct, readable reflection of the formal grammar.

#### From Grammar to Code: The Three Artifacts

The construction of this parser relies on three distinct but related artifacts:

**1. The AST Definition (ASDL)**

The Abstract Syntax Tree (AST) is the **output** of the parser. It's a hierarchical representation of the program's meaning, stripped of syntactic details like semicolons and braces.

> *ASDL for this project:*
> ```asdl
> program = Program(function_definition)
> function_definition = Function(identifier name, statement body)
> statement = Return(exp)
> exp = Constant(int)
> ```
In our OCaml project, this is implemented using algebraic data types in `lib/ast.ml`.

**2. The Formal Grammar (EBNF)**

The formal grammar defines the **concrete syntax** of the language. It guides the parser's logic by specifying exactly which tokens are required and in what order.

> *EBNF for this project:*
> ```ebnf
> <program>   ::= <function>
> <function>  ::= "int" <identifier> "(" [ "void" ] ")" "{" <statement> "}"
> <statement> ::= "return" <exp> ";"
> <exp>       ::= <integer_literal>
> ```

**3. The Parser Implementation**

The parser's code is the bridge between the formal grammar and the AST. It consumes tokens according to the grammar rules and constructs the corresponding AST nodes.

> *Pseudocode for `parse_statement`:*
> ```pseudocode
> parse_statement(tokens):
>     expect("return", tokens)      // Consume a terminal from the grammar
>     return_val = parse_exp(tokens)  // Call a function for a non-terminal
>     expect(";", tokens)          // Consume another terminal
>     return Return(return_val)    // Construct and return an AST node
> ```

### Stage 3: Assembly Generation (in OCaml)

This is the first step of translation towards the target machine. The **assembly generator** walks the high-level C AST and translates it into a lower-level, structured representation of assembly code.

#### From C AST to Assembly AST

This stage is another transformation from one tree structure to another. It is defined by two key artifacts: the target Assembly AST and the translation logic.

**1. The Assembly AST Definition (ASDL)**

This defines the structure of our assembly language representation. Keeping assembly in this structured form (instead of printing strings directly) allows for easier manipulation and platform-specific logic.

> *ASDL for the Assembly AST:*
> ```asdl
> program = Program(function_definition)
> function_definition = Function(identifier name, instruction* instructions)
> instruction = Mov(operand src, operand dst) | Ret
> operand = Imm(int) | Register
> ```
In our OCaml project, this is implemented in `lib/assembly_ast.ml`.

**2. The Translation Logic**

The `assembly_generator.ml` module contains the functions that traverse the C AST and build the Assembly AST. A key concept is that a single, high-level C node may expand into multiple low-level assembly instructions.

> *Example Translation:*
> A `Return` node from the C AST...
> ```ocaml
> (* C AST Node *)
> S_Return (E_Constant 42)
> ```
> ...is translated into a *list* of assembly instructions:
> ```ocaml
> (* Assembly AST Nodes *)
> [ I_Mov (A_Imm 42, A_Register); I_Ret ]
> ```
This corresponds to `movl $42, %eax` followed by `ret`.

### Stage 4: Code Emission (in OCaml)

The **code emitter** performs the final translation. It traverses the structured Assembly AST and prints the final, formatted text.
-   **Input:** The Assembly AST.
-   **Process:** Each node of the Assembly AST is converted into its textual x64 assembly equivalent. This stage handles platform-specific syntax like `_main` for macOS and `.note.GNU-stack` for Linux.
-   **Output:** A complete, formatted assembly file (`.s`) ready to be assembled.

---
## Current Compiler Capabilities

The compiler can successfully process programs that have the following structure:
-   A single `int` function with an identifier (e.g., `main`).
-   The function's parameter list can be `()` or `(void)`.
-   The function body must contain exactly one `return` statement.
-   The `return` statement must return a single integer literal.

#### Valid Code Example:
```c
int main(void) {
    return 42;
}
```
The output for this code will be a runnable assembly file that, when executed, produces an exit code of `42`.

---

## Project Architecture

This OCaml project is structured as a library (`lib/`) and a thin executable (`bin/`) using the Dune build system.

```
.
├── bin/                       # Executable code
│   ├── dune
│   └── main.ml                # Entry point: orchestrates the full pipeline
├── lib/                       # Library code (reusable)
│   ├── ast.ml                 # Defines C AST, token types, and exceptions
│   ├── ast.mli                # Public interface for the Ast module
│   ├── assembly_ast.ml        # Defines the x64 Assembly AST types
│   ├── assembly_generator.ml  # Logic to convert C AST -> Assembly AST
│   ├── code_emitter.ml        # Logic to convert Assembly AST -> Assembly String
│   ├── dune
│   ├── parser.ml              # The recursive descent parsing logic
│   ├── parser.mli             # Public interface for the Parser
│   ├── token_stream.ml        # Deserializes JSON into a token list
│   └── token_stream.mli       # Public interface for the Token_stream
├── dune-project
└── obv_parser.opam            # Project metadata and dependencies
```

---

## Getting Started

### Prerequisites

- [Rust and Cargo](https://rustup.rs/) (for the lexer).
- [OCaml (version 5.0+) and OPAM](https://ocaml.org/install) (the OCaml Package Manager).
- The [Dune build system](https://dune.build/).
- A C compiler like `gcc` or `clang` (for assembling the final output).

### Installation & Building

1.  **Clone the Lexer and Compiler Repositories:**
    It's recommended to place them in the same parent directory.
    ```bash
    git clone https://github.com/0bVdnt/obv_lexer.git
    git clone https://github.com/0bVdnt/obv_parser.git
    ```

2.  **Build the Rust Lexer:**
    ```bash
    cd obv_lexer
    cargo build --release
    cd ..
    ```

3.  **Install OCaml Dependencies and Build the Compiler:**
    ```bash
    cd obv_parser
    opam install dune yojson
    dune build
    ```
    This command will create the `main.exe` executable inside the `_build` directory.

### Execution

The full pipeline involves two main steps: running the lexer, then running the OCaml compiler on its output.

1.  **Run Lexer:** Create a source file `test.c` and run the lexer, saving the output to a JSON file.
    ```bash
    # From the parent directory of both repos
    ./obv_lexer/target/release/obv_lexer ./obv_parser/test.c > ./obv_parser/test.json
    ```

2.  **Run OCaml Compiler:** Navigate into the `obv_parser` repo and run the executable on the generated JSON file.
    ```bash
    cd obv_parser
    dune exec -- ./bin/main.exe test.json
    ```
    This will generate a `test.s` assembly file.

3.  **Assemble and Run:** Use `gcc` or `clang` to create a final executable from the assembly file.
    ```bash
    gcc -o test_executable test.s
    ./test_executable
    echo $?  # Should print the value from your return statement
    ```

---

## Error Handling

The compiler is designed to fail gracefully at each stage:
- **Lexer:** Reports errors if the source code contains invalid characters.
- **Parser:**
    - Raises a `DeserializationError` if the input is not valid JSON or if the lexer reported an error.
    - Raises a `SyntaxError` if the token stream violates the language grammar.
- All errors are printed to standard error (`stderr`), and the program terminates with a non-zero exit code.

---

## Potential Extensions

This compiler is a solid foundation that can be extended to support a more complex language. Future work could include:
- Parsing and generating code for complex expressions (binary/unary operators).
- Adding support for variables, scope, and assignment.
- Implementing control flow statements like `if`/`else` and loops.
- Parsing function arguments and multiple functions.

---

## License

This project is licensed under the **MIT License**.
