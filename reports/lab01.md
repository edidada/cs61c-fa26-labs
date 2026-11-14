# Lab01 公开练习

六个C练习：Hello、值传递与一/二级指针、int8/int16数组寻址、字符串终止/复制/拼接、结构体初始化与字段访问。指针打印显式转void*，size_t用%zu；保留值传递不影响调用者的教学对照。

远端脚本以C11严格警告和ASan/UBSan构建六程序，断言具体输出和地址差2/4/2，而非固定ASLR地址。结构体16字节断言仅适用于本工作流Linux x86_64 ABI，不是C语言跨平台保证。增加Exercise1完整编译生命周期：原Hello World构建后，复制改为Hello 61C的源码但不构建，旧二进制保持原输出，再重编译输出Hello 61C。最终状态须由最终提交CI验证。

官方页面：https://cs61c.org/fa26/labs/lab01/ 。官方要求Hive执行，本次用GitHub临时runner公开自学验证，不冒充Hive操作。Exercise7反馈、Exercise8 AutoRemind、个人账号与Gradescope不冒充自动完成。本地不编译运行；没有新增Python源文件。
