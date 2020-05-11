# 程序员的自修养——链接、装载与库

# 第 1 部分简介

## 第 1 章 温故而知新

- 1.3 万变不离其宗

总线（BUS）

南桥（Southbridge）芯片用于连接低速设备，例如：磁盘、USB、键盘、鼠标等。

北桥（Northbridge，PCI Bridge）芯片用于连接所有高速设备，包括 CPU、内存和 PCI 总线。

对称多处理器（SMP，Symmetrical Multi-Processing），就是每个 CPU 在系统中所处的地
位和所发挥的功能是一样的，是相互对称的。

多核处理器（Multi-core Processor），将多个处理器打包，以一个处理器的外包装进行
出售，处理器之间缓存部件，只保留多个核心。



- 1.4 站得高，看得远

> 计算机科学领域的任何一个问题都可以通过增加一个间接的中间层来解决。
> Any problem in computer science can be solved by another layer of indirection.

接口（Interface），每个层次之间通信的协议。

开发工具和应用程序属于同一个层次，它们都使用应用程序编程接口（Application Program 
Interface）。

运行库使用操作系统提供的系统调用接口（System call Interface），系统调用接口在现
实中往往以软件中断（Software Inerrupt）的方式提供。

硬件规格（Hardware Specification），指驱动程序如可操作硬件，如何与硬件进行通信。



- 操作系统

1. 多道程序（Multiprogramming），当某个程序无需使用 CPU 时，监控程序就把另外正在
等待 CPU 资源的程序启动，使得 CPU 能够充分利用起来。
2. 分时系统（Time-Sharing System），每个程序运行一段时间以后都主动让出 CPU 给其
他程序，使得一段时间内每个程序都有机会运行一小段时间。
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

把地址空间人为地等分成固定大小的页，每一页的大小由硬件决定，或硬件支持多种大小的
页，由操作系统决定页的大小。

虚拟空间的页叫做虚拟页（VP，Virtual Page），物理内存中的页叫做物理页
（PP，Physical Page），把磁盘中的页叫做磁盘页（DP，Disk Page）。

当进程访问对应的页不在内存中时，硬件会捕获到这个消息，就是页错误（Page Fault）。

虚拟存储硬件支持，几乎所有的硬件都采用 MMU（Memory Management Unit）部件进行页映
射。通常 MMU 都集成在 CPU 内部，不会以单独的形式出现。

```
[ CPU ] -> Virtual Address -> [ MMU ] -> Physical Address -> [ Physical Memory ]
```



- 众人拾柴火焰高

线程：

线程（Thread），或被称为轻量级进程（Lightweight Process LWP），是程序执行流的最
小单元。一个标准的线程由线程 ID、当前指令指针（PC），寄存器集合和堆栈组成。



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

抢占（Preemption），线程在用尽时间片之后会被强制剥夺继续执行的权力，进行就绪状态，
即之后别的线程抢占了当前线程。



- Linux 线程

Linux 中不存在线程的概念，Linux 将所有执行实体（无论是线程或进程）都成为任务（Task）
，每个任务概念上都类似于一个单线程的进程，具有内存空间、执行实体、文件资源等。

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

```
$gcc hello.c
$ ./a.out
Hello World
```

编译过程：

预处理（PrePressing）、编译（Compilation）、汇编（Assembly）和链接（Linking）。

```
[ Source Code ] \ 
hello.c          \
                  +-> [ Prepressing ] -> [ Preprocessed ] -> [ Compilation ]
                 /      (cpp)              hello.i             gcc
[ Hearder Files ]                                               |
studio.h                                                        |
...                                                             |
                                                                v
[ Static Library ] <- [ Object File ] <- [ Assembly ] <- [ Assembly ]
  libc.a                hello.o            (as)            hello.s
  ...              /
      \           v
       +> [ Linking ] -> [ Executable]
            (ld)           a.out
```



- 预处理

```
$gcc -E hello.c -o hello.i
or:
$cpp hello.c > hello.i
```

预编译过程主要处理哪些源代码文件中以“#”开头的预编译指令。

预编译处理过程：

1. 将所有的“#define”删除，并展开所有宏定义；
2. 处理所有条件预编译指令，如“#if”、“#elif”、“#elde”、“#endif”；
3. 处理“#include”预编译指令，将被包含的文件插入到该预编译指令的位置。注意，这
个过程是递归进行的，也就是说被包含的文件可能还包含其他文件；
4. 删除所有的“//”和“/**/”；
5. 添加行号和文件名标识，比如 #2“hello.c”2，以便于编译时编译器产生调试用的行号
信息及用于编译时产生编译错误或警告时能够显示行号；
6. 保留所有 #pragma 编译器指令，因为编译器需要使用它们。



- 编译

编译过程就是把预处理完的文件进行一系列词法分析、语法分析、语义分析及优化后产生相
应的汇编文件。

```
$gcc -S hello.i -o hello.s
or
$gcc -S hello.c -o hello.s
```

gcc 是编译器套件，根据不同参数要求去调用预编译程序 cc1、汇编器 as、连接器 ld。



- 汇编

汇编器将汇编代码转变成机器可以执行的指令，每一个汇编语句几乎对应一条机器指令。

```
$as hello.s -o hello.o
or:
$gcc -c hello.s -o hello.o
or:
$gcc -c hello.c -o hello.o
```



- 链接

。。。



- 编译器做了什么

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

源代码首先被输入扫描器（Scanner），运用类似于有限状态机（Finite State Machine）
的算法可以轻松地将源代码的字符序列分割成一系列的记号（Token）。

记号一般分为：关键字、标识符、字面量（数字、字符串等）和特殊符号（加号、等号）。

lex 程序可以实现词法扫描。



2. 语法分析

语法分析器（Grammar Parser）将对由扫描器产生的记号进行语法分析，产生语法树
（Syntax Tree）。整个过程采用了上下文无关语法（Context-free Grammar）的分析手段。

语法树是以表达式（Expression）为节点的树。

yacc（Yet Another Compiler Compiler）程序可用于词法分析。



3. 语义分析

语义分析器（Semantic Analyzer）对表达式做静态语义（Static Semantic，在编译期确定
的语义）分析，不了解这个语句是否有意义。

动态语义（Dynamic Semantic）指在运行期才能确定的语义。



4. 中间语言生成

源码级优化器（Source Code Optimizer）将整个语法树转换成中间代码（Intermediate Code）

中间代码类型：三地址码（Threr-address Code）和 P-代码（P-Code）。

最基本的三地址码：`x = y op z`



5. 目标代码生成与优化

源代码级优化器产生中间代码标志着下面的过程都属于编辑器后端。后端主要包括代码生成
器（Code Generator）和目标代码优化器（Target Code Optimizer）。

示例代码序列：

```assembly
movl index, %ecx            ; value of index to ecx
addl $4, %ecx               ; ecx = ecx + 4
mull $8, %ecx               ; ecx = ecx * 8
movl index, %eax            ; value of index to eax
movl %ecx, array(, eax, 4)  ; array[index] = ecx
```

目标代码优化器可能采用合适的寻址方式、使用位移来代替乘法运算、删除多余的指令等。

上述示例代码乘法由一条基址比例变址寻址（Base Index Scale Addressing）的 lea 指令
完成，随后由 mov 指令完成赋值操作。

源代码此时被便衣成为目标代码，但是 index 和 array 的地址还未确定。



- 连接器

重新计算各个目标的地址的过程被叫做重定位（Relocation）。



- 静态链接

链接（Linking）过程主要包括地址空间分配（Address and Storage Allocation）、符号
决议（Synmbol Resolution）和重定位（Relocation）等。

运行时库（Runtime Library），它是支持程序运行的基本函数的集合。就是一些最常用的
代码编译成目标文件后打包存放。

对地址的修正过程叫做重定位（Relocation），每一个要修正的地方叫一个重定位入口
（Relocation Entry）



## 第 3 章 目标文件里有什么

- 目标文件的格式

PC 平台主流的可执行文件格式（Executable），主要是 Windows 下的 PE
（Portable Execuable）和 Linux 的 ELF（Executable Linkable Format），它们都是 
COFF（Common file format）格式的变种。

目标文件就是源代码编译后但未未进行链接的那些中间问题（Windows 的 .obj 和 Linux 下
的 .o）。

可以广义的将目标文件和可执行文件看作同一类型的文件，Windows 下，统称它们为 PE-COFF 
文件格式。Linux 下，可统称为 ELF 文件。还有不太常见的 Intel/Microsoft 的 OMF
（Object Module Format）、Unix a.out 格式和 MS-DOS.COM 格式等。

动态链接库（DLL，Dynamic Linking Library）（Windows 的 .dll 和 Linux 的 .so）以及
静态链接库（Static Linking Library）（Windows 的 .lib 和 Linux 的 .a）文件都按照
可执行文件格式存储。

| ELF 文件类型 | 说明 | 实例 |
| ----------- | ---- | ---- |
| 可重定位文件（Relocatable File）| 这类文件包含了代码和数据，可以被用来链接成可执行文件或共享目标文件，静态链接库也可以归为这一类 | Linux 的 .o；Windows 的 .obj |
| 共享目标文件（Shared Object File） | 这种文件包含了代码和数据，可以在以下两种情况中使用，一种是链接器可以使用这种文件跟其他的可重定位文件和共享目标文件链接，产生新的目标文件，第二种是动态连接器可以将几个这种共享目标文件与可执行文件结合，作为进程映像的一部分来运行 | Linux 的 .so，如 /lib/glibc-2.5.so，Windows 的 DLL |
| 核心转储文件（Core Dump File） | 当进程意外终止时，系统可以将该进程的地址空间的内容及终止时的一些其他信息转储到核心转储文件 | Linux 下的 Core Dump |



- 目标文件是什么样的？

除了代码和数据以外，目标文件中还包括了链接时所需要的一些信息，比如符号表、调试信息、字符串等。
一般目标文件将这些信息按不同的属性，以节（Section），或者叫段（Segment）的形式存储。

程序源代码编译后的机器指令经常被放在代码段（Code Section）中，常见段名为“.code”或“.text”；
全局变量和局部静态变量数据经常放在数据段（Data Section），一般名叫“.data”


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

ELF 文件的开头是一个“文件头”，它描述了整个文件的属性，包括文件是否可执行、是静态链接
还是动态链接以及入口地址（如果是可执行文件）、目标硬件、目标操作系统等信息。

文件头还包括一个段表（Section Table），段表其实是一个描述文件中各个段的数组，它描述
了各个段在文件中的偏移位置及段的属性等。

.bss 段只是为未初始化的全局变量和局部静态变量预留位置而已，并没有内容，不占空间。

BSS（Bloack Started by Symbol）

总体来说，程序源代码被编译后主要分成代码段和数据段。

> 真正了不起的程序员对自己的程序的每一个字节都了如指掌 ——佚名



简单查看 object 文件结构：

```
$objectdump -h SimpleSection.o
```

额外段：只读数据段（.rodata）、注释信息段（.comment）和堆栈提示段（.note.GNU-stack）。

size 命令查看 ELF 文件的代码段、数据段和 BSS 段的长度（dec 为十进制，hex 为十六进制）。

```
$size SimpleSection.o
```


- 代码段

使用 objdump -s 以十六进制打印所有段的内容，-d 对包含指令的段进行返汇编。

```
$ objdump -s -d SimpleSection.o
```



- 数据段和只读数据段








