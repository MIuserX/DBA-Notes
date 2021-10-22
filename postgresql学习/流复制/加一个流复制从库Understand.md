# 讨论什么？

以渐近式的思路讨论，在已经存在一个 PG 实例的情况下，如何增加一个从库？

其中主要讨论如何设置配置参数。



# 开始讨论

从 Master 的角度来看，要增加一个 Standby，肯定需要付出一些代价。

直接能想到的就有：

* 需要出一个 WAL Sender Process 来发送 WAL
* 可能需要增加保留的 WAL 数量，防止 Standby 断了

此外还有付出一些其他的代价，不再详述，毕竟不是讨论的主题。



## Master 需要做什么准备？

* 进行一次 basebackup ，作为 Standby 的起点
* `wal_level` 调整到满足流复制的级别
* `max_wal_senders` 设置 wal sender process 的数量上限
* `max`



#### 同步复制 VS 异步复制

一般使用异步复制就已经满足很多的业务要求了。但如果需要同步复制，就需要配置如下参数：

**synchronous_standby_names**

配置要求同步复制的 standby 的服务器名字。



**synchromous_commit**

配置同步复制的级别。





#### 防止从库追不上

**wal_keep_segments**





## Standby 需要做什么准备？

#### 从谁哪获取 WAL？

standby 需要知道的第一件是：从谁哪复制？

这需要在 recovery.conf 中配置 

* <span style="color:lightblue">primary_info</span>



#### WAL receiver process 的行为

与 Master 拥有 WAL sender process 相对，Standby 拥有 WAL receiver process。 PG 允许我们对 WAL receiver process 做一些配置，相关的参数有：

* <span style="color:lightblue">wal_receiver_timeout</span>
* <span style="color:lightblue">wal_receiver_status_interval</span>

WAL receiver process 通过 TCP 连接从 WAL sender process 那里获取 WAL，如果 Master 发生了 crash 或者网络发生了中断等导致 WAL receiver process 进程不活跃的事情，WAL receiver process  将在 **wal_receiver_timeout** 毫秒后退出。  

WAL receiver process 不仅仅是单向的从 Master 哪获取信息，还会向 Master 反馈一些信息。例如：流复制过程的信息。**wal_receiver_status_interval** 参数指示向 Master 发送信息的频率。



美好的日子里，Standby 不断获取 WAL（无论是通过 streaming replication、local pg_wal 或者 WAL archive）并 replay。但偶尔也会出一些意外，比较极端的情况下，Standby 无法通过任何途径获取到 WAL 。这时参数：

* <span style="color:lightblue">wal_retrieve_retry_interval</span>

有了用武之地。这个参数



一般情况下，从库是可以执行只读查询的。PG 允许通过  参数来控制是否开启 readonly。相关的参数如下：

* <span style="color:lightblue">hot_standby</span> (boolean)
* <span style="color:lightblue">hot_standby_feedback</span> (boolean)
* <span style="color:lightblue">max_standby_streaming_delay</span> ()
* <span style="color:lightblue">hot_standby_feedback</span> ()

如果开启 readonly，





