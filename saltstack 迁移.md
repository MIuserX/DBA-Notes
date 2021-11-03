[TOC]



# 参考

------

http://blog.51cto.com/ryomajia/1652592

http://www.opscoder.info/move_salt_master.html

# 重点

------

1、minion 的方面不用关心，目前要做的是复制一个 master



# 待调研

------

#### 1、我们的 rpm 包对 saltstack 做了什么特别的定制？

(1) saltstack 的安装位置

(2) saltstack master 端的配置目录



#### 2、旧 master 机器上哪些文件需要转移？

需要转移的文件并不多，就是两个目录。

/home/q/pgdba/base 目录被 git 管理，直接 clone 到新机器上即可。

/home/q/pgdba/etc/cache/pki 目录需要直接复制过去。



# 迁移方法

------

以下的 new_host 代表部署 saltstack master 的新机器。

#### A. 复制 [old_host:/home/q/pgdba/base](http://old_host/home/q/pgdba/base) 到 [new_host:/home/q/pgdba/base](http://new_host/home/q/pgdba/base)

base 目录是别 git 管理的，所以这一步使用 git clone 即可：

```bash
[root@xxx /home/q/pgdba]# git clone git@gitlab.YYY.com:pgdba/salt.git 
base Initialized empty Git repository in /home/q/pgdba/base/.git/
remote: Counting objects: 4277, done.
remote: Compressing objects: 100% (2569/2569), done.
remote: Total 4277 (delta 2914), reused 2526 (delta 1646)
Receiving objects: 100% (4277/4277), 104.18 MiB | 87.43 MiB/s, done.
Resolving deltas: 100% (2914/2914), done.
[root@xxx /home/q/pgdba]#
```



#### B. 删除 [new_host:/home/q/pgdba/etc/master](http://new_host/home/q/pgdba/etc/master) 文件

#### C. new_host 上建立软链：/home/q/pgdba/etc/master => /home/q/pgdba/base/conf/etc.master

```bash
[root@zzz /home/q/pgdba/etc]# ln -s /home/q/pgdba/base/conf/etc.master master [root@zzz /home/q/pgdba/etc]# ll
total 28
lrwxrwxrwx 1 root root  34 Oct 17 15:47 master -> /home/q/pgdba/base/conf/etc.master
-rw-r--r-- 1 root root 24084 Sep 12 20:30 minion
drwxr-xr-x 3 root root 4096 Sep 12 20:30 salt
```



#### D. 编辑 /etc/profile

```bash
# 在 /etc/profile 最后加入下面这行
export SALT_MASTER_CONFIG=/home/q/pgdba/etc/master
```



#### E. 复制 [xxx](http://xxx:/home/q/pgdba/etc/salt/pki](http://com/home/q/pgdba/etc/salt/pki) 目录到 [new_host:/home/q/pgdba/etc/salt/pki](http://new_host/home/q/pgdba/etc/salt/pki)



#### F. 启动 new_host 上的新 master

```bash
[root@zzz /home/q/pgdba]# /etc/init.d/pg-salt-master start
Starting salt-master daemon:                [ OK ]
```



#### G. 在 salt minion 配置文件中写入新的 master 主机地址，与老 master 主机地址并列



#### H. 重启 salt minion



# saltstack 常见问题

------

## 1、master 和 minion 不通

### 现象

master 端 test.ping 某个 minion 时，显示 No response 类似的结果。

### 可能原因及解决方案

#### 1、salt multi-master 模式下 master 之间的公私钥不一致

到能正常连接 minion 端的 master 上，将 xxx 复制到不正常的 master 上相应路径。

出现这种问题时，minion 端的报错日志如下：

```
2018``-``11``-``15` `10``:``04``:``39``,``100` `[salt.crypt                             :``1015``][ERROR  ][``4169``] The master failed to decrypt the random minion token``2018``-``11``-``15` `10``:``04``:``39``,``101` `[salt.crypt                             :``741` `][CRITICAL][``4169``] The Salt Master server's ``public` `key did not authenticate!``The master may need to be updated ``if` `it is a version of Salt lower than ``2018.3``.``0``, or``If you are confident that you are connecting to a valid Salt Master, then remove the master ``public` `key and restart the Salt Minion.``The master ``public` `key can be found at:``/home/q/pgdba/etc/salt/pki/minion/minion_master.pub``2018``-``11``-``15` `10``:``04``:``39``,``102` `[tornado.application                        :``124` `][ERROR  ][``4169``] Future exception was never retrieved: Traceback (most recent call last):`` ``File ``"/home/q/pg-python/lib/python2.7/site-packages/tornado/gen.py"``, line ``876``, in run``  ``yielded = self.gen.``throw``(*exc_info)`` ``File ``"/home/q/pg-python/lib/python2.7/site-packages/salt/transport/zeromq.py"``, line ``491``, in wrap_callback``  ``payload = yield self._decode_messages(messages)`` ``File ``"/home/q/pg-python/lib/python2.7/site-packages/tornado/gen.py"``, line ``870``, in run``  ``value = future.result()`` ``File ``"/home/q/pg-python/lib/python2.7/site-packages/tornado/concurrent.py"``, line ``215``, in result``  ``raise_exc_info(self._exc_info)`` ``File ``"/home/q/pg-python/lib/python2.7/site-packages/tornado/gen.py"``, line ``876``, in run``  ``yielded = self.gen.``throw``(*exc_info)`` ``File ``"/home/q/pg-python/lib/python2.7/site-packages/salt/transport/zeromq.py"``, line ``468``, in _decode_messages``  ``ret = yield self._decode_payload(payload)`` ``File ``"/home/q/pg-python/lib/python2.7/site-packages/tornado/gen.py"``, line ``870``, in run``  ``value = future.result()`` ``File ``"/home/q/pg-python/lib/python2.7/site-packages/tornado/concurrent.py"``, line ``215``, in result``  ``raise_exc_info(self._exc_info)`` ``File ``"/home/q/pg-python/lib/python2.7/site-packages/tornado/gen.py"``, line ``876``, in run``  ``yielded = self.gen.``throw``(*exc_info)`` ``File ``"/home/q/pg-python/lib/python2.7/site-packages/salt/transport/mixins/auth.py"``, line ``63``, in _decode_payload``  ``yield self.auth.authenticate()`` ``File ``"/home/q/pg-python/lib/python2.7/site-packages/tornado/gen.py"``, line ``870``, in run``  ``value = future.result()`` ``File ``"/home/q/pg-python/lib/python2.7/site-packages/tornado/concurrent.py"``, line ``215``, in result``  ``raise_exc_info(self._exc_info)`` ``File ``""``, line ``3``, in raise_exc_info``SaltClientError: Invalid master key
```



## 2、master 上执行 test.ping (或其他)命令发现有多个相同的 hostname 回复

### 现象

```bash
# 产生了两个 centos03 
[root@centos02 master]# pg-salt 'centos0[1-3]' test.ping
centos01:  True
centos03:  True
centos03:  True
```



### 可能原因及解决方案

#### 1、minion 机器上起了多个 pg-salt-minion 进程

解决：直留一个 pg-salt-minion 进程就行

#### 2、minion 端的配置文件中把同一个 master 机器配置了两遍

```
# 下面是 minion 端 xxx 文件的一个片段，
# centos01 和 centos02.qunar.com 是一个机器，
# 但被写了两次，导致 master 端(centos2) 得到了两次回应。
#
......
master: 
  - centos02 
  - centos02
  - xxx
  - zzz
  ......
......
```



解决：每个 master 机器在配置文件中只写一次



# Multi-master 模式下的 BUG

------

根据 saltstack 官方网站的说法，multi-master 模式下 minion 端偶尔会发生不响应的状况。



# 方案制定

------

1、在新机器上装一个 pg-salt master

2、复制老 master 的文件到新 master

3、用老 master 修改一部分 minion 的配置

　 (1) 修改 master 和 master_port

　 (2) 删除 minion_master.pub 文件

4、重启修改过配置文件的 minion，与新 master 联调