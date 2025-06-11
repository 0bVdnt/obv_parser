# obv_parser
An OCaml Recursive Descent Parser.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![OCaml](https://img.shields.io/badge/OCaml-5.1-orange.svg)](https://ocaml.org)
[![Build with Dune](https://img.shields.io/badge/build-dune-ff69b4.svg)](https://dune.build/)

This repository contains a simple, hand-written recursive descent parser for a minimal, C-like language. It is designed as the second stage of a compiler, consuming a JSON token stream produced by a [sister Rust-based lexer project (obv_lexer)](https://github.com/0bVdnt/obv_lexer.git) and producing an Abstract Syntax Tree (AST).

The primary goal of this project is to understand and build a robust parser in OCaml, using the language's strengths in compiler construction, such as its powerful type system, pattern matching, and modular architecture.

---

## Table of Contents

- [Core Compiler Concepts](#core-compiler-concepts)
  - [The Role of a Parser](#the-role-of-a-parser)
  - [Recursive Descent Parsing](#recursive-descent-parsing)
  - [From Grammar to Code: The Three Artifacts](#from-grammar-to-code-the-three-artifacts)
    - [The AST Definition (ASDL)](#the-ast-definition-asdl)
    - [The Formal Grammar (EBNF)](#the-formal-grammar-ebnf)
    - [The Parser Implementation](#the-parser-implementation)
- [Current Parser Capabilities](#current-parser-capabilities)
- [Project Architecture](#project-architecture)
  - [Module Overview](#module-overview)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Building the Project](#building-the-project)
  - [Execution](#execution)
- [Error Handling](#error-handling)
- [Potential Extensions](#potential-extensions)

---

## Core Compiler Concepts

This project is built on several fundamental principles of compiler design.

### The Role of a Parser

A parser is the second phase of a compiler, following the lexer (or scanner). Its primary responsibilities are:

1.  **Input:** To consume a linear sequence of tokens produced by the lexer.
2.  **Syntactic Analysis:** To verify that this sequence of tokens conforms to the formal grammar of the source language. If it does not, the parser reports a **syntax error**.
3.  **Output:** To produce a tree-like data structure called an **Abstract Syntax Tree (AST)** that represents the hierarchical structure and meaning of the source code.

### Approach: A Hand-Written Parser
There are two main approaches to building a parser: using a parser generator (like ANTLR or Bison) or writing it by hand. This project opts for the latter, which allows for greater control and understanding of the parsing process.

### Recursive Descent Parsing

This project implements a **recursive descent parser**, which is a top-down parsing strategy. The core idea is to create a set of mutually recursive functions, where each function is responsible for parsing one non-terminal symbol from the language's grammar.

- The main function, `parse_program`, attempts to parse the top-level `<program>` symbol.
- To do so, it calls `parse_function` to handle the `<function>` symbol.
- `parse_function` in turn calls `parse_statement`, and so on.

This approach makes the parser code a direct, readable reflection of the formal grammar, which is excellent for understanding and maintenance.

### From Grammar to Code: The Three Artifacts

The construction of this parser relies on three distinct but related artifacts: the AST definition, the formal grammar, and the parser implementation itself.

**1. The AST Definition (ASDL)**

The Abstract Syntax Tree (AST) is the **output** of the parser. It's a hierarchical representation of the program's meaning, stripped of syntactic details like semicolons and braces. We define its structure using a language-neutral notation like **_Zephyr ASDL_** (Abstract Syntax Description Language).

*ASDL for this project:*
```asdl
program = Program(function_definition)
function_definition = Function(identifier name, statement body)
statement = Return(exp)
exp = Constant(int)
```
In our OCaml project, this is implemented using **algebraic data types** in `lib/ast.ml`.

**2. The Formal Grammar (EBNF)**

The formal grammar defines the **concrete syntax** of the language. Unlike the AST, it specifies exactly which tokens (`{`, `(`, `;`) are required and in what order. This grammar guides the parser's logic. The parser validates the token stream against the following formal grammar, expressed in a variant of **_EBNF (Extended Backus-Naur Form)_**:

```ebnf
<program>   ::= <function>
<function>  ::= "int" <identifier> "(" [ "void" ] ")" "{" <statement> "}"
<statement> ::= "return" <exp> ";"
<exp>       ::= <integer_literal>
```

- `<...>` denotes a non-terminal symbol (an abstract concept).
- `"`...`"` denotes a terminal symbol (a literal token).
- `[ ... ]` denotes an optional part of the rule.

**3. The Parser Implementation**

The parser's code is the bridge between the formal grammar and the AST. It consumes tokens according to the grammar rules and constructs the corresponding AST nodes. A single parsing function demonstrates this relationship perfectly:

*Pseudocode for `parse_statement`:*
```
parse_statement(tokens):
    expect("return", tokens)      // Consume a terminal from the grammar
    return_val = parse_exp(tokens)  // Call a function for a non-terminal
    expect(";", tokens)          // Consume another terminal
    return Return(return_val)    // Construct and return an AST node
```
This structured approach, based on a formal grammar and a target AST, ensures the parser is both correct and maintainable.

## Current Parser Capabilities

Based on the grammar, the parser can successfully process programs that have the following structure:

-   A single function, which must be named and have a return type of `int`.
-   The function's parameter list can be either empty `()` or explicitly void `(void)`.
-   The function body must contain exactly one statement.
-   The only valid statement is a `return` statement.
-   The `return` statement must return a single integer literal (e.g., `2`, `100`, `0`).

#### Valid Code Examples:
```c
int main() {
    return 2;
}
```
```c
int another_func(void) {
    return 12345;
}
```

#### Invalid Code Examples (will be rejected by the parser):
```c
// Invalid: Missing return value
int main() {
    return;
}

// Invalid: Expression is not a simple integer
int main() {
    return 2 + 3;
}

// Invalid: Multiple statements
int main() {
    return 1;
    return 2;
}
```

## Project Architecture

This project is structured as a library (`lib/`) and a thin executable (`bin/`) using the Dune build system. This promotes code reusability and a clean separation of concerns.

```
.
├── bin/                    # Executable code
│   ├── dune
│   └── main.ml             # Entry point: coordinates the library
├── lib/                    # Library code (reusable)
│   ├── ast.ml              # Defines AST, token types, and exceptions
│   ├── ast.mli             # Public interface for the Ast module
│   ├── dune
│   ├── parser.ml           # The recursive descent parsing logic
│   ├── parser.mli          # Public interface for the Parser
│   ├── token_stream.ml     # Deserializes JSON into a token list
│   └── token_stream.mli    # Public interface for the Token_stream
├── dune-project
└── obv_parser.opam         # Project metadata and dependencies
```

### Module Overview

- **`Ast`**: Defines all core data structures (`token`, `exp`, `statement`, etc.), custom exceptions, and the AST pretty-printer. The `.mli` file exposes these types publicly.
- **`Token_stream`**: Responsible for one thing: taking a raw JSON string from `stdin` and converting it into a `token list`. It acts as a firewall between the external data format and our internal types.
- **`Parser`**: Contains the core parsing logic. Its public interface (`parser.mli`) exposes a single function, `parse_program`, hiding all the internal `parse_*` helper functions.
- **`Main`**: The executable's entry point. It orchestrates the entire process: calling `Token_stream.from_string` and then passing the result to `Parser.parse_program`.

## Getting Started

### Prerequisites

- [OCaml (version 5.0+) and OPAM](https://ocaml.org/install) (the OCaml Package Manager).
- The [Dune build system](https://dune.build/).

### Installation

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/0bVdnt/obv_parser.git
    cd obv_parser
    ```

2.  **Install Dependencies:**
    Use OPAM to install `dune` and the necessary `yojson` library.
    ```bash
    opam install dune yojson
    ```

### Building the Project

Use Dune to compile the library and the executable.

```bash
dune build
```

This command will create the `main.exe` executable inside the `_build` directory.

### Execution

The parser is designed to be part of a pipeline. It reads a JSON string from standard input (`stdin`) and prints the result to standard output (`stdout`).

To run it, you must pipe the output from the [corresponding lexer project (obv_lexer)](https://github.com/0bVdnt/obv_lexer.git) into it.

```bash
# General command format:
# /path/to/obv_lexer <source_file.c> | dune exec ./bin/main.exe
# cargo run ../test.c > ../lexer_output.json && dune exec ./bin/main.exe < ../lexer_output.json

# Example command:
$ cargo run --manifest-path ../obv_lexer/Cargo.toml --quiet -- ../test.c | dune exec ./bin/main.exe
--- Source Code ---
int main() { return 0; }

-------------------
Done: 100% (37/37, 0 left) (jobs: 1)Program(
  Function(
    name="main",
    body=Return(
      Constant(0)
    )
  )
)
```

- `cargo run ...`: Executes the Rust lexer on a source file.
- `|`: The pipe operator, which redirects the `stdout` of the lexer to the `stdin` of the parser.
- `dune exec ./bin/main.exe`: Executes the OCaml parser.

A successful run will print the pretty-printed AST.

## Error Handling

The parser is designed to fail gracefully:

- If the input is not valid JSON or if the lexer reported an error, a `DeserializationError` is raised.
- If the token stream violates the language grammar, a `SyntaxError` is raised with a message indicating what was expected vs. what was found.
- All errors are printed to standard error (`stderr`), and the program terminates with a non-zero exit code, which is standard practice for command-line tools.

## Potential Extensions

This parser is a solid foundation that can be extended to support a more complex language. Future work could include:

- Parsing more complex expressions (binary operators, unary operators).
- Adding support for variables and assignment.
- Implementing control flow statements like `if`/`else`.
- Parsing function arguments and multiple functions.
