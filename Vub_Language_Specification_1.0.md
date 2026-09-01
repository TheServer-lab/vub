# Vub Language Specification

## **Version 1.0**

---

## **1. Overview**

Vub is a lightweight, self-executing build orchestration language designed for project management. It uses a single `forge.vub` file that contains both the interpreter and build configuration.

### **1.1 Philosophy**

- **Simplicity**: Easy to read and write
- **Self-contained**: Single file execution
- **Practical**: Focus on common build operations
- **Chainable**: Support for target dependencies

### **1.2 File Structure**


```
forge.vub
├── Python Interpreter (auto-executes)
├── Vub Configuration Section
│   ├── Target Definitions
│   ├── File Operations
│   └── Build Settings
└── Main Execution Entry
```


---

## **2. Syntax Specification**

### **2.1 Comments**

Comments begin with `;` and continue to the end of the line.

vub

```
; This is a comment
; Comments are ignored by the interpreter
define "build" execute = "gcc main.c"  ; Inline comment
```


### **2.2 Target Definitions**

Define executable build targets.

**Syntax:**


```
define "target_name" execute = "command"
```


**Rules:**

- Target names must be quoted with double quotes
- Commands must be quoted with double quotes
- Multiple spaces between tokens are allowed
- Commands are shell commands

**Examples:**

vub

```
define "build" execute = "gcc -Wall -O2 src/*.c -o myapp"
define "test" execute = "python tests/run_tests.py"
define "clean" execute = "rm -rf build/ *.o"
define "run" execute = "./myapp"
define "install" execute = "cp myapp /usr/local/bin/"
```


### **2.3 File Operations**

#### **2.3.1 Copy Files**

Copy files or directories from source to destination.

**Syntax:**


```
copyfile "source" "destination"
```


**Features:**

- Supports wildcards (`*`)
- Creates destination directories automatically
- Overwrites existing files

**Examples:**

vub

```
; Copy single file
copyfile "config.json" "build/config.json"

; Copy with wildcard
copyfile "assets/*" "build/assets/"

; Copy entire directory
copyfile "src/*.c" "build/src/"
```


#### **2.3.2 Move Files**

Move or rename files and directories.

**Syntax:**


```
movefile "source" "destination"
```


**Examples:**

vub

```
; Rename file
movefile "temp.log" "logs/archive.log"

; Move directory contents
movefile "build/*" "dist/"
```


#### **2.3.3 Delete Files**

Delete files or directories.

**Syntax:**


```
deletefile "path"
```


**Examples:**

vub

```
; Delete single file
deletefile "temp.log"

; Delete entire directory
deletefile "build/"

; Delete with wildcard
deletefile "*.tmp"
```


### **2.4 Build Directory**

Set the build directory for the project.

**Syntax:**


```
makefile "directory_name"
```


**Examples:**

vub

```
makefile "build"
makefile "dist"
makefile "target"
```


### **2.5 Default Target**

Define the target that runs when no arguments are provided.

**Syntax:**


```
define "default" execute = "target_name"
```


**Examples:**

vub

```
define "default" execute = "build"
define "default" execute = "all"
```


---

## **3. Command Line Interface**

### **3.1 Usage**


```
./forge.vub [target] [flags]
```


### **3.2 Flags**

| **Flag** | **Description** |
|---|---|

| `-test`             | Test/dry run mode - shows what would happen without executing |
| `-info`             | Info/verbose mode - displays detailed execution information   |
| `-{target}`         | Chain additional targets (execute after main target)          |
| `--list`            | List all available targets                                    |
| `--help`            | Display help information                                      |

### **3.3 Examples**

bash

```
# Build the project
./forge.vub build

# Test mode (dry run)
./forge.vub build -test

# Verbose mode
./forge.vub build -info

# Combined modes
./forge.vub build -test -info

# Chain targets
./forge.vub build -test -run -docs

# Clean with verbose
./forge.vub clean -info

# List targets
./forge.vub --list

# Show help
./forge.vub --help
```


---

## **4. Execution Flow**

### **4.1 Processing Order**

1. **Parse Configuration**: Read `forge.vub` file
2. **Load Targets**: Extract all target definitions
3. **Load File Ops**: Extract file operations
4. **Process Arguments**: Parse CLI arguments and flags
5. **Execute File Ops**: Run copy/move/delete operations
6. **Build Directory**: Create build directory if specified
7. **Execute Target**: Run the specified target command
8. **Chain Targets**: Execute additional targets from flags
9. **Report Status**: Display success/failure message

### **4.2 Execution Modes**

| **Mode** | **Flag** | **Behavior** |
|---|---|---|

| **Normal**           | (none)        | Executes commands directly       |
| **Test**             | `-test`       | Shows commands without executing |
| **Info**             | `-info`       | Shows detailed execution info    |
| **Test+Info**        | `-test -info` | Both dry run and verbose output  |

### **4.3 Error Handling**

- If target not found → Display error and list available targets
- If command fails → Stop execution and report error
- If file operation fails → Report error and continue or stop
- Missing files in copy/move → Report warning

---

## **5. Grammar Specification**

### **5.1 Lexical Grammar**


```
comment          ::= ';' [^\n]*
whitespace       ::= ' ' | '\t' | '\n'
identifier       ::= '"' [^"]* '"'
command          ::= '"' [^"]* '"'
path             ::= '"' [^"]* '"'
target_name      ::= '"' [^"]* '"'
```


### **5.2 Syntactic Grammar**


```
program          ::= (statement | comment | newline)*
statement        ::= define_statement
                   | makefile_statement
                   | copy_statement
                   | move_statement
                   | delete_statement

define_statement ::= 'define' target_name 'execute' '=' command
makefile_statement ::= 'makefile' path
copy_statement   ::= 'copyfile' path path
move_statement   ::= 'movefile' path path
delete_statement ::= 'deletefile' path
```


### **5.3 Valid Token Examples**


```
; Valid target names
"build"
"test"
"my-app"
"build_project"
"clean-all"

; Valid commands
"gcc -Wall -O2 main.c"
"python tests/run.py --verbose"
"rm -rf build/ *.o"
"echo 'Hello World'"

; Valid paths
"config.json"
"build/"
"assets/*"
"src/main.c"
"../output/"
```


---

## **6. Advanced Features**

### **6.1 Target Chaining**

Chain multiple targets together:

vub

```
; Define individual targets
define "build" execute = "gcc main.c -o app"
define "test" execute = "python tests.py"
define "run" execute = "./app"

; Define chain
define "all" execute = "build test run"
```


### **6.2 Command-Line Chaining**

Chain targets from CLI:

bash

```
./forge.vub build -test -run -docs
```


### **6.3 Environment Variables**

Commands run in the current shell environment:

vub

```
; Use environment variables
define "build" execute = "$CC -Wall $CFLAGS main.c -o $OUTPUT"
```


### **6.4 Wildcard Support**

File operations support glob patterns:

vub

```
copyfile "src/*.c" "build/"
copyfile "assets/images/*.png" "dist/images/"
deletefile "logs/*.log"
```


---

## **7. Best Practices**

### **7.1 Project Structure**


```
project/
├── forge.vub          # Main build file
├── src/               # Source code
├── build/             # Build artifacts
├── tests/             # Test files
└── README.md          # Documentation
```


### **7.2 Recommended Targets**

| **Target** | **Purpose** |
|---|---|

| `build`           | Build the project               |
| `clean`           | Remove build artifacts          |
| `test`            | Run tests                       |
| `run`             | Execute the program             |
| `install`         | Install the program             |
| `docs`            | Generate documentation          |
| `all`             | Build everything (dependencies) |
| `default`         | Default target (build)          |

### **7.3 Example Project Config**

vub

```
; Project: MyApp - C++ Application

; Build configuration
makefile "build"

; Build targets
define "build" execute = "g++ -std=c++17 -O2 src/*.cpp -o myapp"
define "debug" execute = "g++ -std=c++17 -g -O0 src/*.cpp -o myapp"
define "clean" execute = "rm -rf build/ *.o myapp *.log"
define "test" execute = "ctest --output-on-failure"
define "run" execute = "./myapp"
define "docs" execute = "doxygen Doxyfile"

; File operations
copyfile "config/default.json" "build/config.json"
copyfile "assets/*" "build/assets/"

; Dependencies
define "all" execute = "build test docs"
define "deploy" execute = "build test run"

; Default
define "default" execute = "build"
```


---

## **8. Error Messages**

### **8.1 Target Errors**


```
Error: Target 'build' not found
Try: ./forge.vub --list
```


### **8.2 Syntax Errors**


```
Error: Missing quote in target definition
Syntax: define "name" execute = "command"
```


### **8.3 Command Errors**


```
Error executing command: gcc main.c -o myapp
Command failed with exit code: 1
```


### **8.4 File Operation Errors**


```
Error copying file: config.json -> build/config.json
File not found: config.json
```


---

## **9. Implementation Details**

### **9.1 Interpreter Requirements**

- Python 3.6+
- Standard library modules: `os`, `sys`, `re`, `shutil`, `subprocess`, `pathlib`, `glob`

### **9.2 File Encoding**

- UTF-8 encoding
- Unix (LF) line endings recommended
- Windows (CRLF) line endings supported

### **9.3 Execution Permissions**

- File must be executable: `chmod +x forge.vub`
- Or run with: `python3 forge.vub`

### **9.4 Exit Codes**

| **Code** | **Meaning** |
|---|---|

| 0               | Success                  |
| 1               | General error            |
| 2               | Target not found         |
| 3               | Command execution failed |

---

## **10. Future Extensions**

### **10.1 Planned Features**

- Parallel target execution
- Conditional execution
- Loop support for file operations
- Plugin system
- Remote execution
- Docker support
- Colorized output
- Progress indicators

### **10.2 Backward Compatibility**

- All existing syntax will continue to work
- New features will be additive
- Deprecation warnings for obsolete features

---

## **11. Examples**

### **11.1 C Project**

vub

```
; C Project Build
makefile "build"

define "build" execute = "gcc -Wall -Wextra -O2 src/*.c -o myapp"
define "debug" execute = "gcc -Wall -Wextra -g -O0 src/*.c -o myapp"
define "clean" execute = "rm -rf build/ *.o myapp"
define "run" execute = "./myapp"
define "test" execute = "tests/run_tests.sh"

copyfile "config/*" "build/config/"
define "all" execute = "build test"
define "default" execute = "build"
```


### **11.2 Python Project**

vub

```
; Python Project Build
define "install" execute = "pip install -r requirements.txt"
define "test" execute = "pytest tests/"
define "lint" execute = "pylint src/"
define "format" execute = "black src/ tests/"
define "typecheck" execute = "mypy src/"
define "build" execute = "python setup.py sdist bdist_wheel"
define "clean" execute = "rm -rf build/ dist/ *.egg-info"

copyfile ".env.example" ".env"
define "default" execute = "install"
```


### **11.3 Web Project**

vub

```
; Web Project Build
define "install" execute = "npm install"
define "build" execute = "npm run build"
define "serve" execute = "npm run serve"
define "test" execute = "npm test"
define "deploy" execute = "npm run deploy"
define "clean" execute = "rm -rf node_modules/ dist/"

copyfile ".env.example" ".env"
define "all" execute = "install build test"
define "default" execute = "build"
```


---

## **12. Version History**

| **Version** | **Date** | **Changes** |
|---|---|---|

| 1.0                    | 2024 | Initial specification |

---

## **13. License**

Propeitary

---

**End of Specification**
