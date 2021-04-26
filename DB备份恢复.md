[TOC]



# 概述

这里简单说一下 Qunar PG 数据库的备份工作。

备份任务实际上是一个 crontab 任务，一般挂在 postgres 用户下。

备份程序是一个 bash 脚本，由 pg-saltstack 管理(部署)。

机器上一般保存最近几天的备份，除非是要恢复较老的备份时需要到远程主机上取回备份，一般用本地的备份就行。



下面以 l-djb2cdb[12-14].vc.cn6 这套 pg 集群举例，

l-djb2cdb12.vc.cn6:5432 是主库，l-djb2cdb[13-14].vc.cn6:5432 是从库。

### 1、确定备份机器及备份任务的基本信息

制作备份 crontab 任务一般在 PG 集群的从库机器上的 postgres 用户下：

```
# l-djb2cdb[12-14].vc.cn6:5432 这套 pg 集群的备份任务在``# l-djb2cdb14.vc.cn6 这个机器上，``#` `[postgres@l-djb2cdb14.vc.cn6 ~]$ ``crontab` `-l``# Lines below here are managed by Salt, do not edit``MAILTO=pg-alert@qunar.com``# SALT_CRON_IDENTIFIER:compress_pglog_cron``20 0 * * * ``bash` `/home/q/pgdba/scripts/compress_pglog``.sh 1>> ``/home/q/pgdba/log/compress_pglog``.log``# SALT_CRON_IDENTIFIER:pitr_backup_djb2c6_cron``0 3 * * * ``bash` `/home/q/pgdba/scripts/pitr_backup``.sh ``/home/q/pgdba/conf/djb2c6_config``.sh 1>> ``/home/q/pgdba/log/pitr_backup_djb2c6``.log ``#---> 这个就是备份脚本
```



可以在备份配置文件 /home/q/pgdba/conf/djb2c6_config.sh 中查看备份的一些信息：

```
# 下面是配置文件 l-djb2cdb14.vc.cn6:/home/q/pgdba/conf/djb2c6_config.sh``# 的一部分内容：``# product 是业务线号，是由pgdba小组决定的，一般这个概念只对 pgdba 有用，对数据库使用方是透明的，``# xlog_dir 是存放本地备份的目录，一般会保存最近几天的备份文件，``# backup_keep_days 设置本地备份保留的天数，``# rsync_dest 是远程备份的地址，``# rsync_pwd 是远程备份的密码``#``...` `# 产品 tag，一台机器多个产品的话，使用此 tag 来区分目录``product=``'djb2c6'` `...` `# 从库用来备份 xlog 目录，和用来实时同步的 wal log 目录``xlog_dir=``"/export/${product}_xlog_archive/"` `...` `########### 可选配置 ##``# 本地备份保留多久,不设置将永久保留``bakup_keep_days=3` `# rsync 远端地址``rsync_dest=``'root@l-sclt1.ops.cn2.qunar.com::CN2_MFS_DB_PG_DJB2C6/'``rsync_pwd=``'xxx-xxx-xxx-xxx'` `...
```



从上面的配置文件中可知，备份文件存放的目录是 /export/product_xlog_archive/，可以进去看看：

```
# 这篇wiki创建于 2018-08-01``#``#` `[postgres@l-djb2cdb14.vc.cn6 ``/export/djb2c6_xlog_archive``]$ ll``total 130032752``-rw-r--r-- 1 postgres postgres     256 May 7 2016 2016-05-06.key``-rw-r--r-- 1 postgres postgres 17709158432 May 7 2016 2016-05-06.``tar``.e``-rw-r--r-- 1 postgres postgres     256 May 29 2016 2016-05-28.key``-rw-r--r-- 1 postgres postgres 16832931872 May 29 2016 2016-05-28.``tar``.e``-rw-r--r-- 1 postgres postgres     256 Oct 24 2017 2017-10-23.key``-rw-r--r-- 1 postgres postgres 22881239072 Oct 24 2017 2017-10-23.``tar``.e``-rw-r--r-- 1 postgres postgres     256 Jun 5 04:02 2018-06-04.key``-rw-r--r-- 1 postgres postgres 21395394592 Jun 5 04:04 2018-06-04.``tar``.e``-rw-r--r-- 1 postgres postgres     256 Jul 31 04:08 2018-07-30.key``-rw-r--r-- 1 postgres postgres 27059056672 Jul 31 04:10 2018-07-30.``tar``.e``-rw-r--r-- 1 postgres postgres     256 Aug 1 04:09 2018-07-31.key``-rw-r--r-- 1 postgres postgres 27274926112 Aug 1 04:11 2018-07-31.``tar``.e``drwxr-xr-x 2 postgres postgres    4096 Aug 1 04:09 2018-08-01``drwxr-xr-x 2 postgres postgres   741376 Aug 1 20:27 realtime
```



# 步骤

------

### 1、确认备份任务所在的机器

确认备份任务在集群的那台机器上运行。

### 2、从远程主机取回备份(不是必须步骤)

这一步不是必须步骤，如果本地备份满足需求，则无需拉取远程备份，否则需要进行该步骤。

Qunar PostgreSQL 数据库机器上一般会有 /export 目录(也可能是个软链)，数据目录一般会放在这个目录下。

拉取远程备份文件到本地时，最好在该目录下，保证磁盘撑的住。

从备份任务配置文件中获取 远程备份地址、密码 的信息，然后执行如下命令：

```
# 查看 rsync 远程地址与密码，XXX 是对应的业务线号``grep` `'rsync'` `/home/q/pgdba/conf/XXX_config``.sh` `# 设置 rsync 密码``export` `RSYNC_PASSWORD=``'*************'` `# 获取加密 key 到当前目录``rsync` `-avP root@l-sclt1.ops.cn2.qunar.com::CN2_MFS_DB_PG_TKT2``/2017-12-20``.key .` `# 获取备份数据到当前目录``rsync` `-avP root@l-sclt1.ops.cn2.qunar.com::CN2_MFS_DB_PG_TKT2``/2017-12-20``.``tar``.e .
```



### 3、解密备份文件

```
# 解密 tar 包``cat` `2017-12-20.``tar``.e | ``/home/q/pgdba/scripts/qsec``.sh -d ``/home/q/pgdba/conf/ticket2_aes256``.pem 2017-12-20.key > 2017-12-20.``tar` `# 将 2017-12-20.tar 中的 2017-12-20/l-pgdb7.tkt.cn5-*.tar.gz 文件解压出来``tar` `-xvf 2017-12-20.``tar` `2017-12-20``/l-pgdb7``.tkt.cn5-*.``tar``.gz
```



### 4、解压备份文件

如果备份文件很大，加压可能需要较长时间。

```
# 解压 *-data-* 和 *-xlog-* 这俩包``tar` `-zxvf l-pgdb7.tkt.cn5-data-2017-12-20.``tar``.gz &>``/dev/null``tar` `-zxvf l-pgdb7.tkt.cn5-xlog-2017-12-20.``tar``.gz &>``/dev/null` `tar` `-zxvf &>``/dev/null
```



### 5、复制并解压当天 xlog 文件

这一步不是必须步骤，如果恢复的不是当天的数据，就不用复制 xlog 了。

```
ll | ``awk` `'{print $NF}'` `| ``xargs` `-I {} gunzip {}
```



### 6、编写 recovery.conf 文件

准备该文件的目的是：启动一个只读实例。

实际上不要该文件也是可行的，这样启动的就是个可读可写的实例。

```
standby_mode=``'on'``restore_command=``'cp /export/backup_tmp/2018-08-01/%f %p'``recovery_target_time=``'2018-08-01 17:18:00 +08'``recovery_target_inclusive=``false``recovery_target_action=pause
standby_mode=``'on'``restore_command=``'cp /export/backup_tmp/2018-08-01/%f %p'``recovery_target_timeline=``'latest'``recovery_target_inclusive=``false``recovery_target_action=pause
```



### 7、修改临时实例的端口号

改成一个不跟已有端口号冲突的端口号就行。



### 8、启动实例，开始恢复备份

启动之前，切记修改监听端口号，不要跟机器上已有的 pg 实例冲突。

```
/opt/pg10/bin/pg_ctl` `-D xxx start
```