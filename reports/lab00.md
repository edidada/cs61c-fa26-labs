# Lab00 公开练习与边界

按 https://cs61c.org/fa26/labs/lab00/ Exercise5，修复已有code.py：15倍数仅一行fizzbuzz，3/5倍数分别输出，其余静默；保留无关函数和主循环。

GitHub Actions检查-100到100共201个整数及完整1..19脚本输出。在runner临时目录创建独立bare远端和两个clone，第一版仅改if条件，模拟伙伴增加组合分支，真实触发拒绝推送和合并冲突，集成两方语义后检查双亲merge、远端SHA及程序输出。该fixture是明确标注的公开Git流程复现，未冒充官方Oski提交或个人Hive操作。原init.sh包含强制推送与hard reset，保持原文件但不在真实仓库执行。

本地仅编辑与静态检查，不执行程序；无新增Python源文件。Ex1服务/Gradar身份、Ex2本人软件安装、Ex3 VPN/Hive/SSH、Ex4个人GitHub密钥、Ex5本人机器gen-debug.sh及GUI工具启动、Ex6欢迎调查和Gradescope均仍待个人环境完成；不生成虚假debug.txt，不调整用户全局Git/SSH配置。CI通过后才能验收公开代码与隔离Git流程，不等于整个校内Lab00完成。
