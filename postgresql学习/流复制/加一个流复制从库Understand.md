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

#### WAL 级别

流式复制是通过 Master 向 Standby 发送 WAL，Standby 重放 WAL 完成的，而 Master 记录 WAL 是分级别的。要搭建流复制集群，Master 首先做的是设置 <span style="color:lightblue">wal_receiver_timeout</span> 到支持流复制的级别。



#### 准备 WAL sender 和 replication slot

* <span style="color:lightblue">wal_sender_timeout</span>
* <span style="color:lightblue">max_wal_senders</span>
* <span style="color:lightblue">max_replication_slot</span>





#### 同步复制 VS 异步复制

一般使用异步复制就已经满足很多的业务要求了。但如果需要同步复制，就需要配置如下参数：

**synchronous_standby_names**

配置要求同步复制的 standby 的服务器名字。



**synchromous_commit**

配置同步复制的级别。





#### 防止从库追不上

* <span style="color:lightblue">wal_keep_segments</span>
* <span style="color:lightblue">vacuum_defer_cleanup_age</span>







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



#### readonly

一般情况下，从库是可以执行只读查询的。PG 允许通过参数来控制是否开启 readonly。相关的参数如下：

* <span style="color:lightblue">hot_standby</span> (boolean)
* <span style="color:lightblue">hot_standby_feedback</span> (boolean)
* <span style="color:lightblue">max_standby_streaming_delay</span> (integer)
* <span style="color:lightblue">max_standby_archive_delay</span> (integer)

如果开启 readonly，有可能会出现这样的场景：

> Standby 上的 SQL A 开始执行，在执行的过程中，它所需要的数据被 Master 上的 SQL B 删除了。收到 WAL 需要决定是取消 SQL A 的执行还是延迟 replay WAL 。
>
> 这是因为在一个 Node 上的 SQL 处于一个上下文中，DBMS 可以检测到这种情况，并自行决定。但 Master 和 Standby 显然是两个上下文。
>
> 那有没有办法让他们在一个上下文呢？

<span style="color:lightblue">hot_standby_feedback</span> 是这样参数，它允许 Standby 向 Master 发送正在执行的 readonly SQL 的信息。发送信息的频率受 <span style="color:lightblue">wal_receiver_status_interval</span> 限制。

WAL 总是要被 replay 的，当 Standby 通过 WAL archive 获取 WAL 时，Standby 会在冲突发生时最多延迟 <span style="color:lightblue">max_standby_archive_delay</span> 时间后，取消 SQL 并 replay SQL。当 Standby 通过 streaming replication 获取 WAL 时，Standby 会在冲突发生时最多延迟 <span style="color:lightblue">max_standby_streaming_delay</span> 时间后，取消 SQL 并 replay SQL。









## synchronous replication



# Replication slot

复制槽的存在是为了解决如下问题：

> WAL segments 需要在所有 Standby 接收到之后才能够被删除。

这里需要讲些关于流复制的历史。

replication slot 在 9.4 才被引入，在这之前，通过 <span style="color:lightblue">wal_keep_segments</span> 来解决这个问题，但这个方法非常粗糙，只是通过保留尽可能多的 WAL segments 来保证。如果 Standby 断开时间过长，可能会发生需要的 WAL segments 已经被删除的问题，这是 Standby 将无法进行 streaming replication。

但复制槽仅仅保留那些还被 Standby 需要的，不会保留多余的，解决的更加精确。





# hot_standby_feedback





# Reference Links

https://hevodata.com/learn/postgresql-replication-slots/

https://www.cybertec-postgresql.com/en/what-hot_standby_feedback-in-postgresql-really-does/

