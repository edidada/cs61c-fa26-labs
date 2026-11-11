# CS61C Fall2026 Lab03：RISC-V与Venus

规范 https://cs61c.org/fa26/labs/lab03/ ，官方基线ae05a0313aad04ed688bb4fbd1aa7df3b8b38132。AI辅助公开自学，不冒充校内提交。

hello输出2026；内存循环改为严格小于10以避免第11次写入，保存分配基址并free；离散函数用输入加3、左移2位、基址相加后lw，无条件分支（仅保留原jr ra返回）；可选factorial采用迭代乘积，初始化累乘值并支持0!。未改官方离散函数tester和fib。

独立.github/workflows/lab03.yml调用scripts/verify_lab03.sh；只在Actions执行。使用当期官方download_tools.sh指向的sp26 Venus工具URL，固定首次实际下载SHA256为69e48a8ffecb155d1227d171ae6888be0d3e103975d04b19762a08fc9463e1cc，不将其冒称新秋季版本。验证hello/fib、7个官方lookup案例、factorial的0/1/3/7/8/12，以及memcheck；另保存原始越界、修正边界后的泄漏与最终释放对照，fib trace用于逐项核对调试题。

当前远程结果及ex2/ex3答案尚待日志核对，不计完成。网页编辑器挂载、Step/Prev交互、问卷、Gradescope尚未验收；CLI trace不能冒充手工网页操作。本地不运行编译/模拟实验，无新增Python文件。

首次a6ac0ca/run43039021877已证明功能用例和最终内存零泄漏，但浅克隆缺少基线提交，读取原始调试样例失败；现完整检出以保留演进证据。CLI trace为执行后PC/寄存器配执行前指令，且CLI参数设置令sp=0x7fffffdc；不能不加核对地冒充网页默认栈值。
