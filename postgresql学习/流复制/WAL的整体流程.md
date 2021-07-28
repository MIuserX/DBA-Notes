## 参考

https://www.postgresql.org/docs/11/wal.html



## 文档引用

##### R1

As described in the previous section, transaction commit is normally *synchronous*: the server waits for the transaction's WAL records to be flushed to permanent storage before returning a success indication to the client.

##### R2

If `synchronous_standby_names` is empty, the only meaningful settings are `on` and `off`; `remote_apply`, `remote_write` and `local` all provide the same local synchronization level as `on`. The local behavior of all non-`off` modes is to wait for local flush of WAL to disk. In `off` mode, there is no waiting, so there can be a delay between when success is reported to the client and when the transaction is later guaranteed  to be safe against a server crash. (The maximum delay is three times [wal_writer_delay](https://www.postgresql.org/docs/11/runtime-config-wal.html#GUC-WAL-WRITER-DELAY).) Unlike [fsync](https://www.postgresql.org/docs/11/runtime-config-wal.html#GUC-FSYNC), setting this parameter to `off` does not create any risk of database inconsistency: an operating system or database crash might result in some recent allegedly-committed  transactions being lost, but the database state will be just the same as if those transactions had been aborted cleanly. So, turning `synchronous_commit` off can be a useful alternative when performance is more important than exact certainty about the durability of a transaction. For more  discussion see [Section 30.3](https://www.postgresql.org/docs/11/wal-async-commit.html).

If [synchronous_standby_names](https://www.postgresql.org/docs/11/runtime-config-replication.html#GUC-SYNCHRONOUS-STANDBY-NAMES) is non-empty, `synchronous_commit` also controls whether transaction commits will wait for their WAL records to be processed on the standby server(s).

When set to `remote_apply`,  commits will wait until replies from the current synchronous standby(s)  indicate they have received the commit record of the transaction and  applied it, so that it has become visible to queries on the standby(s),  and also written to durable storage on the standbys. This will cause  much larger commit delays than previous settings since it waits for WAL  replay. When set to `on`, commits wait until  replies from the current synchronous standby(s) indicate they have  received the commit record of the transaction and flushed it to durable  storage. This ensures the transaction will not be lost unless both the  primary and all synchronous standbys suffer corruption of their database storage. When set to `remote_write`, commits will wait until replies from the current synchronous standby(s)  indicate they have received the commit record of the transaction and  written it to their file systems. This setting ensures data preservation if a standby instance of PostgreSQL  crashes, but not if the standby suffers an operating-system-level crash  because the data has not necessarily reached durable storage on the  standby. The setting `local` causes commits  to wait for local flush to disk, but not for replication. This is  usually not desirable when synchronous replication is in use, but is  provided for completeness.

##### R3

Streaming replication allows a standby server to stay more up-to-date  than is possible with file-based log shipping. The standby connects to  the primary, which streams WAL records to the standby as they're  generated, without waiting for the WAL file to be filled.



## 头脑风暴

* 做修改的 SQL 与 WAL 生成的过程
* WAL 写入 WAL Segments 的过程
* WAL Sender 从哪拿 WAL？
* WAL Receiver 收到 WAL 后怎么处理的？





* SQL 执行（改变发生）
* WAL 生成在内存中
* WAL 被写入到磁盘中
* 给 Client 返回 SQL 执行成功的标志
* WAL Sender 将生成的 WAL Records 发送给 WAL Receiver
* WAL Receiver 收到 WAL Records 后写入到 File System
    * **remote_write**
* 将 WAL Records 刷写到磁盘中
    * **on**
* 已经 WAL 应用到数据文件，可被查看
    * **remote_apply**

