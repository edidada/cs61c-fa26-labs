# CS61C Fall 2026 Lab06

规范：https://cs61c.org/fa26/labs/lab06/ 。基线为官方 main 的 ae05a0313aad04ed688bb4fbd1aa7df3b8b38132。独立分支 edidada/lab06，工作流 lab06.yml 调用 scripts/verify_lab06.sh。本地只编辑、解析 XML 和检查差异；模拟与测试全部交由 Actions。Java 仅用于官方 Logisim 运行时，本实验为数字电路实验。

## 实现

- ex1 用 splitter 提取 instruction[31:25]、[11:7]，拼成 12 位 S 型立即数；输出高 20 位均接 instruction[31]，完成符号扩展。
- ex2 用 funct3 的位 2 和位 1 相与，unsigned 分支 110/111 输出 1，signed 100/101 输出 0，其余按照规范 don't care 选择确定输出。
- ex3 原电路保持不变。输入寄存器 CLK-to-Q 10ns、乘法 60ns、加法 45ns、目的寄存器 setup 10ns，总计 125ns。hold 5ns 属于最短路径约束，不额外加入最大路径。
- ex4 插入 8 位乘积寄存器，再由累加寄存器逐周期累加，模 256。乘法级为 10+60+10=80ns，加法级为 10+45+10=65ns，因此周期下限 80ns，最高频率 12.5MHz。输出相比非流水版本多一个前导零；每周期乘积独立，累加反馈仅在第二级，无需气泡。
- ex5 修正 odd/even 常量、5/10 的匹配常量，将 upper28 与零比较的错误 LT 输出改为 unsigned GT，覆盖最高位为 1 的输入。保留其余原始结构与全部引脚，新增独立 num_cycles 计数寄存器。

## 答案与验证边界

ex5_answers 描述修复前电路：周期 0/1 输入 200/201，bit_zero 为 0/1，错误 is_odd 为 1/0；周期 3/4 输入 15/17，错误 greater_than_fifteen 均为 0；周期 5 的 bits_five=0b101，但错误 five_or_ten=0。工作流隔离恢复原始电路，用原始 ROM 驱动观测错误输出；修复版本继续使用全部未修改的原始驱动和参考轨迹。

原始 test.py 失败仍返回 0，因此脚本额外断言 Passed 4/4 并逐文件 diff。补充覆盖全部 4096 个 S 立即数各两组无关位、全部 128 opcode ×8 funct3，以及 0..255 和无符号 32 位边界。官方工具按 SHA256 固定。当前尚待远端执行结果，不能提前计为验收成功。

GUI 的 Timing Diagram、Add or Remove Signals、手工逐周期探测未执行；CLI 观测不能冒充这些 GUI 操作。个人反馈问卷、Gradescope 未提交。

首轮实现 c2d31d6 的远端 run43222678219 已 completed/success：原始4/4轨迹、8192立即数、1024控制、270数字边界全部通过。原始buggy CSV也已观测并断言，工件cs61c-lab06-results包含全部向量与日志。最终文档提交仍由同一独立工作流重新验证。
