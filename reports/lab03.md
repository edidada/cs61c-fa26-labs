# CS61C Fall2026 Lab03：RISC-V与Venus

公开程序与调试答案在d7f94fb的[Actions 43040403080](https://github.com/edidada/cs61c-fa26-labs/actions/runs/43040403080)全部通过，结果原文保存reports/lab03-results.json。报告归档后的最终提交由同一独立lab03.yml再次验证，查看分支edidada/lab03最新HEAD对应运行。本地未编译或运行模拟器。

来源为[Fall2026 Lab3规范](https://cs61c.org/fa26/labs/lab03/)，官方starter ae05a0313aad04ed688bb4fbd1aa7df3b8b38132。当前官方download_tools.sh仍指向sp26 Venus，SHA256固定69e48a8ffecb155d1227d171ae6888be0d3e103975d04b19762a08fc9463e1cc。网页另直接访问https://venus.cs61c.org/，按观察日记录，不冒称与JAR同版本。

hello输出2026。内存循环严格小于10，保存分配基址并释放；离散函数只用偏移加3、左移2、基址寻址和lw，除原有jr ra外无分支/跳转；factorial用初始化的迭代乘积，覆盖0/1/3/7/8/12。原始7例tester与fib未改，测试程序的打印结果另做断言，最终memcheck明确0字节0块。

Chromium实际编辑器载入、组装、Step/Prev、查看内存0x10000000字节0C、设置0x28断点、停靠七次、十进制切换和最终输出144均通过。七次t0为1/1/2/3/5/8/13。11个ex2答案逐项与网页实际值比较；sp实测0x7fffffdc，保存在browser.json，未凭历史默认值填答。截图在output/playwright/。

ex3八题来自原始与中间版真实运行：无memcheck越界0x10008058；memcheck越界0x10008080、分配40字节、18行、索引10；仅修边界后泄漏40字节位于0x10008058。脚本对错误日志与最终零泄漏同时断言，避免预期错误因工具未运行而被误报成功。

首次a6ac0ca因浅克隆缺少基线，完整检出修复；db6d48c的浏览器探针将0C当作十进制解析，现用十六进制解析；这些验证脚本问题已在d7f94fb修正，不修改原始tester的期望。

这是AI辅助公开自学结果。网页文件系统挂载尚未验证，个人反馈问卷和Gradescope未执行，不代表校内全部环节通过，也不代表整门课程完成。
