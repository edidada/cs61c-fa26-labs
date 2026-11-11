# CS61C Fall 2026 Lab02：C调试与内存管理

基线为官方61c-teach/fa26-lab-starter提交ae05a0313aad04ed688bb4fbd1aa7df3b8b38132；2026-11-11重新拉取确认。规范：https://cs61c.org/fa26/labs/lab02/ 。本报告为AI辅助公开自学，不冒充校内提交。

实现记录：ex1修复指针层级与返回值并释放Course；密码函数修复长度方向、闭区间和数字ASCII范围；Bork分配终止符、释放最终字符串并支持空输入；vector补全堆构造/销毁，扩容零填充保留原数据且检查大小溢出；双指针示例删除被覆盖的冗余分配。保留bad_vector_new教学反例，不调用悬空返回值；ex5保留故意的空指针崩溃供GDB定位。

ex2/ex3命令在原始/仅修正长度的中间版本上分别运行，记录修复前观察；最终修复后的密码驱动另外执行。ex5答案ben/16由远程GDB回溯核验。脚本保存编译器、GDB、Valgrind版本及所有输出，验证原始vector打印的10组等式，补充密码边界和30000步数组差分，Bork含空串/全元音/无元音。

验证仅在独立.github/workflows/lab02.yml的GitHub Actions执行，本地未编译或运行实验。当前结果待远程运行确认，恢复时查看edidada/lab02最新HEAD的运行，不以本说明代替证据。

范围限制：Ubuntu runner替代Hive，不证明课程指定机器环境；原密码/vector测试源文件未修改；Google Form内存错误测验、个人反馈问卷、Gradescope和人工CGDB界面操作未完成，不能宣布整门课程或课堂Lab全部验收。可选vector也纳入公开代码验证。

首次f81d667/run43038273993在安装gdb/valgrind时因runner的azure.archive.ubuntu.com DNS失败，尚未执行实验；改用隔离的官方archive.ubuntu.com源并限时安装，不减去GDB/Valgrind验证。另完整检出以读取原始调试版本。

162cefe和0ba874d分别尝试官方主镜像与sudo代理保留，日志确认没有HTTP代理且仍DNS失败；改用固定SHA的mamba-org/setup-micromamba提供conda-forge GDB18.1/Valgrind3.27.1，不省略调试器/内存检查。实际解析环境的显式包锁随artifact归档；是否能完成实验仍以最终远程结果为准。
