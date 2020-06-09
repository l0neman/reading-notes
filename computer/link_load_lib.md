# 程序员的自我修养 - 链接、装载与库

# 第 1 部分简介

## 第 1 章 温故而知新

- 1.3 万变不离其宗

总线（BUS）

南桥（Southbridge）芯片用于连接低速设备，例如：磁盘、USB、键盘、鼠标等。

北桥（Northbridge，PCI Bridge）芯片用于连接所有高速设备，包括 CPU、内存和 PCI 总线。

对称多处理器（SMP，Symmetrical Multi-Processing），就是每个 CPU 在系统中所处的地位和所发挥的功能是一样的，是相互对称的。

多核处理器（Multi-core Processor），将多个处理器打包，以一个处理器的外包装进行出售，处理器之间缓存部件，只保留多个核心。



- 1.4 站得高，看得远

> 计算机科学领域的任何一个问题都可以通过增加一个间接的中间层来解决。
> Any problem in computer science can be solved by another layer of indirection.

接口（Interface），每个层次之间通信的协议。

开发工具和应用程序属于同一个层次，它们都使用应用程序编程接口（Application Program Interface）。

运行库使用操作系统提供的系统调用接口（System call Interface），系统调用接口在现实中往往以软件中断（Software Inerrupt）的方式提供。

硬件规格（Hardware Specification），指驱动程序如可操作硬件，如何与硬件进行通信。



- 操作系统

1. 多道程序（Multiprogramming），当某个程序无需使用 CPU 时，监控程序就把另外正在等待 CPU 资源的程序启动，使得 CPU 能够充分利用起来。
2. 分时系统（Time-Sharing System），每个程序运行一段时间以后都主动让出 CPU 给其他程序，使得一段时间内每个程序都有机会运行一小段时间。
3. 多任务系统（Multi-tasking System），所有程序都以进程的方式运作。

抢占式（Preemptive）



- 1.5 内存不够怎么办

如何将计算机有限的物理内存分配给多个程序使用？

简单分配，1-10MB 分配给 A 程序，10-100MB 分配给 B 程序。

1. 地址空间不隔离
2. 内存使用效率低
3. 程序运行的地址不确定

解决方法，增加中间层，把程序给出的地址看作一种虚拟地址（Virtual Address）



- 分段（Segmentation）

把一段与程序所需要的内存空间大小的虚拟空间映射到某一个地址空间。



- 分页（Paging）

把地址空间人为地等分成固定大小的页，每一页的大小由硬件决定，或硬件支持多种大小的页，由操作系统决定页的大小。

虚拟空间的页叫做虚拟页（VP，Virtual Page），物理内存中的页叫做物理页（PP，Physical Page），把磁盘中的页叫做磁盘页（DP，Disk Page）。

当进程访问对应的页不在内存中时，硬件会捕获到这个消息，就是页错误（Page Fault）。

虚拟存储硬件支持，几乎所有的硬件都采用 MMU（Memory Management Unit）部件进行页映射。通常 MMU 都集成在 CPU 内部，不会以单独的形式出现。

```
[ CPU ] -> Virtual Address -> [ MMU ] -> Physical Address -> [ Physical Memory ]
```



- 众人拾柴火焰高

线程：

线程（Thread），或被称为轻量级进程（Lightweight Process LWP），是程序执行流的最小单元。一个标准的线程由线程 ID、当前指令指针（PC），寄存器集合和堆栈组成。



线程私有存储空间：

1. 栈（并非完全无法被其他线程访问，一般情况下可视为私有）；
2. 线程局部存储（Thread Local Storage，TLS）；
3. 寄存器（包括 PC 寄存器），寄存器时执行流的基本数据，因此为线程私有。

不断在处理器上切换不同线程的行为成为线程调度（Thread Schedule）



线程通常处于三种状态：

1. 运行（Running）：此时线程正在执行；
2. 就绪（Ready）：此时线程可以立刻运行，但 CPU 已被占用；
3. 等待（Waiting）：此时线程正在等待某一事件（通常是 I/O 或同步）发生，无法执行。

```
         无法运行，且线程被选中
        /                      \
       V                        \  
[ Running ] ----------------> [ Ready ]
       \       时间片用尽       ^
        \                      / 
开始等待 \                    /  等待结束
          +>    [ Wait ]   -+
```



调度方式：

1. 优先级调度（Priority Schedule）；
2. 轮转法（Round Robin）



线程优先级（Thread Priority）



IO 密集型（IO Bound Thread），频繁等待的线程。

CPU 密集型（CPU Bound Thread），很少等待的线程。

在优先级调度下，线程存在被饿死（Starvation）的现象。



线程优先级改变方式：

1. 用户指定优先级；
2. 根据进入等待状态的频繁程度提升或降低优先级；
3. 长时间得不到执行而被提升优先级。

抢占（Preemption），线程在用尽时间片之后会被强制剥夺继续执行的权力，进行就绪状态，即之后别的线程抢占了当前线程。



- Linux 线程

Linux 中不存在线程的概念，Linux 将所有执行实体（无论是线程或进程）都成为任务（Task），每个任务概念上都类似于一个单线程的进程，具有内存空间、执行实体、文件资源等。

Linux 创建新任务方式：

| 系统调用 | 作用                                 |
| -------- | ------------------------------------ |
| fork     | 复制当前进程                         |
| exec     | 使用新的可执行映像覆盖当前可执行映像 |
| clone    | 创建子进程并从指定位置开始执行       |

fork 使用写时复制（Copy on Write，COW）的内存空间，能以较快速度产生新任务。



- 线程安全

单指令操作被称为原子的（Atomic）



可重入函数：

1. 不使用任何（局部）静态或全局的非 const 变量；
2. 不返回任何（局部）静态或全局的非 const 变量的指针；
3. 仅依赖于调用方提供的参数；
4. 不依赖任何单个资源的锁；
5. 不调用任何不可重入的函数。



线程模型：

1. 一对一，一个用户线程对应一个内核线程；
2. 多对一，多个用户线程映射到一个内核线程上；
3. 多对多，多个用户线程映射到多个内核线程上；



# 第 2 部分 静态链接

## 第 2 章 编译和链接

```c
// hello.c
#include <stdio.h>

int main()
{
  printf("Hello World\n");
  return 0;
}
```

```shell
$ gcc hello.c
$ ./a.out
Hello World
```



### 2.1 被隐藏的过程

编译过程：

预处理（PrePressing）、编译（Compilation）、汇编（Assembly）和链接（Linking）。

```
[ Source Code ] \ 
hello.c          \
                  >-> [ Prepressing ] -> [ Preprocessed ] -> [ Compilation ]
                 /      (cpp)              hello.i             gcc
[ Hearder Files ]                                               |
studio.h                                                        |
...                                                             |
                                                                v
[ Static Library ] <- [ Object File ] <- [ Assembly ] <- [ Assembly ]
  libc.a                hello.o            (as)            hello.s
  ...              /
      \           v
       -> [ Linking ] -> [ Executable]
            (ld)           a.out
```



- 预处理

```shell
$ gcc -E hello.c -o hello.i
or:
$ cpp hello.c > hello.i
```

预编译过程主要处理哪些源代码文件中以“#”开头的预编译指令。

预编译处理过程：

1. 将所有的“#define”删除，并展开所有宏定义；
2. 处理所有条件预编译指令，如“#if”、“#elif”、“#elde”、“#endif”；
3. 处理“#include”预编译指令，将被包含的文件插入到该预编译指令的位置。注意，这个过程是递归进行的，也就是说被包含的文件可能还包含其他文件；
4. 删除所有的“//”和“/**/”；
5. 添加行号和文件名标识，比如 #2“hello.c”2，以便于编译时编译器产生调试用的行号信息及用于编译时产生编译错误或警告时能够显示行号；
6. 保留所有 #pragma 编译器指令，因为编译器需要使用它们。



- 编译

编译过程就是把预处理完的文件进行一系列词法分析、语法分析、语义分析及优化后产生相应的汇编文件。

```shell
$ gcc -S hello.i -o hello.s
or
$ gcc -S hello.c -o hello.s
```

gcc 是编译器套件，根据不同参数要求去调用预编译程序 cc1、汇编器 as、连接器 ld。



- 汇编

汇编器将汇编代码转变成机器可以执行的指令，每一个汇编语句几乎对应一条机器指令。

```shell
$ as hello.s -o hello.o
or:
$ gcc -c hello.s -o hello.o
or:
$ gcc -c hello.c -o hello.o
```



- 链接

。。。



### 2.2 编译器做了什么

编译过程：

```
[ Source Code ] -> Scanner -> [ Tokens ] -> Parser -> [ Stnax Tree ]
                                                            v
                                                      Semantic Analyzer
                                                            v
[ Intermediate- ] <- Soure Code Optimizer <- [ Commented Syntax Tree ]
  Representation
      v
 Code Generator
      v
[ Target Code] -> Code Optimizer -> [ Final Target Code ]
```



1. 词法分析

源代码首先被输入扫描器（Scanner），运用类似于有限状态机（Finite State Machine）的算法可以轻松地将源代码的字符序列分割成一系列的记号（Token）。

记号一般分为：关键字、标识符、字面量（数字、字符串等）和特殊符号（加号、等号）。

lex 程序可以实现词法扫描。



2. 语法分析

语法分析器（Grammar Parser）将对由扫描器产生的记号进行语法分析，产生语法树（Syntax Tree）。整个过程采用了上下文无关语法（Context-free Grammar）的分析手段。

语法树是以表达式（Expression）为节点的树。

yacc（Yet Another Compiler Compiler）程序可用于词法分析。



3. 语义分析

语义分析器（Semantic Analyzer）对表达式做静态语义（Static Semantic，在编译期确定的语义）分析，不了解这个语句是否有意义。

动态语义（Dynamic Semantic）指在运行期才能确定的语义。



4. 中间语言生成

源码级优化器（Source Code Optimizer）将整个语法树转换成中间代码（Intermediate Code）

中间代码类型：三地址码（Threr-address Code）和 P-代码（P-Code）。

最基本的三地址码：`x = y op z`



5. 目标代码生成与优化

源代码级优化器产生中间代码标志着下面的过程都属于编辑器后端。后端主要包括代码生成器（Code Generator）和目标代码优化器（Target Code Optimizer）。

示例代码序列：

```assembly
movl index, %ecx            ; value of index to ecx
addl $4, %ecx               ; ecx = ecx + 4
mull $8, %ecx               ; ecx = ecx * 8
movl index, %eax            ; value of index to eax
movl %ecx, array(, eax, 4)  ; array[index] = ecx
```

目标代码优化器可能采用合适的寻址方式、使用位移来代替乘法运算、删除多余的指令等。

上述示例代码乘法由一条基址比例变址寻址（Base Index Scale Addressing）的 lea 指令完成，随后由 mov 指令完成赋值操作。

源代码此时被便衣成为目标代码，但是 index 和 array 的地址还未确定。



### 链接器

重新计算各个目标的地址的过程被叫做重定位（Relocation）。



### 静态链接

链接（Linking）过程主要包括地址空间分配（Address and Storage Allocation）、符号决议（Synmbol Resolution）和重定位（Relocation）等。

运行时库（Runtime Library），它是支持程序运行的基本函数的集合。就是一些最常用的代码编译成目标文件后打包存放。

对地址的修正过程叫做重定位（Relocation），每一个要修正的地方叫一个重定位入口（Relocation Entry）



## 第 3 章 目标文件里有什么

### 3.1 目标文件的格式

PC 平台主流的可执行文件格式（Executable），主要是 Windows 下的 PE（Portable Execuable）和 Linux 的 ELF（Executable Linkable Format），它们都是 COFF（Common file format）格式的变种。

目标文件就是源代码编译后但未未进行链接的那些中间问题（Windows 的 .obj 和 Linux 下的 .o）。

可以广义的将目标文件和可执行文件看作同一类型的文件，Windows 下，统称它们为 PE-COFF 文件格式。Linux 下，可统称为 ELF 文件。还有不太常见的 Intel/Microsoft 的 OMF（Object Module Format）、Unix a.out 格式和 MS-DOS.COM 格式等。

动态链接库（DLL，Dynamic Linking Library）（Windows 的 .dll 和 Linux 的 .so）以及静态链接库（Static Linking Library）（Windows 的 .lib 和 Linux 的 .a）文件都按照可执行文件格式存储。

| ELF 文件类型 | 说明 | 实例 |
| ----------- | ---- | ---- |
| 可重定位文件（Relocatable File）| 这类文件包含了代码和数据，可以被用来链接成可执行文件或共享目标文件，静态链接库也可以归为这一类 | Linux 的 .o；Windows 的 .obj |
| 共享目标文件（Shared Object File） | 这种文件包含了代码和数据，可以在以下两种情况中使用，一种是链接器可以使用这种文件跟其他的可重定位文件和共享目标文件链接，产生新的目标文件，第二种是动态连接器可以将几个这种共享目标文件与可执行文件结合，作为进程映像的一部分来运行 | Linux 的 .so，如 /lib/glibc-2.5.so，Windows 的 DLL |
| 核心转储文件（Core Dump File） | 当进程意外终止时，系统可以将该进程的地址空间的内容及终止时的一些其他信息转储到核心转储文件 | Linux 下的 Core Dump |



### 3.2 目标文件是什么样的？

除了代码和数据以外，目标文件中还包括了链接时所需要的一些信息，比如符号表、调试信息、字符串等。
一般目标文件将这些信息按不同的属性，以节（Section），或者叫段（Segment）的形式存储。

程序源代码编译后的机器指令经常被放在代码段（Code Section）中，常见段名为“.code”或“.text”；全局变量和局部静态变量数据经常放在数据段（Data Section），一般名叫“.data”


程序编译成目标文件的示例示例：

```c
// C code with various storage classes             Executable File/Object File
                                                   ---------------------------
int global_ini_var= 84; ---+                               File Header
int globa_uninit_var;+      \                      ---------------------------
                      \  +---\---------------+->          .text section
void func(int i)       \/     \              |     ---------------------------
{                      /\      +-------------|->          .data section 
  printf("%d\n", i); -+  \     |             |     ---------------------------
}                         +----|----+--------|->          .bss section
                               |   /         |     ---------------------------
int main(void)                 |  /          |
{                             /  /           |
  static int static_var = 85;+  /            |
  static int static_var2;  ----+             |
                                             |
  int a = 1;                                 |
  int b;                                     |
  func1(static_var + static_var2 + a + b); --+
  return 0;
}
```

ELF 文件的开头是一个“文件头”，它描述了整个文件的属性，包括文件是否可执行、是静态链接还是动态链接以及入口地址（如果是可执行文件）、目标硬件、目标操作系统等信息。

文件头还包括一个段表（Section Table），段表其实是一个描述文件中各个段的数组，它描述了各个段在文件中的偏移位置及段的属性等。

.bss 段只是为未初始化的全局变量和局部静态变量预留位置而已，并没有内容，不占空间。

BSS（Bloack Started by Symbol）

总体来说，程序源代码被编译后主要分成代码段和数据段。

> 真正了不起的程序员对自己的程序的每一个字节都了如指掌 ——佚名



简单查看 object 文件结构：

```shell
$ objectdump -h SimpleSection.o
```

额外段：只读数据段（.rodata）、注释信息段（.comment）和堆栈提示段（.note.GNU-stack）。

size 命令查看 ELF 文件的代码段、数据段和 BSS 段的长度（dec 为十进制，hex 为十六进制）。

```shell
$ size SimpleSection.o
```


- 代码段

使用 objdump -s 以十六进制打印所有段的内容，-d 对包含指令的段进行返汇编。

```shell
$ objdump -s -d SimpleSection.o
```



- 数据段和只读数据段

.data 段保存的是那些已经初始化了的全局变量和局部静态变量。

查看字符串常量的存放情况：

```shell
$ objdump -x -s -d SimpleSection.o
```

字节序（Bye Order）：大端（Big-endian）和小端（Little-endian）



- .bss 段

.bss 段存放的是未初始化的全局变量和局部晶态变量。

符号表（Symbol Table）



- 其他段

常用段名

| 常用的段名 | 说明 |
| ---------- | ---- |
| .rodata1   | Read only Data，这种段里存放的只是只读数据，比如字符串常量、全局 const 变量。跟 .rodata 一样 |
| .comment | 存放的是编译器版本信息，例如“GCC:(GNU)4.2.0” |
| .debug | 调试信息 |
| .dynamic | 动态链接信息 |
| .hash | 符号哈希表 |
| .line | 调试时的行号表，即源代码与行号与编译后指令的对应表 |
| .note | 额外的编译器信息。比如程序的公司名，发布版本号等 |
| .strtab | String Table 字符串表，用于存储 ELF 文中用到的各种字符串 |
| .symtab | Symbol Table 符号表 |
| .shstrtab | Section String Table 段名表 |
| .plt .got | 动态链接的跳转表和全局入口表 |
| .init .fini | 程序初始化与终结代码段 |



指定代码放置到指定段（GCC 提供支持）：

```c
__attribute__((section("FOO"))) int global = 42;
__attribute__((section("BAR"))) void foo() {}
```


### 3.4 ELF 文件结构描述

ELF 目标文件格式的最前部是 ELF 文件头（ELF Header），它描述了整个文件的基本属性，比如 ELF 文件版本、目标机器型号、程序入口地址等，ELF 文件中与段有关的从要结构是段表（Section Header Table）。



- 文件头

使用 readelf 工具查看文件头：

```shell
$ readelf -h SimpleSection.o
```

ELF 文件头中定义了 ELF 魔数、文件机器字节长度、数据存储方式、版本、运行平台、ABI 版本、ELF 重定位类型、硬件平台、硬件平台版本、入口地址、程序头入口和长度、段表的位置和长度及段的数量等。

ELF 文件头结构及相关常数被定义在“/usr/include/elf.h”中。

ELF 文件有 32 位版本和 64 位版本，描述结构的前缀为 Elf32 和 Elf64。

```c
// /usr/include/elf.h

#define EI_NIDENT (16)

typedef struct
{
  unsigned char e_ident[EI_NIDENT];     /* Magic number and other info */
  Elf32_Half    e_type;                 /* Object file type */
  Elf32_Half    e_machine;              /* Architecture */
  Elf32_Word    e_version;              /* Object file version */
  Elf32_Addr    e_entry;                /* Entry point virtual address */
  Elf32_Off     e_phoff;                /* Program header table file offset */
  Elf32_Off     e_shoff;                /* Section header table file offset */
  Elf32_Word    e_flags;                /* Processor-specific flags */
  Elf32_Half    e_ehsize;               /* ELF header size in bytes */
  Elf32_Half    e_phentsize;            /* Program header table entry size */
  Elf32_Half    e_phnum;                /* Program header table entry count */
  Elf32_Half    e_shentsize;            /* Section header table entry size */
  Elf32_Half    e_shnum;                /* Section header table entry count */
  Elf32_Half    e_shstrndx;             /* Section header string table index */
} Elf32_Ehdr;
```

ELF 文件头结构成员含义

| 成员        | readelf 输出结果与含义                                       |
| ----------- | ------------------------------------------------------------ |
| e_ident     | Magic:           7f 45 4c 46 01 01 01 00 00 00 00 00 00 00 00 00<br />Class:            ELF32<br />Data:             2's complement, little endian<br />Version:        1(current)<br />OS/ABI:         UNIX - System V<br />ABI Version: 0 |
| e_type      | Type: REL(Relocatable file)<br />ELF 文件类型                |
| e_machine   | Machine: Intel 80836<br />ELF 文件的 CPU 平台属性，相关常量以 EM_ 开头 |
| e_version   | Version: 0x1<br />ELF 版本号。一般为常数 1                   |
| e_entry     | Entry point address: 0x0<br />入口地址，规定 ELF 程序的入口虚拟地址，操作系统在加载完该程序后从这个地址开始执行进程的指令。可重定位文件一般没有入口地址，这个值为 0 |
| e_phoff     | Start of program header: 0(bytes)                            |
| e_shoff     | Start of section headers: 280(bytes into file)<br />段表在文件中的偏移， |
| e_word      | Flags: 0x0<br />ELF 标志位，用来标识一些 ELF 文件平台相关的属性。相关常量格式一般为 EF_machine_flag，machine 为平台，flag 为标志 |
| e_ehsize    | Size of this header: 52(bytes)<br />即 ELF 文件头本身的大小  |
| e_phentsize | Size of program headers: {}(bytes)                           |
| e_phnum     | Number of program headers: ()                                |
| e_shentsize | Size of section headers: 40(bytes)<br />段表描述符的大小，这个一般等于一节 |
| e_shnum     | Number of section headers: 11<br />段表描述符数量。这个值等于 ELF 文件中拥有段的数量 |
| e_shstrndx  | Section header string table index: 8<br />段表字符串表所在的段在段表中的下标 |



- ELF 魔数

最前面的 Magic 的 16 个字节刚好对应“Elf32_Endr”的 e_ident 这个成员。

第一个字节 0x46 对应 ASCII 字符里面的 DEL 控制符，后面 3 个字节正好对应“ELF” 3 个字符。

```
7f 45 4c 46 01 01 01 00 00 00 00 00 00 00 00 00
^  ^  ^  ^   ^  ^
  "E  L  F"  |  |
            /    \
[ ELF 文件类型 ]  [ 字节序 ]
0 无效文件        0 无效格式
1 32 位 ELF 文件  1 小端格式
2 64 位 ELF 文件  2 大端格式
```



- 文件类型

e_type 成员表示 ELF 文件类型，系统通过这个常量来判断 ELF 文件类型，而不是文件扩展名。

| 常量 | 值 | 含义 |
| ---- | -- | ---- |
| ET_REL | 1 | 可重定位文件，一般为 .o 文件 |
| ET_EXEC | 2 | 可执行文件 |
| ET_DYN | 3 | 共享目标文件，一般为 .so 文件 |



- 机器类型

ELF 文件被设计成可以在多个平台下使用，但并不表示同一个 ELF 文件可以在不同的平台下使用，而是表示不同平台下的 ELF 文件都遵循同一套 ELF 标准。e_machine 成员就表示该属性。

相关常量以“EM”开头：

| 常量     | 值 | 含义           |
| -------- | -- | -------------  |
| EM_M32   | 1  | AT&T WE 32100  |
| EM_SPARC | 2  | SPARC          |
| EM_386   | 3  | Intel x86      |
| EM_68K   | 4  | Motorola 68000 |
| EM_88K   | 5  | Motorola 88000 |
| EM_860   | 6  | Intel 80860    |



- 段表

段表（Section Header Table）描述了各个段的信息，比如每个段的段名、段的长度、在文件中的偏移、读写权限及段的其他属性。

编译器、链接器和装载器都是依靠段表来定位和访问各个段的属性的。段表在 ELF 文件头的位置由“e_shoff”成员决定。

查看段表：

```shell
$ readelf -S SimpleSection.o
```

段表是一个以“Elf32_Shdr”结构体为元素的数组。

每一个“Elf32_Shdr”结构体对应一个段。“Elf32_Shdr”又被称为段描述符（Section Descriptor）。



Elf32_Shdr 段描述符结构：

```c
// /usr/include/elf.h

/* Section header.  */

typedef struct
{
  Elf32_Word    sh_name;                /* Section name (string tbl index) */
  Elf32_Word    sh_type;                /* Section type */
  Elf32_Word    sh_flags;               /* Section flags */
  Elf32_Addr    sh_addr;                /* Section virtual addr at execution */
  Elf32_Off     sh_offset;              /* Section file offset */
  Elf32_Word    sh_size;                /* Section size in bytes */
  Elf32_Word    sh_link;                /* Link to another section */
  Elf32_Word    sh_info;                /* Additional section information */
  Elf32_Word    sh_addralign;           /* Section alignment */
  Elf32_Word    sh_entsize;             /* Entry size if section holds table */
} Elf32_Shdr;
```



Elf32_Shdr 各个成员的含义：

| 成员               | 含义                                                         |
| ------------------ | ------------------------------------------------------------ |
| sh_name            | Section name 段名<br />段名是个字符串，它位于一个叫做“.shstrtab”的字符串表。sh_name 是段名在“.shstrtab”中的偏移 |
| sh_tpe             | Section type 段的类型                                        |
| sh_flags           | Section flag 段的标志                                        |
| sh_addr            | Section Address 段虚拟地址<br />如果该段可以被加载，这 sh_addr 为该段被加载后在进程地址空间中的地址；否未 sh_addr 为 0 |
| sh_offset          | Section Offset 段偏移<br />如果该段存在于文件中，则表示该段在文件中的偏移；否则无意义。比如对 BSS 段来说 |
| sh_size            | Section Size 段的长度                                        |
| sh_link 和 sh_info | Section Link and Section Information 段链接信息              |
| sh_addralign       | Section Address Alignment 段地址对齐<br />有些段对段地址对齐有要求，比如有个段刚开始的位置包含一个 double 变量,因为 Inel x86 系统要求浮点数的存储地址必须是本身的整数倍，也就是说保存 double 变量的地址必须是 8 字节的整数倍。这样一来对于一个段来说，它的 sh_addr 必须是 8 的整数倍。<br />由于地址对齐的数量都是 2 的整数倍，sh_addralign 表示是地址对齐数量中的指数，即 sh_addrlign = 3 表示对齐为 2 的 3 次方倍，即 8 倍，依次类推，所以一个段的地址 sh_addr 必须满足下面的条件：sh_addr % (2 ** sh_addralign) = 0。** 表示指数运算。<br />如果 sh_addralign 为 0 或 1，则表示该段没有对齐要求。 |
| sh_entsize         | Section Entry Size 项的长度<br />有些段包含了一些固定大小的项，比如符号表，它包含的每个符号所占的大小都是一样的，对于这种段，sh_entsize 表示每个项的大小。如果为 0，则表示该段不包含固定大小的项。 |



- 段的类型（sh_type）

段的名字只是在编译和链接过程中有意义，不能真正表示段的类型。

决定段的属性和类型的是段的类型（sh_type）和段的属性（sh_flag）。

| 常量         | 值 | 含义                                   |
| SHT_NULL     | 0  | 无效段                                 |
| SHT_PROGBITS | 1  | 程序段、代码段、数据段都是这种类型     |
| SHT_SYMTAB   | 2  | 表示该段的内容为符号表                 |
| SHT_STRTAB   | 3  | 表示该段的内容为字符串表               |
| SHT_RELA     | 4  | 重定位表，该段包含了重定位信息         |
| SHT_HASH     | 5  | 符号表的哈希表                         |
| SHT_DYNAMIC  | 6  | 动态链接信息                           |
| SHT_NOTE     | 7  | 提示性信息                             |
| SHT_NOBITS   | 8  | 表示该段在文件中没有内容，比如 .bss 段 |
| SHT_REL      | 9  | 该段包含了重定位信息                   |
| SHT_SHLIB    | 10 | 保留                                   |
| SHT_DNYSYM   | 11 | 动态链接的符号表                       |



- 段的标志位（sh_flag）

段的标志位表示该段在进程虚拟地址空间中的属性，比如是否可写，是否可执行等。

| 常量          | 值 | 含义 |
| SHF_WRITE     | 1  | 表示该段在进程空间中可写 |
| SHF_ALLOC     | 2  | 表示该段在进程空间中需要分配空间。有些包含指示或者控制信息的段不需要在进程空间中被分配空间，它们一般不会有这个标志。像代码段、数据段和 .bss 段一般都会有这个标志位 |
| SHF_EXECINSTR | 4  | 表示该段在进程空间中可以被执行,一般指代码段 |

系统保留段相关属性：

| Name      | sh_type      | sh_flags                                                     |
| --------- | ------------ | ------------------------------------------------------------ |
| .bss      | SHT_NOBITS   | SHF_ALLOC + SHF_WRITE                                        |
| .comment  | SHT_PROGBITS | none                                                         |
| .data     | SHT_PROGBITS | SHF_ALLOC + SHF_WRITE                                        |
| .data1    | SHT_PROGBITS | SHF_ALLOC + SHF_WRITE                                        |
| .debug    | SHT_PROGBITS | none                                                         |
| .dynamic  | SHT_DYNAMIC  | SHF_ALLOC + SHF_WRITE<br />有些系统下 .dynamic 段可能是只读的，所以没有 SHF_WRITE 标志位 |
| .hash     | SHT_HASH     | SHF_ALLOC                                                    |
| .line     | SHT_PROGBITS | none                                                         |
| .note     | SHT_NOTE     | none                                                         |
| .rodata   | SHT_PROGBITS | SHF_ALLOC                                                    |
| .rodata1  | SHT_PROGBITS | SHF_ALLOC                                                    |
| .shstrtab | SHT_STRTAB   | none                                                         |
| .strtab   | SHT_STRTAB   | 如果该 ELF 文件中有可装载的段需要用到该字符串表，那么字符串表也将被装载的到内存空间，则有 SHF_ALLOC 标志位 |
| .symtab   | SHT_SYMTAB   | 同字符串表                                                   |
| .text     | SHT_PROGBITS | SHF_ALLOC + SHF_WRITE                                        |



- 段的链接信息（sh_link、sh_info）

段的类型必须是链接相关的（动态或静态），比如重定位表、符号表等。否则这两个成员无意义。

| sh_type                    | sh_link                              | sh_info                            |
| -------------------------- | ------------------------------------ | ---------------------------------- |
| SHT_DYNAMIC                | 该段所使用的字符串表在段表中的下标   | 0                                  |
| SHT_HASH                   | 该段所使用的符号表在段表中的下标     | 0                                  |
| SHT_REL<br />SHT_RELA      | 该段所使用的相应符号表在段表中的下标 | 该重定位表所作用的段在段表中的下标 |
| SHT_SYMTAB<br />SHT_DYNSYM | 操作系统相关的                       | 操作系统相关的                     |
| other                      | SHN_UNDEF                            | 0                                  |



- 重定位表（Relocation Table）

“.rel.text”段的类型是“SHT_REL”，它表示“.text”的重定位表。



- 字符串表（String Table）



### 3.5 链接的接口——符号

目标文件 B 用到了目标文件 A 中的函数“foo”，那么我们就称目标文件 A 定义（Define）了函数“foo”，称目标文件 B 引用（Reference）了目标文件 A 中的函数“foo”。

在链接中，函数和变量统称为符号（Symbol），函数名和变量名就是符号名（Symbol Name）。

每一个目标文件都会有一个相应的符号表（Symbol Table），每一个定义的符号有一个对应的值，叫做符号值（Symbol Value），对于函数和变量来说，就是它们的地址。

符号表中的所有符号分为如下几类：

1. 定义在本目标文件的全局符号，可被其他目标文件引用；
2. 定义在本目标文件的全局符号，却没有定义在目标文件，一般叫做外部符号（External Symbol），也就是符号引用，例如“printf”；
3. 段名，这种符号往往由编译器产生，它的值就是该段的起始地址；
4. 局部符号，这种符号只在编译单元内部可见，对于链接过程没有作用，调试器可以使用这些符号来分析程序或崩溃时的核心转储文件；
5. 行号信息，即目标文件指令与源代码中代码行的对应关系，它也是可选的。



使用“nm”工具查看符号：

```shell
$ nm SimpleSection.o
```


- ELF 符号结构

符号表存在于“.symtab”段中，符号表的结构是一个 Elf32_Sym（32 位 ELF 文件）结构的数组。每个 Elf32_Sym 结构对应一个符号，数组的第一个元素为无效的“未定义”符号。

Elf32_Sym 结构如下：

```c
// /usr/include/elf.h

/* Symbol table entry.  */

typedef struct
{
  Elf32_Word    st_name;                /* Symbol name (string tbl index) */
  Elf32_Addr    st_value;               /* Symbol value */
  Elf32_Word    st_size;                /* Symbol size */
  unsigned char st_info;                /* Symbol type and binding */
  unsigned char st_other;               /* Symbol visibility */
  Elf32_Section st_shndx;               /* Section index */
} Elf32_Sym;
```

成员定义如下：

| 成员     | 含义 |
| -------- | ---- |
| st_name  | 符号名。这个成员包含了该符号名在字符串表中的下标 |
| st_value | 符号相对应的值。这个跟符号有关，可能是一个绝对值，也可能是一个地址等，不同的符号，它所对应的值含义不同 |
| st_size  | 符号大小。对于包含数据的符号，这个值是该数据类型的大小。比如一个 double 类型的符号它占用 8 个字节。如果该值为 0，则表示该符号大小为 0 或未知 |
| st_info  | 符号类型和绑定信息 |
| st_other | 该成员目前为 0，无用 |
| st_shndx | 符号所在段 |



- 符号类型和绑定信息（st_info）

该成员低 4 位表示符号的类型（Symbol Type），高 28 位表示符号绑定信息（Symbol Binding）。

符号绑定信息：

| 宏定义名   | 值 | 说明                               |
| ---------- | -- | ---------------------------------- |
| STB_LOCAL  | 0  | 局部符号，对于目标文件的外部不可见 |
| STB_GLOBAL | 1  | 全局符号，外部可见                 |
| STB_WEAK   | 2  | 弱引用                             |

符号类型：

| 宏定义名    | 值 | 说明 |
| ----------- | -- | ---- |
| STT_NOTYPE  | 0  | 未知类型符号 |
| STT_OBJECT  | 1  | 该符号是一个数据对象，比如变量、数组等 |
| STT_FUNC    | 2  | 该符号是一个函数或其他可执行代码       |
| STT_SECTION | 3  | 该符号表示一个段，这种符号必须是 STB_LOCAL 的 |
| STT_FILE    | 4  | 该符号表示文件名，一般都是该目标文件所对应的源文件名，它一定是 STB_LOCAL 类型的，并且它的 st_shndx 一定是系统 SHN_ABS |



- 符号所在段（st_shndx）

如果符号定义在本目标文件中，那么这个成员表示符号所在的段在段表中的下标，如果符号不是定义在本目标文件中，或者对于有些特殊符号，sh_shndx 的值有些特殊。

符号所在段特殊常量

| 宏定义名   | 值     | 说明 |
| ---------- | ------ | ---- |
| SHN_ABS    | 0xfff1 | 表示该符号包含了一个绝对的值。比如文件名的符号类型就是这种 |
| SHN_COMMON | 0xff2  | 表示该符号是一个“COMMON块”类型的符号，一般来说，未初始化的全局符号定义就是这种类型的，比如 SimpleSection.o 里面的 global_uninit_var |
| SHN_UNDEF  | 0      | 表示该符号未定义，这个符号表示该符号在本目标文件中被引用，但是定义在其他目标文件中 |



- 符号值（st_value）

有如下几种情况：

1. 在目标文件中，如果是符号的定义并且该符号不是“COMMON块”类型的，则表示该符号在段中的偏移。 即符号所对应的变量或函数位于 sh_shndx 指定的段，偏移 st_value 的位置。
2. 在目标文件中，如果符号是“COMMON块”类型的，则 st_value 表示该符号的对齐属性。
3. 在可执行文件中，st_value 表示符号的虚拟地址。这个虚拟地址对于动态链接器十分有用。



使用 readelf 查看符号信息：

```shell
$ readelf -s SimpleSection.o
```



- 特殊符号

当使用 ld 作为链接器来生成可执行文件时，它会为我们定义很多特殊符号，这些符号并没有在你的程序中定义，但是你可以直接声明并引用它们。

例如：

1. __executable_start，该符号为程序起始地址，注意，不是入口地址；
2. __etext 或 _etext 或 etext，该符号为代码段结束地址，即最末尾的地址；
3. _edata 或 edata，该符号为数据段结束地址，即最末尾的地址；
4. \_end 或 end，该符号为程序结束地址。

以上地址都是程序被装载时的虚拟地址。



- 符号修饰与函数签名

命名空间（Namespace）

符号修饰（Name Decoration）或符号改编（Name Mangling）

函数签名（Function Signature）

使用 c++filt 工具解析被修饰后的符号名：

```shell
$ c++filt _ZN1N1C4funcEi
```

由于不同的编译器采用不同的名字修饰方法，必然会导致由不同的编译器编译产生的目标文件无法相互链接，这是导致不同编译器之间不能互操作的主要原因之一。



- extern "C"

C++ 编译器会将在extern “C”的大括号内部的代码当作 C 语言代码处理，

```c
#ifdef __cplusplus
extern "C" {
#endif

void *memset (void *, int, size_t);

#ifdef __cplusplus
}
#endif
```



- 弱符号与强符号

多个目标文件中含有相同名字全局符号的定义时，这些目标文件链接的时候会出现符号重复定义的错误。

这种符号的定义可以被称为强符号（Strong Symbol），有些符号的定义可以被称为弱符号。

对于 C/C++ 语言来说，编译器默认函数和初始化了的全局变量为强符号，为初始化的全局变量为弱符号。

可以通过 GCC 的“__attribute__((weak))”来定义任何一个强符号为弱符号。

链接器按照如下规则处理与选择被多次定义的全局符号：

1. 不允许强符号被多次定义（即不同的目标文件中不能有同名的强符号）；如果定义了多个强符号，则链接器报符号重复定义错误；
2. 如果一个符号在某个目标文件中是强符号，在其他文件中都是弱符号，那么选择强符号；
3. 如果一个符号所在的所有目标文件中都是弱符号，那么选择其中占用空间最大的一个。（尽量不要使用多个不同类型的弱符号，否则很容易导致很难发现的程序错误）。

- 弱引用与强引用

目前对外部目标文件中的符号引用在目标文件被最终链接成可执行文件时，它们必须要被正确决议，如果没有找到该符号的定义，链接器就会报符号未定义错误，这种被称为强引用（Strong Reference）

如果该符号有定义，则链接器将该符号的引用决议；如果该符号未被定义，则链接器对于该引用不报错，会给与其一个默认值 0，或一个特殊的值，以便于程序代码能够识别。

弱符号和弱引用对于库来说十分有用，比如库中定义的弱符号可以被用户定义的强符号所覆盖，从而使得程序可以使用自定义版本的库函数；或者程序可以对某些扩展功能模块的引用定义为弱引用，当我们将扩展模块与程序链接在一起时，功能模块就可以正常使用；去掉了某些功能模块，那么程序也可以正常链接，只是缺少了相应的功能，这使得程序的功能更加容易裁剪和组合。



### 4.6 调试信息

使用 GCC 编译时加 -g 参数，编译器将会在目标文件中加入调试信息。

ELF 文件采用一个叫 DWARF（Debug With Arborary Record Format）的标准的调试信息格式。

ELF 文件中的调试信息往往很大，使用 strip 命令来去除 ELF 文件中的调试信息。

```shell
$ strip foo
```



## 第 4 章 静态链接

链接两个文件。

```sh
$ gcc -c a.c b.c
```

### 4.1 空间与地址分配

- 按序叠加

- 相似段合并

- 两步链接（Two-pass Linking）

1. 空间与地址分配
2. 符号解析与重定位


```shell
$ld a.o b.o -e main -o ab
```

VMA（Virtual Memory Address）虚拟地址

- 符号地址的确定



### 4.2 符号解析与重定位

- 重定位

- 重定位表（Relocation Table）

可被叫做重定位段，例代码段“.text”中如果有要被重定位的地方，那么会有一个相对应的“.rel.text”段保存了代码段的重定位表。

查看重定位表：

```shell
$ objdump -r a.o
```

重定位入口（Relocation Entry）

重定位表结构

```c
// /usr/include/elf.h

/* Relocation table entry without addend (in section of type SHT_REL).  */

typedef struct
{
  Elf32_Addr    r_offset;               /* Address */
  Elf32_Word    r_info;                 /* Relocation type and symbol index */
} Elf32_Rel;
```

| 成员     | 含义                                                         |
| -------- | ------------------------------------------------------------ |
| r_offset | 重定位入口的偏移。对于可重定位文件来说，这个值是该可重定位入口所要修正的位置的第一个字节相对于段起始的偏移；对于可执行文件或共享对象文件来说，这个值是该重定位入口所要修正的位置的第一个字节的虚拟地址。 |
| r_info   | 重定位入口的类型和符号。这个成员的低 8 位表示重定位入口的类型，高 24 位表示重定位入口的符号在符号表中下标。<br />因为各个处理器的指令格式不一样，所以重定位所修正的地址格式也不一样，每种处理器都有自己一套重定位入口的类型，对于可执行文件和共享对象文件来说，它们的重定位入口是动态链接类型的。 |



- 符号解析

x86 基本重定位类型

| 宏定义     | 值 | 重定位修正方法         |
| ---------- | -- | ---------------------- |
| R_386_32   | 1  | 绝对寻址修正方法       |
| R_386_PC32 | 2  | 相对寻址修正 S + A - P |

A = 保存在被修正位置的值
P = 被修正的位置（相对于段开始的偏移量或者虚拟地址），该值可通过 r_offset 计算得到
S = 符号的实际地址，即由 r_infod 的高 24 位指定的符号的实际地址



### 4.3 COMMON 块

COMMON 块（Common Block）的机制，这种机制最早来源于 Fortran，早期的 Fortran 没有动态分配空间的机制，程序员必须事先声明它所需要的临时空间的大小。Fortran 把这种空间叫做 COMMON 块，当不同的目标文件需要的 COMMON 块空间大小不一致时，一最大的那块为准。

现代链接机制在处理弱符号的时候，采用的就是与 COMMON 块一样的机制。

COMMON 机制的还有一个原因是，早期 C 程序员经常忘记声明“extern”关键字，导致多个目标文件中产生同一个变量的定义。

编译器将一个编译单元编译成目标文件的时候，如果该编译单元包含了弱符号，此时该符号的空间大小此时是未知的，因为有可能其他编译单元中该符号所占的空间比本编译单元要大。所以需要在链接阶段确认。

GCC 的“-fno-common”允许我们把未初始化的全局变量不以 COMMON 块的形式处理。

或使用“__attribute__”处理：

```c
int global __attribute__((nocommon));
```



### 4.4 C++ 相关问题

- 重复代码消除

C++ 通常会产生重复的代码，比如模板（Templates）、外部内联函数（Extern Inline Function）和虚函数表（Virtual Function Table）都可能在不同的编译单元里生成相同的代码。

存在如下问题：

1. 空间浪费；
2. 地址交易出错；
3. 指令运行效率较低。

一个方法是把每一个模板的实例代码都单独存放在一个段里，每个段只包含一个模板实例，当别的编译单元实例化同名模板后，会生成同样名字的段，这样链接器最终可以区分这些相同的模板实例段，并将它们合并入最后的代码段。



- 函数级别链接

VISUAL C++  编译器提供了一个编译选项叫函数级别链接（Functional-Level Linking, /Gy），这个选项让所有的函数像模板函数一样，单独保存到一个段里面。

GCC 编译器也提供了类似机制，“-ffunction-sections”和“-fdata-sections”，分别是将函数和变量保持到独立的段中。

这个优化选项可以避免使用任意一个目标文件中的函数或变量时，把整个文件链接起来，减少输出文件长度，减少空间浪费，但会增加编译和链接负担，因为要计算各个函数间的依赖关系，同时重定位过程增加了复杂度。



- 全局构造与析构

ELF 文件中两种特殊的段：

1. .init 该段里面保持了可执行的指令，它构成了进程的初始化代码。因此，当一个程序开始运行时，在 main 函数被调用之前，Glibc 的初始化部分安排执行这个段中的代码。
3. .final 该段保存着进程终止的代码指令。因此，当一个程序的 main 函数正常退出返回时，Glibc 会安排执行这个段中的代码。

利用此特性，可实现 C++ 的全局构造和析构函数。



- C++ 与 ABI

ABI（Application Binary Interface）

影响 C 语言目标文件的二进制兼容相关：

1. 内置类型（int、float、char 等）的大小和在存储器中的放置方式（大端、小端、对齐方式）；
2. 组合方式（struct、union、数组等）的存储方式和内存分布；
3. 外部符号（external-linkage）与用户定义的符号之间的命名方式和解析方式；
4. 函数调用方式，比如参数入栈顺序，返回值如何保持等；
5. 堆栈的分布方式，比如参数和局部变量在堆栈中的位置，参数传递方法等；
6. 寄存器使用约定，函数调用时那些寄存器可以修改，哪些必须要保存等。

C++ 对二进制兼容的额外影响：

1. 继承体系的内存分布，如基类，虚基类在继承类中的位置等；
2. 指向成员函数指针（pointer-to-member）的内存分布，如何通过指向成员函数的指针来调用成员函数，如何传递 this 指针；
3. 如何调用虚函数，vtable 的内容和分布方式，vtable 指针在 object 中的位置等；
4. template 如何实例化；
5. 外部符号的修饰；
6. 全局对象的构造和析构；
7. 异常的产生和捕获机制；
8. 标准库的细节问题，RTTI 如何实现等；
9. 内嵌函数访问细节。



### 4.5 静态库链接

“ar”压缩程序可以将多个目标文件压缩到一起，方便进行文件管理和组织。

查看文件包中有哪些目标文件：

```shell
$ ar -t libc.a
```

Visusl C++ 中也提供了类似 ar 的工具，lib.exe，可创建提取、列举 .lib 文件中的内容，使用“lib /LIST libcmt.lib”可以列举里面的目标文件。



### 4.6 链接过程控制

操作系统内核本质上也是一个程序，比如 Windows 的内核 ntoskrnl.exe 就是一个 PE 文件，它位于 “\WINDOWS\system32\ntoskrnl.exe”

- 链接控制脚本

链接器控制链接的 3 种方法：

1. 使用命令行给链接器指定参数；
2. 将链接指令存放再目标文件里面；
3. 使用链接控制脚本。

各个链接器平台的链接控制过程国不相同，VISUAL C++ 把这种控制脚本叫做模块定义文件（Module-Definition File），扩展名一般为 .def。

查看 ld 的默认链接脚本：

```shell
$ ld -verbose
```

指定控制脚本：

```shell
$ ld -T link.script
```



- 使用 ld 链接脚本

输入文件中的段称为输入段（Input Sections），输出文件中的段成为输出段（Output Sections）。

控制链接过程无非是控制输入段如何变为输出段，比如哪些输入段要合并成一个输出段，哪些输入段要丢弃；指定输出段的名字、装载地址、属性等（一般链接脚本名都以 lds 作为扩展名 ld script）。

```lds
/* TinyHelloWorld.lds */

ENTRY(nomain)

SECTIONS
{
  . = 0x08048000 + SIZEOF_HEADERS;
  tinytext  : { *(.text) *(.data) *(.rodata) }
  /DISCARD/ : { *(.comment) }
}
```



- ld 链接脚本语法简介

链接脚本由一系列语句组成，语句分为两种，一种是命令语句，另一种赋值语句。

以下特点与 C 语言类似：

1. 语句之间使用分号“;”作为分割符，对于命令语句来说也可使用换行符来结束语句；
2. 表达式与运算符，比如+、-、*、/、+=、-=、*=，甚至包括&、|、>>、<< 这些位运算符；
3. 注释和字符引用，使用 /\*\*/ 作为注释。脚本文件中使用到的文件名、格式名或段名等凡包括“;”或其他的分隔符的，都要使用双引号将该名字全称引用起来，如果文件名包含引号，将无法处理。

| 命令语句                                         | 说明                                                         |
| ------------------------------------------------ | ------------------------------------------------------------ |
| ENTRY(symbol)                                    | 指定符号 symbol 的值为入口地址（Entry Point）。入口地址即进程执行的第一条用户空间的指令在进程地址空间的地址，它被指定在 ELF 文件头 Elf32_Ehdr 的 e_entry 成员中。ld 有多种方法可以设置进程入口地址，它们之间的优先级按以下顺序排列（优先级由上至下）：<br />1. ld 命令行的 -e 选项<br />2. 链接脚本的 ENTRY（symbol）命令<br />3. 如果定义了 \_start 符号，使用 _start 符号值<br />4. 如果存在 .text 段，使用 .text 段的第一字节的地址<br />5. 使用值 0 |
| STARTUP(filename)                                | 将文件 filename 作为链接过程中的第一个输入文件               |
| SEARCH_DIR(path)                                 | 将路径 path 加入到 ld 链接器的库查找目录。ld 会根据指定的目录去查找相应的库，跟“-Lpath”命令有着相同的作用 |
| INPUT(file, file, ...)<br />INPUT(file file ...) | 将指定文件作为链接过程中的输入文件                           |
| INCLUDE filename                                 | 将指定文件包含进本链接脚本，类似于 C 语言中的 #include 预处理 |
| PROVIDE(symbol)                                  | 在链接脚本中定义某个符号。该符号可以在程序中被引用。         |



复杂的 SECTIONS 命令：

```lds
SECTIONS
{
  ...
  secname: { contents }
  ...
}
```

secname 表示输出段的段名，secname 后面必须有一个空格符，这样使得输出段名不会有歧义。

contents 描述了一套规则和条件，它表示符合这种条件的输入段将合并到这个输出段中。

有一个特殊的段名叫做“/DISCARD/”，使用它作为输出段名，那么所有符合 contents 规定的段都将被丢弃。

条件的写法如下：

```lds
filename(sectoion)
```

filename 表示输入文件名，sections 表示输入段名，例如：

1. file1.o(.data) 表示文件名中为 file1.o 的文件叫 .data 的段符合条件；
2. file1.o(.data. rodaa)，同上，名叫 .data 和 .rodata 的段符合条件；
3. file1.o 直接指定文件名而省略后面的小括号和段名，表示此文件的所有段符合条件；
4. *(.data) 所有输入文件中的名字为 .data 的文件符合条件；
5. [a-z]*(.text*[A-Z])表示所有输入文件中以小写字母 a 到 z 开头的文件中的所有段以 .text 开头，且以 A 到 Z 结尾的段。



### 4.7 BFD 库

BFD 库（Binary File Descriptor library），目的是通过一种统一的接口来处理不同的目标文件格式。



## 第 5 章 Windows PE/COFF

### 5.1 Windows 的二进制文件格式 PE/COFF

在 32 位的 Windows 平台下，微软引入了一种叫 PE（Protable Executable）的可执行文件格式。

PE 文件格式和 ELF 同根同源，都是由 COFF（Common Object File Format）格式发展而来的。



### 5.2 PE 的前身——COFF

使用 Visual C++ 编译器 cl（cl 是 Compiler 的缩写）：

```cmd
cl /c /Za SimpleSection.c
```

编译后得到一个 SimpleSection.obj 文件。

使用 dimpbin 查看 obj 文件结构：

```cmd
dumpbin /ALL SimpleSection.obj > SimpleSection.txt
```

查看基本信息：

```cmd
dumpbin SimpleSection.obj /SUMMARY
```



- COFF 文件结构

COFF 文件头包括两部分，映像头（Image Header）包含文件总体结构和属性；段表（Section Table）包含段属性和属性的映像头。

映像（Image）：因为 PE 文件在装载的时候被直接映射到进程的虚拟空间执行，它是进程的虚拟空间的映像。所以 PE 可执行文件很多时候被叫做映像文件（Image File）。



- 5.3 链接指示信息

- 5.4 调试信息

- 5.5 大家都有符号表



### 5.6 Windows 下的 ELF——PE

PE 文件是基于 COFF 的扩展，它比 COFF 文件多了几个结构，有两个主要变化：

1. 文件最开始的部分不是 COFF 文件头，而是 DOS MZ 可执行文件格式的文件头和桩代码（DOS MZ File Header and Stub）；
2. 原来的 COFF 文件头中的“IMAGE_FILE_HEADER”部分扩展成了 PE 文件文件头结构“IMAGE_NT_HEADERS”，此结构包括了原来的“Image Header”及新增的 PE 扩展头部结构（PE Optional Header）。



# 第 3 部分 装载与动态链接

## 第 6 章 可执行文件的装载与进程

### 6.1 进程虚拟地址空间

程序（或者狭义上讲可执行文件）是一个静态概念，它就是一些预先编译好的指令和数据集合的一个文件；进程则是一个动态的概念，它是程序运行时的一个过程，很多时候把动态库叫做运行时（Runtime）也有一定的含义。

每个程序被运行起来以后，它将拥有自己独立的虚拟地址空间（Virtual Address Space）。

PAE（Physical Address Extension）

AWE（Address Windowing Extensions）

XMS（eXtended Memory Specification）



### 6.2 装载的方式

覆盖装入（Overlay）和页映射（Paging）是两种很典型的动态装入方法，它们都利用了程序的局部性原理。动态装入的思想是程序是程序用到哪个模块，就将哪个模块装入内存，如果不用就暂时不装入，放在磁盘中。

- 覆盖装入

覆盖管理器（Overlay Manager）

程序员需要手工将模块按照它们之间的调用依赖关系组织成书状结构。

- 页映射



### 6.3 从操作系统角度看可执行文件的装载

- 进程的建立

1. 创建一个独立的虚拟地址空间；
2. 读取可执行文件头，并且建立虚拟空间与可执行文件的映射关系；
3. 将 CPU 的指令寄存器设置成可执行文件的入口地址，启动运行。

虚拟内存区域（VMA，Virtual Memory Area）



- 页错误

页错误（Page Fault）



### 进程虚存空间分布

段的权限:

1. 以代码段为代表的权限为可读可执行的段；
2. 以数据段和 BSS 段为代表的权限为可读可写的段；
3. 以只读数据段为代表的权限为制度的段。

一个简单的方案是：对于相同权限的段，把它们合并到一起当作一个段进行映射。

ELF 中的视图（View），从“Section”的角度来看 ELF 文件就是链接视图（Linking View），从“Segment”的角度来看就是执行视图（Execution View）。

ELF 可执行文件中有一个专门的数据结构叫做程序头表（Program Header Table），用来保存“Segment”的信息。有为 ELF 目标文件不需要被装载，所以它没有程序头表，而 ELF 的可执行文件和共享库文件都有。

```c
// /usr/include/elf.h

/* Program segment header.  */

typedef struct
{
  Elf32_Word    p_type;                 /* Segment type */
  Elf32_Off     p_offset;               /* Segment file offset */
  Elf32_Addr    p_vaddr;                /* Segment virtual address */
  Elf32_Addr    p_paddr;                /* Segment physical address */
  Elf32_Word    p_filesz;               /* Segment size in file */
  Elf32_Word    p_memsz;                /* Segment size in memory */
  Elf32_Word    p_flags;                /* Segment flags */
  Elf32_Word    p_align;                /* Segment alignment */
} Elf32_Phdr;

```

成员说明如下：

| 成员     | 含义                                                         |
| -------- | ------------------------------------------------------------ |
| p_type   | “Segment”类型，“LOAD”类型的常量为 1                          |
| p_offset | “Segment”在文件中的偏移                                      |
| p_vaddr  | “Segment”的第一个字节在虚拟地址空间的起始位置，整个程序表头中，所有“LOAD”类型的元素按照 p_vaddr 从小大到大排列 |
| p_paddr  | “Segment”的物理装载地址，即 LMA（Load Memory Address），一般情况下 p_paddr 和 p_vaddr 是相同的 |
| p_filesz | “Segment”在 ELF 文件中所占空间的长度，它的值可能是 0，因为可能这个“Segment”在 ELF 文件中不存在内容 |
| p_memse  | “Segment”在进程虚拟地址空间中所占的长度，它的值也可能是 0    |
| p_flags  | “Segment”的权限属性，比如可读“R”，可写“W”和可执行“X”         |
| p_align  | “Segment”的对齐属性，实际对齐字节等于 2 的 p_align 次方      |



- 堆和栈

在操作系统里面，VMA除了被用来映射可执行文件中的各个“Segment”以外，还包括栈（Stack）和堆（Heap）。

查看 /proc 来看进程的虚拟空间分布：

```
$ ./SectionMapping.elf &
[1] 12345
$ cat /proc/12345/maps
```

匿名虚拟内存区域（Anonymous Virtual Memory Area）

VMA 类型：

1. 代码 VMA，权限只读、可执行；有影象文件；
2. 数据 VMA，权限可读写，可执行；有映像文件；
3. 堆 VMA，权限可读写、可执行；无映像文件，匿名，可向上扩展；
4. 栈 VMA，权限可读写、不可执行；无映像文件，匿名，可向下扩展。



- 堆的最大申请数量

- 段地址对齐

对于任意一个可装载的“Segment”，它的 p_vaddr 除以对齐属性的余数等于 p_offset 除以对齐属性的余数。

- 进程堆栈初始化



### 6.5 Linux 内和装载 ELF 过程简介

load_elf_binary：


1. 检查 ELF 可执行文件格式的有效性，比如魔数、程序头表中段（Segment）的数量；
2. 寻找动态链接的“.interp”段，设置动态连接器路径（与动态链接有关）；
3. 根据 ELF 可执行文件的程序头表的描述，对 ELF 文件进行映射，比如代码、数据、只读数据；
4. 将系统调用的返回地址修改成 ELF 可执行文件的入口点，这个入口点取决于程序的链接方式，对于静态链接的 ELF 可执行文件，这个程序入口就是 ELF 文件的文件头中 e_entry 所指的地址；对于动态链接的 ELF 可执行文件，程序入口点是动态链接器。



### 6.6 Windows PE 的装载

RVA（Relative Virtual Address），相对虚拟地址。

PE 装载过程：

1. 先读取文件的第一个页，在这个页中，包含了 DOS 头，PE 文件头和段表；
2. 检查进程地址空间中，目标地址是否可用，如果不可用，则另外选一个装载地址。这个问题对于可执行文件来说基本不存在，因为它往往是进程第一个装入的模块，所以目标地址不太可能被占用。主要是针对 DLL 文件的装载而言的；
3. 使用段表中提供的信息，将 PE 文件中所有的段一一映射到地址空间中相应的位置；
4. 如果装载地址不是目标地址，则进行 Rebasing；
5. 装载所有 PE 文件所需的 DLL 文件；
6. 对 PE 文件中的所有倒入符号进行解析；
7. 根据 PE 头中指定的参数，建立初始化栈和堆；
8. 建立主线程并且启动进程。

PE 文件中，与装载相关的主要信息都包含在 PE 扩展头（PE Optional Header）和段表：

装载有关的成员：

| 成员                                             | 含义                                                         |
| ------------------------------------------------ | ------------------------------------------------------------ |
| ImageBase                                        | PE 文件的优先装载地址，比如，如果该值是 0x00400000，PE 装载器将尝试把文件装到虚拟地址空间的 0x00400000 处。若该地址区域已被其他目标文件占用，那 PE 装载器会选用其他空闲地址。对于可执行文件来说，它一般是 0x00400000，对于 DLL 来说它一般是 0x10000000 |
| AddressOfEntryPoint                              | PE 装载器准备运行的 PE 文件的第一个指令的 RVA。如果我们需要改变整个执行的流程，可以将该值指定到新的 RVA，这样当 PE w文件被开始执行时，会从新的 RVA 处的指令首先被执行，这经常是一些病毒感染 PE 文件后做的第一件事 |
| SectionAlignment                                 | 内存中段对齐的粒度，默认情况下一般是系统页面的大小，x86 下是 4096 字节 |
| FileAlignment                                    | 文件中段对齐的粒度，这个值必须是 2 的指数倍，从 512 到 64KB。默认一般是 512 字节 |
| MajorSubsystemVersion<br />MinorSubsystemVersion | 程序运行所需要的 Win32 子系统版本                            |
| SizeOfImage                                      | 内存中整个 PE 映像的尺寸，它是所有头和节经过节对齐处理后的大小 |
| SizeOfHeaders                                    | 所有头+节表的大小，也就是等于文件尺寸减去文件中所有节的尺寸。可以以此值作为 PE 文件第一节的文件偏移数量 |
| Subsystem                                        | NT 用来识别 PE 文件属于哪一个子系统。对于大多数 Win32 程序，只有两类值：Windows GUI 和 Windows CUI（控制台） |
| SizeOfCode                                       | 代码段的长度                                                 |
| SizeOfInitializedData                            | 初始化了的数据段长度                                         |
| SizeOfUnintitializedData                         | 未初始化的数据段长度                                         |
| BaseOfCode                                       | 代码段起始 RVA                                               |
| BaseOfData                                       | 数据段起始 RVA                                               |



## 第 7 章 动态链接

- 程序的可扩展性和兼容性

插件（Plug-in）

动态链接（Dynamic Linking）

在 Linux 系统中，ELF 动态链接文件被称为动态共享对象（DSO Dynamic Shared Objects），简称共享对象，它们一般都是以“.so”为扩展名的一些文件；而在 Windows 系统中，动态链接文件被称为动态链接库（Dynamical Linking Library），它们通常就是我们平时很常见的以“.dll”为扩展名的文件。



- 简单的动态链接例子

```c
/* Program1.c */
#include "Lib.h"

int main()
{
  foobar(1);
  return 0;
}

/* Program2.c */
#include "Lib.h"

int main()
{
  foobar(2);
  return 0;
}

/* Lib.c */
#include <stdio.h>

void foobar(int i)
{
  printf("Printing from Lib.so %d\n", i);
}

/* Lib.h */
#ifndef LIB_H
#define LIB_H

void foobar(int i);

#endif LIB_H
```

```shell
gcc -fPIC -shared -o Lib.so Lib.c

gcc -o Program1 Program1.c ./Lib.so
gcc -o Program2 Program2.c ./Lib.so
```

编译和链接过程：

```
                [ Lib.c ] -> [ Compiler ] -> [ Lib.o ]
                                                 |
                                                 v
                    [ C Runtime Library ] -> [ Linker ]
                                                 |
                                                 v
                                           [ Lib.so (Stub) ]
                                                       \
                                                        v
[ Program1.c ] -> [ Compiler ] -> [ Program1.o ] -> [ Lineker ] -> [ Program1 ]                     
```

- 关于模块（Module）

在静态链接时，整个程序最终只有一个可执行文件，它是一个不可以分割的整体；但是在动态链接下，一个程序被分成了若干的文件，有程序的主要部分，即可执行文件（Program1）和程序所依赖的共享对象（Lib.so），很多时候我们也把这些部分称为模块，即动态链接下的可执行文件和共享对象都可以看作是程序的一个模块。

共享对象的最终装载地址在编译时是不确定的。

### 7.3 地址无关代码

静态共享库（Static Shared Library）

共享对象在编译时不能假设自己在进程虚拟地址空间中的位置。



- 装载时重定位

静态链接时的重定位叫做链接时重定位（Link Time Relocation），动态链接时被称作装载时重定位（Load Time Relocation），在 Windows 中，这种装载时重定位又被叫做基址重置（Rebasing）。



- 地址无关代码

地址无关代码（PIC，Position-independent Code）技术

-fPIC 的作用就是产生地址无关代码

共享对象模块中的地址引用情况：

1. 模块内部的函数调用、跳转等；
2. 模块内部的数据访问，比如模块中定义的全局变量，静态变量；
3. 模块外部的函数调用、跳转等；
4. 模块外部的数据访问，比如其他模块中定义的全局变量。



针对不同情况的处理：

- 1. 模块内部调用或跳转

模块内部指令相对位置固定，不需要重定位，采用相对地址即可。

- 2. 模块内部数据访问

通过 PC 值计算相对数据地址

- 3. 模块间数据访问

模块间的数据访问需要在装载时才决定，ELF 在数据段里面建立一个指向这些变量的指针数组，也被称为全局偏移表（Global Offset Table，GOT），当代码引用该全局变量时，可以通过 GOT 中相对应的项间接引用。

- 4. 模块间调用、跳转

采用 GOT



各种地址引用方式：

|          | 指令跳转、调用             | 数据访问          |
| -------- | -------------------------- | ----------------- |
| 模块内部 | （1）相对跳转和引用        | （2）相对地址访问 |
| 模块外部 | （3）间接跳转和调用（GOT） | 间接访问（GOT）   |



-fpic 和 -fPIC

唯一的区别是“-fPIC”产生的代码要大，而“-fpic”产生的较小，且更快，但在某些平台上存在限制，比如全局符号的数量或者代码的长度等，而“-fPIC”没有这样的限制，为了方便，绝大部分情况下都使用“-fPIC”。



PIC 和 PIE

地址无关代码也可以用在可执行文件上，以地址无关的方式编译出来的可执行文件被称作地址无关可执行文件（PIE，Position-Independent Execuable），产生参数为“-fPIE”或者“-fpie”。



- 共享模块的全局变量问题

```c
extern int global;
int foo()
{
  global = 1;
}
```

编译器无法根据这个上下文判断 global 是定义在同一个模块的其他目标文件中还是定义在另一个共享对象中，即无法判断是否为跨模块间的调用。

解决办法就是所有使用这个变量的指令都指向位于可执行文件中的那个副本。ELF 共享库在编译时，默认都把定义在模块内部的全局变量当作定义在其他模块的全局变量，也就是说当作前面的类型四，通过 GOT 来实现变量的访问。在模块装载时，如果某个全局变量在可执行文件中拥有副本，那么动态链接器就会把 GOT 中的相应地址指向该副本，这样该变量运行时实际上最终就只有一个实例。如果变量在共享模块中被初始化，那么动态链接器还需要将该初始化值复制到程序主模块中的变量副本；如果该全局变量在程序主模块中没有副本，那么 GOT 中的相应地址就指向模块内部的变量副本。



- 数据段地址无关性

不使用 -fPIC 参数生成共享对象：

```
$ gcc -shared pic.c -o pic.so
```

将产生一个不使用地址无关代码而使用装载时重定位的共享对象，则不能被多个进程之间共享，那样就失去了节省内存优点。但装载时重定位的共享对象的运行速度要比使用地址无关代码的共享对象要快，因为它省去了地址无关代码中每次访问全局数据和函数时需要做一次计算当前地址以及间接地址寻址的过程。



### 7.4 延迟绑定（PLT）

延迟绑定（Lazy Binding），基本思想是函数第一次被用到时才进行绑定（符号查找、重定位等），如果没有用到则不进行绑定。所以程序刚开始运行时，模块间的函数调用都没有进行绑定，而是需要用到时才由动态连接器来进行绑定。这样可以大大加快程序的启动速度。

ELF 使用 PLT（Procedure Linkage Table）的方法来实现。

.got.plt 前三项：

1. 保存的是“.dynamic”段的地址，这个段描述了本模块动态链接相关的信息；
2. 保存的是本模块的 ID；
3. 保存的是 \_dl\_runtime_resolve() 的地址。

第 2 项和第 3 项由动态连接器在装载共享模块时将他们初始化，.got.plt 的其它项分别对应每个外部防函数的引用。



### 7.5 动态链接相关结构

动态连接器（Dynamic Linker）

- “.interp”段

动态链接器由 ELF 可执行文件决定，在 ELF 文件中，“.interp”段用来存放所需的动态链接器的路径

- “.dynamic”段

```c
// /usr/include/elf.h

/* Dynamic section entry.  */

typedef struct
{
  Elf32_Sword   d_tag;                  /* Dynamic entry type */
  union
    {
      Elf32_Word d_val;                 /* Integer value */
      Elf32_Addr d_ptr;                 /* Address value */
    } d_un;
} Elf32_Dyn;
```

由一个类型值加上一个附加的数值或者指针。

| d_tag 类型                | d_un 的含义                                         |
| ------------------------- | --------------------------------------------------- |
| DT_SYMTAB                 | 动态链接符号表的地址，d_ptr 表示“.dynsym”的地址     |
| DT_STRTAB                 | 动态链接字符串表地址，d_ptr 表示“.dynstr”的地址     |
| DT_STRSZ                  | 动态链接字符串表大小，d_val 表示大小                |
| DT_HASH                   | 动态链接哈希表地址，d_ptr 表示“.hash”的地址         |
| DT_SONAME                 | 本共享对象的“SO-NAME”                               |
| DT_RPATH                  | 动态链接共享对象搜索路径                            |
| DT_INIT                   | 初始化代码地址                                      |
| DT_FINIT                  | 结束代码地址                                        |
| DT_NEED                   | 依赖的共享对象文件，d_ptr表示所以来的共享对象文件名 |
| DT_REL<br />DT_RELA       | 动态链接重定位表地址                                |
| DT_RELENT<br />DT_RELAENT | 动态重读位表入口地址                                |



- 动态符号表

动态符号表（Dynamic Symbol Table），它的段名通常叫做“.dynsym”，它只保存了与动态链接相关的符号，而“.symtab”中保存了所有的符号。

动态符号表也需要一些辅助表，例如动态符号字符串表“.dynstr”（Dynamic String Table），符号哈希表（“.hash”）。

查看 ELF 文件的动态符号表以及它的哈希表：

```shell
$ readelf -sD Lib.so
```



- 动态链接重定位表

查看动态链接的文件的重定位表：

```shell
$ readelf -r Lib.so
```



- 动态链接时进程堆栈初始化信息

进程初始化的时候，堆栈里面保存了关于进程执行环境和命令行参数等信息，还保存了动态连接器所需要的一些辅助信息数组（Auxiliary Vector）。

```c
// usr/include/elf.h

/* Auxiliary vector.  */

/* This vector is normally only used by the program interpreter.  The
   usual definition in an ABI supplement uses the name auxv_t.  The
   vector is not usually defined in a standard <elf.h> file, but it
   can't hurt.  We rename it to avoid conflicts.  The sizes of these
   types are an arrangement between the exec server and the program
   interpreter, so we don't fully specify them here.  */

typedef struct
{
  uint32_t a_type;              /* Entry type */
  union
    {
      uint32_t a_val;           /* Integer value */
      /* We use to have pointer elements added here.  We cannot do that,
         though, since it does not work when using 32-bit definitions
         on 64-bit platforms and vice versa.  */
    } a_un;
} Elf32_auxv_t;
```

| a_type 定义 | a_type 值 | a_val 的含义                                                 |
| ----------- | --------- | ------------------------------------------------------------ |
| AT_NULL     | 0         | 表示辅助信息数组结束                                         |
| AT_EXEFD    | 2         | 表示可执行文件的文件句柄，动态链接器需要知道一些关于可执行文件的信息。当进程开始执行可执行文件时，操作系统会先将文件打开，这时候就会产生文件句柄。那么操作系统可以将文件句柄传递给动态连接器，动态链接器可以通过操作系统的文件读写操作来访问可执行文件。 |
| AT_PHDR     | 3         | 可执行文件中程序头表（Program Header）在进程中的地址。<br />正如前面 AT_EXEFD 提到的，动态链接器可以通过操作系统的文件读写功能来访问可执行文件，但事实上，很多操作系统会把可执行文件映射到进程的虚拟空间里面，从而动态链接器不需要通过读写文件，而是可以直接访问内存中的文件镜像。所以操作系统要么选择前面的文件句柄方式，要么选择这种映像的方式。当选择映像的方式时，操作系统必须提供后面的 AT_PHENT、AT_PHNUM 和 AT_ENTRY 这几个类型 |
| AT_PHENT    | 4         | 可执行文件头中程序表中每一个入口（Entry）的大小              |
| AT_PHNUM    | 5         | 可执行文件头中程序头表中入口（Entry）的数量                  |
| AT_BASE     | 7         | 表示动态链接器本身的装载地址                                 |
| AT_ENTRY    | 9         | 可执行文件入口地址，即启动地址                               |



### 7.6 动态链接的步骤和实现

- 动态链接器自举

动态链接器本身也是一个共享对象，动态链接器本身的重定位工作由它自身来完成。

自举（Bootstrap）



- 装载共享对象

全局符号表（Global Symbol Table）

全局符号介入（Global Symbol Interpose）

Linux 动态链接器的处理：当一个符号需要被加入全局符号表时，如果相同的符号名已经存在，则后加入的符号被忽略。



- 重定位和初始化

- Linux 动态链接器的实现

1. 动态链接器本身时静态链接的；
2. 动态链接器一般是 PIC 的；
3. 动态链接器的装载地址和一般共享对象没区别。



### 7.7 显式运行时链接

显式运行时链接（Explicit Run-time Linking），让程序自己在运行时控制加载指定的模块，并且可以在不需要模块的时候卸载。

动态装载库（Dynamic Loading Library）

- dlopen()

dlopen() 函数用来打开一个动态库，并将其加载到进程的地址空间，完成初始化过程。

```c
void * dlopen(const char * filename, int flag);
```

第一个参数是被加载动态库的路径，如果这个路径是绝对路径（以“/”开始的路j），则该函数将会尝试直接打开该动态库，如果是相对路径，那么 dlopen() 会尝试在以一定的顺序去查找该动态库文件。

1. 查找有环境变量 `LD_LIBRARY_PATH` 指定的一系列目录；
2. 查找由 /etc/ld.so.cache 里面所指定的共享库路径；
3. /lib、/usr/lib 注意：这个查找顺序与旧的 a.out 装载器的顺序刚好相反，旧的 a.out 的装载器在装载共享库的时候会优先查找 /usr/lib，然后是 /lib。

如果 filename 这个参数设置为 0，那么 dlopen 返回全局符号表的句柄，可以查找全局符号表里面的任意一个符号，并且可以执行它们，类似高级语言的反射（Reflection）。全局符号表包括了程序的可执行文件本身、被动态链接器加载到进程中的所有共享模块以及在运行时通过 dlopen 打开并且使用了 RTLD_GLOBAL 方式的模块中的符号。

第 2 个参数 flag 表示函数符号的解析方式。

1. 常量 RTLD_LAZY 表示使用延迟绑定，当函数第一次被用到时才进行绑定，即 PLT 机制；
2. 常量 RTLD_NOW 表示当模块被加载时即完成所有的函数绑定工作，如果有任何为定义的符号引用的绑定工作没法完成，那么 dlopen() 就会返回错误；
3. 常量 RTLD_GLOBAL 可以跟上面两者中的任意一个一起使用，表示将被加载的模块的全局符号合并到进程的全局符号表中，使得后来加载的模块可以使用这些符号。

dlopen 返回被加载模块的句柄，用于 dlsym 或 dlclose，如果加载模块失败，返回 0。如果被加载模块之有依赖关系，那么程序需要手动加载被依赖的模块，例如 A 依赖 B，则先加载 B，再加载 A。

dlopen 会在加载模块时执行模块中初始化部分的代码，即“.init”段的代码，用以完成模块的初始化工作。



- dlsym()

dlsym 函数基本上是运行装载的核心部分，可以通过这个函数找到所需要的符号。

```c
void * dlsym(void * handle, char * symbol);
```

第一个参数是由 dlopen 返回的动态库句柄；第二个参数是要查找的符号的名字，一个以“\0”结尾的 C 字符串。

如果 dlsym 找到了对应的符号，则返回该符号的值，否则返回 NULL，对于符号类型的不同，它返回值的含义不同如果查找的是一个函数，则返回函数的地址；如果是个变量，则返回变量的地址；如果是一个常量，那么返回该常量的值。如果常量的值刚好返回 NULL 或 0，可以使用 dlerror() 函数，当它返回 NULL，表示 dlsym 找到了对应的符号，则否返回错误信息。

- 符号优先级

装载序列（Load Ordering）

依赖序列（Dependency Ordering）



- dlerror()

每次调用 dlopen()、dlsym() 或 dlclose() 后，可以调用 dlerror() 函数来判断上一次是否成功。dlerror() 的返回值类型是 char\*，如果返回 NULL，则表示上一次调用成功；如果不是，则返回相应的错误消息。


- dlclose()

dlclose() 的作用刚好相反，它是将一个已经加载的模块卸载，系统会维持一个加载引用计数器，每次使用 dlopen() 加载某模块时，相应的计数器加一；每次 dlclose() 卸载某模块时，相应计数器减一。只有当计数器值减到 0 时，模块才真正的被卸载掉。

卸载的过程刚好相反，先执行“.finit”段的代码，然后相应的符号从符号表中去除，取消进程空间跟模块的映射关系，然后关闭模块文件。



## 第 8 章 Linux 共享库的组织

共享库（Shared Library）

### 8.1 共享库版本

- 共享库的兼容性

共享库的更新：

1. 兼容更新。所有更新只在原有共享库的基础上添加一些内容，所有原有的接口都保持不变；
2. 不兼容更新。共享库更新改变了原有的接口，使用该共享库原有接口的程序可能不能运行或运行不正常。

ABI（Application Binary Interface）

当值 C 语言共享库 ABI 改变的 4 个行为：

1. 导出函数的行为发生改变，也就是说调用这个函数以后产生的结果与以前不一样，不再满足旧版本规定的函数行为准则；
2. 导出函数被删除；
3. 导出数据的结构发变化，比如共享库定义的结构体变量的结构发生改变：结构体成员删除、顺序改变或其他引起结构体内存布局变化的行为（通常来讲，往结构体尾部添加成员不会导致不兼容，当然这个结构体必须是共享内部分配的，如果是外部分配的，在分配该结构时必须考虑成员添加的情况）。
4. 导出函数的接口发生变化，比如函数返回值、参数被更改。

开发 C++ 的共享库需要注意：

1. 不要在接口类中使用虚函数，万不得已要使用虚函数时，不要随意删除、添加或在子类中添加新的实现函数，这样会导致类的虚函数表结构发生变化；
2. 不要改变类中任何成员变量的位置和类型；
3. 不要删除非内嵌的 public 或 protected 成员的函数；
4. 不要将非内嵌的成员函数改变成内嵌的成员函数；
5. 不要改变成员函数的访问权限；
6. 不要再接口中使用模板；
7. 最重要的是，不要改变接口的任何部分或干脆不要使用 C++ 作为共享库接口！



- 共享库版本命名

Linux 规定共享库的文件名规则必须如下：

```
libname.so.x.y.z
```

最前面使用前缀“.lib、中间是库的名字和后缀“.so”，最后面跟的是三个数字组成的版本号。“x”表示主版本号（Major Version Number），“y”表示次版本号“Minor Version Number”、“z”表示发布版本号（Release Version Number）。

主版本号表示库的重大升级，不同主版本号之间的库是不兼容的，依赖于旧的主版本号的程序需要改动相应的部分，并且重新编译，才可以在新版的共享库中运行；或者，系统必须保留旧版的共享库，使得那些依赖于旧版共享库的程序能够正常运行。

次版本号表示库的增量升级，即增加一些新的接口符号，且保持原来的符号不变。在主版本号相同的情况下，高的次版本号的库向后兼容低的次版本号的库。一个依赖于旧的的次版本号共享库的程序，可以在新的次版本号共享库中运行，因为新版中保留了原来所有的接口，并且不改变它们的定义和含义。

发布版本号表示库的一些错误修正、性能的改进等，并不添加任何新的接口，也不对接口进行更改。相同主版本号、次版本号的共享库，不同的发布版本号之间完兼容，依赖于某个发布版本号的程序可以在任何一个其他发布版本号正常运行，而无需做任何修改。

Glibc 库没有使用这种规则，它的基本 C 语言库使用了 libc-x.y.z.so 这种命名方式。



- SO-NAME

SO-NAME 即共享库的文件名去掉次版本和发布版本号，保留主版本号。

例如 libfoo.so.2.6.1，它的 SO_NAME 即 libfoo.so.2，SO-NAME 是为了记录共享库的依赖关系。

Linux 系统中，系统会为每个共享库在它所在的目录创建一个跟“SO-NAME”相同的并且指向它的软链接（Symbol Link）。这个软链接会指向目录中主版本号相同、次版本号和发布版本号最新的共享库。

链接名（Link Name）

次版本号交会问题（Minor-revision Rendezvous Problem），系统中只有低次版本号的库，可能运行失败。



- 基于符号的版本机制

基于符号的版本机制（Symol Versioning），每次升级，每个符号都添加一个独立的版本标记。

- Solaris 中的符号版本机制

符号版本脚本

范围机制（Scoping）



- Linux 中的符号版本

GCC 对 Solaris 符号版本机制的扩展

GG 允许使用一个叫做“.symver”的汇编宏指令来指定符号的版本。

```c
asm(".symver add, add@VERS_1.1");

int add(int a, int b)
{
  return a + b;
}
```

还允许多个版本的同一个符号存在于一个共享库中：

```c
asm(".symver old_printf, printf@VERS_1.1");
ams(".sym");

int old_printf() { ... }
int new_printf() { ... }
```



- Linux 系统中符号版本机制实践

符号版本脚本：

```ver
VERS_1.2 {
  global:
    foo;
  local:
      *;
}
```

指定符号脚本编译：

```shell
gcc -shared -fPIC lib.c -Xlinker --version-script lib.ver -o lib.o
```



### 8.3 共享库系统路径

大多数包括 Linux 在内的开源操作系统都遵守一个叫做 FHS（File Hierarchy Standard）的标准。

FHS 规定了一个系统中的文件该如何存放，包括各个目录的结构、组织和作用，有利用促进各个开源操作系统之间的兼容性，共享库作为系统中重要的文件，它们的存放方式也被 FHS 列入范围。

FHS 规定，一个系统主要有两个存放共享库的位置：

1. /lib，这个位置主要存放系统最关键和基础的共享库，比如动态链接器、C 语言运行库、数学库等，这些库主要是那些 /bin 和 /sbin 下的程序所需要用到的库，还有系统启动时需要的库；
2. /usr/lib，这个目录下主要保存的是一些非系统运行时所需要的关键性的共享库，主要是一些开发时用到的共享库，这些共享库以一般不会被用户的程序或 shell 脚本字节用到。这个目录下面还包含了开发时可能会用到的静态库、目标文件等；
3. /usr/local/lib，这个目录用来放置一些跟操作系统本身并不十分相关的库，主要是一些第三方应用程序的库。比如安装了 python 语言的解释器，那么与它相关的共享库可能会被放到 /usr/local/lib/python，而它的可执行文件可能被放到 /usr/local/bin 下。GNU 的标准推荐第三方的程序应该默认将库安装到 /usr/local/lib 下。



### 8.4 共享库查找过程

### 8.5 环境变量

LD\_LIBRARY\_PATH

LD\_PRELOAD

LD\_DEBUG



### 共享库的创建和安装

- 共享库的创建

```shell
$ gcc -shared -W1,-soname,my_soname -o library_name source_files library_files
```

如果不使用 -soname 来指定共享库的 SO-NAME，那么它默认就没有 SO-NAME，即使用 ldconfig 更新 SO-NAME 的软链接时，对该共享库也没有效果。

将 libfoo1.c 和 libfoo2.c 两个源代码文件,产生一个 libfoo.so.1.0.0 的共享库，它们依赖于 libbar1.so 和 libbar2.so 这两个共享库：

```shell
$ gcc shared -fPIC -w1,-soname,libfoo.so.1 -o libfoo.so.1.0.0 libfool1.c libfoo2.c -lbar1 -lbar2
```



- 清除符号信息

```shell
$strip libfoo.so
```



-共享库的安装

```shell
$ ldconfig -n share_library_directory
```



- 共享库构造和析构函数

gcc 提供了一种共享库的构造函数，只要在函数声明附加上“__attribute__((constructor))”的属性，即指定该函数为共享库构造函数，它会在共享库被加载时执行，即在 main 函数之前执行。

对应的析构函数是“__attribute__((destructor))”

- 共享库脚本



## 第 9 章 Windows 下的动态链接

todo

# 第 4 部分 库与运行库

## 第 10 章 内存

### 10.1 程序的内存布局

应用程序使用的内存空间的"默认"区域：

- 栈：栈用于维护函数调用的上下文，离开了栈函数调用就没法实现。栈通常在用户空间的最高地址处分配，通常有数兆字节的大小；
- 堆：堆是用来容纳应用程序动态分配的内存区域，当程序使用 malloc 或 new 分配内存时，得到的内存来自堆里。堆通常存在于栈的下方（低地址方向），在某些时候，堆也可能没有固定统一的存储区域。堆一般比栈大很多，可以有几十至数百兆字节的容量；
- 可执行文件映像：这里存储着可执行文件在内存里的映像；
- 保留区：保留区并不是一个单一的内存区域，而是堆内存中受到保护而禁止访问的内存区域的总称。



### 10.2 栈与调用惯例

- 什么是栈

栈（Stack） 向下增长

栈保存了一个函数调用所需要的维护信息，这常常被堆栈帧（Stack Frame），或活动记录（Activate Record）

包括如下及内容：

1. 函数的返回地址和参数；
2. 临时变量：包括函数的非静态局部变量以及编译器自动生成的其他临时变量；
3. 保存的上下文：包括在函数调用前后需要保持不变的寄存器。

ebp 寄存器被称为帧指针（Frame Pointer）



i386 下的函数调用：

1. 把所有或一部分参数压入栈中，如果有其他参数没有入栈，那么使用某些特定寄存器传递；
2. 把当前指令的下一条指令的地址压入栈中；
3. 跳转到函数执行。



调用惯例（Calling Convention）

1. 函数参数的传递顺序和方式；
2. 栈的维护方式；
3. 名字修饰（Name-mangling）的策略；



| 调用惯例 | 参数传递   | 出栈方                                                       | 名字修饰                                                     |
| -------- | ---------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| cdecl    | 函数调用方 | 从右至左的顺序压参数入栈                                     | 下划线 + 函数名                                              |
| stdcall  | 函数本身   | 从右至左的顺序压参数入栈                                     | 下划线 + 函数名 + @ + 参数的字节数，如函数 int func(int a, double b)为 _func@12 |
| fastcall | 函数本身   | 头两个 DWORD（4 字节）类型或者占更少字节的参数被放入寄存器，其他剩下的参数按从右到左的顺序压入栈 | @ + 函数名 + @ + 参数的字节数                                |
| pascal   | 函数本身   | 从左至右的顺序压参数入栈                                     | 较为复杂                                                     |

- 函数返回值传递



### 10.3 堆与内存管理

堆（Heap）

- Linux 进程堆管理

Linux 提供两个堆空间分配的系统调用，brk() 和 mmap()。

```c
int brk(void * end_data_segment);
```

brk() 的作用实际上就是设置进程数据段的结束地址，即它可以扩大或缩小数据段（Linux 下的数据段和 BSS 段合并在一起统称为数据段）。

```c
void * mmap(
  void * start,
  size_t length,
  int prot,
  int flags,
  int fd,
  off_t offset
);
```

mmap 向操作系统申请一段虚拟地址空间，这块空间可以映射到某个文件（这也是这个系统调用的最初的作用），当它不将地址空间映射到某一个文件时，这块空间被称为匿名（Anonymous）空间。



- Windows 进程管理

堆管理器（Heap Manager）API：

- HeapCreate：创建一个堆。
- HeapAlloc：在一个堆里分配内存。
- HeapFree：释放已经分配的内存。
- HeapDestory：摧毁一个堆。



- 堆分配算法

1. 空闲链表

空闲链表（Free List），把堆中各个空闲的块按照链表的方式连接起来，当用户请求一块空间时，可以遍历整个列表，直到找到合适大小的块并且将它拆分；当用户释放空间时将他合并到空闲链表中。

2. 位图

位图（Bitmap），将整个堆划分成为大量的块（block），每个块的大小相同。当用户请求内存时，总是分配整个块的空间给用户，第一个被称为已分配区域的头（Head），其余的成为已分配区域的主体（Body）。可以使用一个整数数组来记录块的使用情况，由于每个块只有头/主体/空闲三种状态，那么仅需要两位即可表示一个块，因此称为位图。

优点：

1. 速度快：由于整个堆的空闲信息存储在一个数组内，因此访问该数组时 cache 容易命中；
2. 稳定性好：为了避免用户越界读写破坏数据，只需简单的备份位图即可。即使部分数据被破坏，也不会导致整个堆无法工作；
3. 块不需要额外信息，已于管理；

缺点：

1. 分配内存时容易产生碎片。例如分配 300 字节，需要 3 个块，384 字节，浪费了 84 字节；
2. 如果堆很大，或者设定一个块很小（可以较少内存碎片）那么位图将会很大，可能失去 cache 命中率高的优势，也会浪费一定的空间，可以使用多级位图。

3. 对象池

如果每一次分配的空间大小都一样，那么就可以按照这个每次请求分配的大小作为一个单位，把整个堆空间划分成大量的小块，每次请求的时候只需要找到小块即可。



## 第 11 章 运行库

### 11.1 入口函数和程序初始化

入口函数和入口点（Entry Point）

程序运行典型步骤：

1. 操作系统创建进程后，把控制权交到了程序的入口，这个入口往往是运行库中的某个入口函数；
2. 入口函数对运行库和程序运行环境进行初始化，包括堆、I/O、线程、全局变量构造等等；
3. 入口函数在完成初始化后，调用 main 函数，正式开始执行程序主体部分；
4. main 函数执行完毕后，返回到入口函数，入口函数进行清理工作，包括全局变量析构
堆销毁、关闭 I/O 等，然后进行系统调用结束进程。



### 11.2 C/C++ 运行库

运行时库（Runtime Library），C 语言的运行库，被称为 C 运行库。

C 语言库的覆盖范围：

1. 启动与退出：包括入口函数及入口函数所依赖的其他函数等；
2. 标准函数：由 C 语言标准 规定的 C 语言标准库所拥有的函数实现；
3. I/O：I/O 功能的封装和实现；
4. 堆：堆的封装和实现；
5. 语言实现：语言中的一些特殊功能的实现；
6. 调试：实现调试功能的代码。

美国国家标准协会（American National Standards Institute，ANSI）



- C 语言标准库

1. 变长参数
2. 非局部跳转



- glibc 与 MSVC CRT

glibc（GNU C Library）和 MSVS CRT（MicrosoftVisual C Run-time）

glibc 是 GNU 旗下的 C 标准库，由自由软件基金会 FSF（Free Software Foundation）发起开发。



### 11.3 运行库与多线程

### 11.4 全局构造与析构

### 11.5 fread 实现



## 第 12 章 系统调用与 API

系统调用（System Call）

### 12.2 系统调用原理

用户模式（User Mode）和内核模式（Kernel Mode）

中断（Interrupt）

中断处理程序（Interrupt Service Routine，ISR）

中断向量表（Interrupt Vector Table）



## 第 13 章 运行库实现
