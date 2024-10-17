**Zigsp**

Zigsp - a short from Zig Lisp is a small and naive Scheme interpreter in Zig.
The aim of this project is to learn the basics of Zig and have some fun writing an interpreter.

**Features**
What works:
1) Variable definitions
2) If statements
3) Functions
4) Multiple primitive data types (booleans, numbers)
5) Basic mathematical operations (+, -, =, <, >, etc.)
6) Comparisons (not across types)
7) Working with formatted .scm files

What isn't implemented:
1) Lists
2) ~~Recursion (it is buggy at the moment)~~ seems to be okay now
3) Macros
4) More complex data types (strings, vectors, etc.)
5) Quotes 
6) Readable errors and a lot of more complex error handling

**Running Zigsp**
These instructions will guide you through the process of building and running your Zig project using Zig version 0.11.0.

**Prerequisites**
Zig v0.11.0 or later must be installed on your system.
Clone the Repository
If you haven't already, clone your project's repository to your local machine.

**Dev Build Instructions**

```bash
git clone https://github.com/Emulebest/Zigsp.git
cd Zigsp
zig run src/main.zig -- <absolute_path_to_your_source_file.scm>
```

**Optimized Build instructions**

```bash
git clone https://github.com/Emulebest/Zigsp.git
cd Zigsp
zig build
./zig-out/bin/Zigsp <absolute_path_to_your_source_file.scm>
```

