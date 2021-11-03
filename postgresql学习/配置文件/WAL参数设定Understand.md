# 头脑风暴

* WAL 从产生到别写入磁盘的整个过程是什么样的？
* 从 WAL 的声明周期中理解相关参数



# Preview





# Main





## WAL basic settings

```sql

-- WAL 产生 --
wal_level: 决定WAL中记录内容的种类与多少

-- WAL 在内存中 --
wal_buffers: WAL能使用多大的缓冲区，缓冲区是 shared_buffers 的一部分

-- WAL 写入 Disk --
wal_writer_delay:
wal_writer_flush_after:

wal_sync_method: 
fsync:
```



### synchronous_commit





### WAL 什么时候写入磁盘？

有3个条件会触发 WAL 刷入磁盘：

1. 距离上次写入间隔事件达到 <span style="color: lightblue">wal_writer_delay</span> 毫秒
2. 未写入的 WAL size 达到  <span style="color: lightblue">wal_writer_flush_after</span> 字节
3. 被异步提交事务触发

否则 WAL 仅被写入 OS。







## Checkpoints





## Archiving



# Reference Links

