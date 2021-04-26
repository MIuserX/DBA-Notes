[TOC]



# 参看

------

http://wiki.corp.qunar.com/confluence/pages/viewpage.action?pageId=149556770

# 一些分析与理解

------





# 线上机器迁移

------

## 迁移前调研

### 检查新旧机器硬件及系统配置

这一步检查的主要目的是：机器提供方交付的机器是否符合工单要求。

同时还要检查新机器的参数是否与旧机器一致。

若新机器硬件配置比旧机器高那更好，如果新机器硬件配置旧机器低需要与TL沟通。



具体操作请看下列 wiki ：

http://wiki.corp.qunar.com/confluence/pages/viewpage.action?pageId=231889744

### IP 及 VIP 情况

1）观察待迁移机器的 VIP 挂载情况，保证迁移前后一致。

2）观察 DB Cluster 所有机器的 IP 和 VIP 以及新机器的 IP ，判断是否在一个网段。

### Pgbouncer 情况

1）调查所有指向待迁移 DB 实例的所有 Pgbouncer

2）应用是否都使用 pgbouncer 连接 DB 。



## 复制DB实例

### 复制机器 PostgreSQL 环境

#### postgresql rpm包：数量；版本

查看机器上安装的所有 postgresql rpm 包。

查看机器上运行的DB实例用了哪些 postgresql rpm 包。

```
# 查看 rpm 包``sudo` `rpm -qa | ``grep` `-i ``"postgresql"` `# 查看 postgresql 实例``ps` `auxww | ``grep` `"bin/post"
```



#### 扩展 rpm 包：http://wiki.corp.qunar.com/confluence/pages/viewpage.action?pageId=213214273

```
#### 下面列出了目前 PGDBA 使用的一些扩展。``# 下面将检测：``# ``sudo` `rpm -qa | ``grep` `-iE ``"^(CRF\+\+|nlpbamboo|chinese_parser|pg_tokenize)"` `sudo` `rpm -qa | ``grep` `-iE ``"^sunpinyin|qpinyin"` `sudo` `rpm -qa | ``grep` `-iE ``"^(geos|proj|gdal|json\-c|postgis)"` `sudo` `rpm -qa | ``grep` `-iE ``"^(ip4r|pg_cconv|temporal)"` `#### 每个命令列出了一组 rpm 包的以来关系和安装顺序``# 下面讲扩展安装：``#` `# 安装分词扩展 ``sudo` `rpm -ivh CRF++-0.57-1.el6.x86_64.rpm nlpbamboo-1.1.2-1.el6.x86_64.rpm chinese_parser_pg91-0.2.0-1.el6.x86_64.rpm pg_tokenize_pg91-0.2.0-1.el6.x86_64.rpm ``sudo` `ldconfig` `# 安装汉字转拼音扩展``sudo` `rpm -ivh sunpinyin-2.0.3-1.el6.x86_64.rpm qpinyin-1.0.2-1.el6.x86_64.rpm pg91_qpinyin-0.1.0-1.el6.x86_64.rpm ``sudo` `ldconfig` `# 安装 postgis 地理扩展``sudo` `rpm -ivh geos-3.5.0-1.el6.x86_64.rpm proj-4.9.2-1.el6.x86_64.rpm gdal-1.11.3-1.el6.x86_64.rpm json-c-0.11-1.el6.x86_64.rpm postgis-pg91-1.5.3-1.el6.x86_64.rpm ``sudo` `ldconfig` `# 安装 ip4r 扩展(提供 ip 相关数据类型与操作符)``sudo` `rpm -ivh ip4r-pg91-2.1.1-1.el6.x86_64.rpm``sudo` `ldconfig` `# 安装 pg_cconv 扩展(提供 简体中文 <-> 繁体中文 转换能力)``sudo` `rpm -ivh pg_cconv-pg91-0.1.0-29.el6.x86_64.rpm``sudo` `ldconfig` `# 安装 temporal 扩展(提供 时间段 相关的数据类型、函数、索引支持)``sudo` `rpm -ivh temporal-pg91-0.7.1-1.el6.x86_64.rpm ``sudo` `ldconfig
```



如何确定一个扩展是否还在被使用？



### 文件迁移

#### 所有 PGDBA 用户及 postgres 的家目录

将老机器上所有 PGDBA 用户和 postgres 用户的家目录复制到新机器。

一般放在新机器 /export/pgdba_home 目录下。

```
#### 下面的例子是将老机器 l-djb2cdb6old.vc.cn5 的 pgdba 的家目录复制到新机器 l-djb2cdb6.vc.cn5 上：` `# 新机器上接受文件``[weidi.jin@l-djb2cdb6.vc.cn5 ~]$ ``sudo` `sudo` `-s``[root@l-djb2cdb6.vc.cn5 ~]``# cd /export/pgdba_home``[root@l-djb2cdb6.vc.cn5 ``/export/pgdba_home``]``# ``[root@l-djb2cdb6.vc.cn5 ``/export/pgdba_home``]``# pwd``/export/pgdba_home``[root@l-djb2cdb6.vc.cn5 ``/export/pgdba_home``]``# ``[root@l-djb2cdb6.vc.cn5 ``/export/pgdba_home``]``# nc -l 54321 | tar -xvf - ``hailong.li/``hailong.li/.bash_history``hailong.li/.pgpass``......传送的内容太多，此处省略大部分``[root@l-djb2cdb6.vc.cn5 ``/export/pgdba_home``]``# ` `# 老机器上发送文件，务必先 cd 到 /home 目录中，再发送文件``[weidi.jin@l-djb2cdb6old.vc.cn5 ~]$ ``sudo` `sudo` `-s``[root@l-djb2cdb6old.vc.cn5 ~]``# cd /home``[root@l-djb2cdb6old.vc.cn5 ``/home``]``# ``[root@l-djb2cdb6old.vc.cn5 ``/home``]``# tar -cf - hailong.li zhanyuan.peng taot.jin zhiyin.wen jianj.qi weidi.jin postgres | nc l-djb2cdb6.vc.cn5 54321``[root@l-djb2cdb6old.vc.cn5 ``/home``]``# ` `# 如果有需要，可以用下列命令将 /export/pgdba_home/username/ 下的内容复制到对应用户的家目录中。``# 以 weidi.jin 用户为例： ``[root@l-djb2cdb6.vc.cn5 ``/export/pgdba_home/weidi``.jin]``# ls -Al``total 124``-rw------- 1 root   root      1860 Apr 4 00:20 .bash_history``-rw-r--r-- 1 weidi.jin qunarengineer  18 Oct 16 2014 .bash_logout``-rw-r--r-- 1 weidi.jin qunarengineer  190 Apr 20 2018 .bash_profile``-rw-r--r-- 1 weidi.jin qunarengineer  124 Oct 16 2014 .bashrc``drwxr-xr-x 2 weidi.jin qunarengineer 4096 Nov 12 2010 .gnome2``-rw------- 1 weidi.jin qunarengineer  64 Aug 11 2017 .pgpass``-rw------- 1 weidi.jin qunarengineer 21520 Apr 2 22:03 .psql_history``drwx------ 2 weidi.jin qunarengineer 4096 Jul 13 2017 .``ssh``-rw------- 1 weidi.jin qunarengineer 7898 Nov 5 18:25 .viminfo``-rwxr-xr-x 1 root   root     41324 Mar 5 11:18 zabbix_pg.py``[root@l-djb2cdb6.vc.cn5 ``/export/pgdba_home/weidi``.jin]``# ls -A1 | xargs -I {} cp -av {} /home/weidi.jin/```.bash_history``' -> `/home/weidi.jin/.bash_history'```.bash_logout``' -> `/home/weidi.jin/.bash_logout'```.bash_profile``' -> `/home/weidi.jin/.bash_profile'```.bashrc``' -> `/home/weidi.jin/.bashrc'```.pgpass``' -> `/home/weidi.jin/.pgpass'```.psql_history``' -> `/home/weidi.jin/.psql_history'```.``ssh``/authorized_keys``' -> `/home/weidi.jin/.ssh/authorized_keys'```.viminfo``' -> `/home/weidi.jin/.viminfo'```zabbix_pg.py``' -> `/home/weidi.jin/zabbix_pg.py'``[root@l-djb2cdb6.vc.cn5 ``/export/pgdba_home/weidi``.jin]``# 
```



#### /export 目录

大部分 DB Server 机器都有这个目录，一般该目录下只存放 DB 相关的文件，将这个目录里的文件全复制到新机器对应目录中去。

当然，不一定把所有文件都复制过去。哪些复制，哪些不复制要靠经验。

如果无法判断哪些不复制，那就把所有文件复制过去。

#### /home/q 目录

所有 DB Server 机器都有这个目录

### 任务迁移

#### postgres 用户的 crontab 任务

老机器上 postgres 用户的 crontab 任务要停掉。

#### root 用户的 crontab 任务

老机器上，PGDBA 部署在 root 用户下的 crontab 任务也要停掉。

root 用户下一般会有其他人的 crontab 任务，这些不管，不要给停错喽！

#### /etc/rc.local 文件中的开机自起任务

/etc/rc.local 文件中的开机自启动任务。

### 部署新机器 PostgreSQL 环境

#### postgresql rpm包：数量；版本

若旧机器上安装有多个版本的 postgresql rpm 包，检查下使用情况，不用的版本可以不用安装到新机器上。

还在使用的版本要安装在新机器上。

#### 扩展 rpm 包：http://wiki.corp.qunar.com/confluence/pages/viewpage.action?pageId=213214273



#### postgresql.conf

postgresql.conf 文件中的配置一般原样复制到新机器，若新机器硬件配置有提升，一般需要修改下这个配置。

#### pg_hba.conf

这个配置文件原样复制到新机器。





## 周知过保迁移信息

信息模板



## 切换新旧DB实例

关报警



开报警



## 周知过保迁移完毕消息







# beta/dev机器迁移

------

## 检查新旧机器硬件配置

这一步检查的主要目的是：机器提供方交付的机器是否符合工单要求。

同时还要检查新机器的参数是否与旧机器一致。

若新机器硬件配置比旧机器高那更好，如果新机器硬件配置旧机器低需要向TL请示。



具体操作请看下列 wiki ：

http://wiki.corp.qunar.com/confluence/pages/viewpage.action?pageId=231889744





## 检查旧机器 PostgreSQL 环境

#### postgresql rpm包：数量；版本

查看机器上安装的所有 postgresql rpm 包。

查看机器上运行的DB实例用了哪些 postgresql rpm 包。

```
# 查看 rpm 包``sudo` `rpm -qa | ``grep` `-i ``'postgresql'` `# 查看 postgresql 实例``ps` `auxww | ``grep` `'bin/post'
```



#### 扩展 rpm 包：http://wiki.corp.qunar.com/confluence/pages/viewpage.action?pageId=213214273

```
#### 下面列出了目前 PGDBA 使用的一些扩展。``# 下面将检测：``# ``sudo` `rpm -qa | ``grep` `-iE ``'^(CRF\+\+|nlpbamboo|chinese_parser|pg_tokenize)'` `sudo` `rpm -qa | ``grep` `-iE ``'^(sunpinyin|qpinyin)'` `sudo` `rpm -qa | ``grep` `-iE ``'^(geos|proj|gdal|json\-c|postgis)'` `sudo` `rpm -qa | ``grep` `-iE ``'^(ip4r|pg_cconv|temporal)'` `#### 每个命令列出了一组 rpm 包的以来关系和安装顺序``# 下面讲扩展安装：``#` `# 安装分词扩展 ``sudo` `rpm -ivh CRF++-0.57-1.el6.x86_64.rpm nlpbamboo-1.1.2-1.el6.x86_64.rpm chinese_parser_pg91-0.2.0-1.el6.x86_64.rpm pg_tokenize_pg91-0.2.0-1.el6.x86_64.rpm ``sudo` `ldconfig` `# 安装汉字转拼音扩展``sudo` `rpm -ivh sunpinyin-2.0.3-1.el6.x86_64.rpm qpinyin-1.0.2-1.el6.x86_64.rpm pg91_qpinyin-0.1.0-1.el6.x86_64.rpm ``sudo` `ldconfig` `# 安装 postgis 地理扩展``sudo` `rpm -ivh geos-3.5.0-1.el6.x86_64.rpm proj-4.9.2-1.el6.x86_64.rpm gdal-1.11.3-1.el6.x86_64.rpm json-c-0.11-1.el6.x86_64.rpm postgis-pg91-1.5.3-1.el6.x86_64.rpm ``sudo` `ldconfig` `# 安装 xxx 扩展``sudo` `rpm -ivh ip4r-pg91-2.1.1-1.el6.x86_64.rpm``sudo` `ldconfig` `# 安装 xxx 扩展``pg_cconv-pg91-0.1.0-29.el6.x86_64.rpm``sudo` `ldconfig` `# 安装 xxx 扩展``temporal-pg91-0.7.1-1.el6.x86_64.rpm``sudo` `ldconfig 
```



如何确定一个扩展是否还在被使用？



## 部署新机器 PostgreSQL 环境

#### postgresql rpm包：数量；版本

若旧机器上安装有多个版本的 postgresql rpm 包，检查下使用情况，不用的版本可以不用安装到新机器上。

还在使用的版本要安装在新机器上。

#### 扩展 rpm 包：http://wiki.corp.qunar.com/confluence/pages/viewpage.action?pageId=213214273



#### postgresql.conf

postgresql.conf 文件中的配置一般原样复制到新机器，若新机器硬件配置有提升，一般需要修改下这个配置。

#### pg_hba.conf

这个配置文件原样复制到新机器。

#### /export 目录



## crontab 任务

#### postgres 用户

老机器上 postgres 用户的 crontab 任务要停掉。

#### root 用户

老机器上，PGDBA 部署在 root 用户下的 crontab 任务也要停掉。

root 用户下一般会有其他人的 crontab 任务，这些不管，不要给停错喽！

#### 所有 PGDBA 用户

如果老机器上 PGDBA 用户也有 crontab 任务，请告知本人，

#### 除 postgres、root、PGDBA 之外的用户

PGDBA 不关心这部分用户的 crontab 任务，无需对这些用户的 crontab 任务做任何操作。

## 用户家目录

老用户 postgres 用户目录迁移到新机器 postgres 家目录

其他PGDBA的用户目录迁移到新机器 /export/pgdba_home 下

## 其他

/etc/rc.local 任务

[Like](https://wiki.corp.qunar.com/confluence/pages/viewpage.action?pageId=200170844)Be the first to like this