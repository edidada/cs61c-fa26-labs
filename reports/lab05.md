# CS61C Fall2026 Lab05：数字电路

官方规范：https://cs61c.org/fa26/labs/lab05/ 。基线ae05a0313aad04ed688bb4fbd1aa7df3b8b38132。独立edidada/lab05分支和lab05.yml，不切换其他实验worktree。

ex2保留原AND2样例，仅使用AND/OR/NOT构建NAND2、NOR2、XOR2、MUX2和MUX4。MUX4选择号为SEL0+2*SEL1，选择A/B/C/D。没有用禁止的内置NAND/NOR/XOR/MUX替代基础门练习，也没有更名或增加子电路。

ex3使用8位加法器和上升沿寄存器，ADD_OUT=REG_OUT+1模256，时钟来自原始clk引脚。ex4固定旋转子电路用16路splitter按位重连，输出位i接输入位(i+n) mod16；RotRight串接rot1/rot2/rot4/rot8及4个16位MUX，按AMOUNT四个位选择，不使用移位器或时序元件。使用有标签的tunnel保持连接清楚，保留所有原始引脚和外观接口。

原始测试驱动、hash校验、测试电路和参考输出均保留。原test.py即使失败也退出0，所以脚本额外检查Passed 3/3、没有FAILED并逐字diff三份输出。补充基础门/MUX穷举84组、24种16位模式在所有16种旋转量下共384组测试向量；Logisim使用官方download_tools.sh对应的sp26地址，版本与SHA256保存在工件。

本地只修改/静态解析XML和脚本，不执行模拟器、不编译或运行实验。Java仅是官方Logisim的运行时，本实验属于数字电路项目。Actions使用Xvfb和原始CLI测试，不冒充GUI手工Poke、连线与Tick操作。个人反馈、可选期中问卷、Gradescope及GUI课堂操作未执行；最终代码验收须看对应最终SHA的完整Actions结论，当前不预先宣称通过。
