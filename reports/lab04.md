# CS61C Fall 2026 Lab04：RISC-V调用约定

官方规范：https://cs61c.org/fa26/labs/lab04/ 。2026-11-12核对官方最新main为ae05a0313aad04ed688bb4fbd1aa7df3b8b38132；使用独立edidada/lab04分支。原始测试驱动和check_arr保留，ex2/ex3只新增指令，验证脚本检查原始行顺序与无删除行。

ex1的pow保存恢复s0；inc_arr保存ra/s0/s1，并在调用helper_fn前保存t0、返回后恢复。t1的值在调用后不再使用，所以无需保留。helper_fn虽不是原始.globl导出函数，也要保存恢复其写入的s0。栈帧取16字节，保证每次调用前后sp恢复。

ex2在入口给原有sw s0分配栈空间，保存ra，出口恢复s0/ra和sp。ex3只在非零指数递归路径分配栈帧，保存ra和之后仍需使用的t0；零指数不递归，因此直接返回。原有标签、分支、乘法和return指令未修改。

题目回答：next_test、pow_loop、pow_end属于函数内部标签，不是独立函数。helper_fn未导出，CC检查器未必能检测其问题；不能把无警告当作完整证明。pow缺少s0保存恢复；inc_arr既是callee又是caller，要保存自己的callee-saved寄存器，并维护跨调用存活的t0和返回地址ra。示例func1初始sp=0x7ffffff0时，s0保存地址0x7fffffec，t0保存地址0x7fffffe4，出口sp仍为0x7ffffff0。

独立lab04.yml仅调用scripts/verify_lab04.sh，构建/运行仅在Actions。使用官方download_tools.sh所选sp26 Venus URL和已固定SHA256；Java17仅为RISC-V模拟器运行时，本项目不是Java实验。验证原始ex1/ex2/ex3的实际失败、修复后的原始输出、16组递归边界（含零指数、负底数和32位溢出）、4组寄存器/栈/空数组/整数溢出哨兵调用，并将helper_fn导出以加强CC检查。所有日志随工件保存，最终SHA和结论以Actions为准；当前不预先宣称通过。

这是AI辅助公开自学实现。Venus网页挂载与手工交互、个人反馈问卷及Gradescope提交未执行；CLI结果不能代替这些课堂环节。本地未编译或运行实验。
