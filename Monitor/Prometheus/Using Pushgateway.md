# 简介

下面是 Prometheus 的架构：

![img](https://prometheus.io/assets/architecture.png)



Pushgateway 用来支持短期的监控数据收集任务。

下面是 Pushgateway github 项目上的简介：

>Prometheus pushgateway 的存在是为了允许短期或批处理任务将它们的监控指标暴漏给 Prometheus。因为这类任务可能不会长期存在以满足 Prometheus 的指标抓取，它们可以将监控指标发给 Pushgateway。
>
>**Non-goas**
>
>首先，Pushgateway 并不是要将 Prometheus 变成一个基于 PUSH 的监控系统。Pushgateway 使用场景的一般描述请看：[When To Use The Pushgateway](https://prometheus.io/docs/practices/pushing/).
>
>Pushgateway 显然不是一个 ***聚合器 或 分发平台*** ，而是一个监控指标缓存。它不是一个类 statsd 语义的。向 Pushgateway 推送的指标与在一个永久的被 Prometheus 抓取的程序中呈现的一样。如果你需要分发计算，你可以也使用 statsd ，与 Prometheus statsd exporter 一起用，或者看看 https://github.com/weaveworks/prom-aggregation-gateway 。随着经验的积累，Prometheus 项目可能有一天可以提供原生的解决方案，与 Pushgateway 分离或作为 Pushgateway 的一部分。
>
>对于机器级别的指标，Node Exporter 的 textfile 收集器通常更被偏好。Pushgateway 更倾向于服务级别的指标。
>
>Pushgateway 不是一个 ***事件存储***。当你可以用 Prometheus 作为 Grafana 的数据源，跟踪一些事情，像发布事件，发生和事件日志的框架。
>
>不久之前，我们决定不实现 timeout 或 TTL 对于推送指标，因为几乎所有提出的使用场景都能转化为 反模式，这是我们强烈的阻止的。你可以遵循一个近期的讨论在 [prometheus-developers mailing list](https://groups.google.com/forum/#!topic/prometheus-developers/9IyUxRvhY7w) 。



# 安装

1. 下载对应的发行版
2. 解压并启动 Pushgateway



# 推送数据的格式与方法

* **理解一些基本概念**：data_model, metric types, job & instance

    https://prometheus.io/docs/concepts/data_model/

    https://prometheus.io/docs/concepts/metric_types/

    https://prometheus.io/docs/concepts/jobs_instances/

* **学习推送格式**：https://github.com/prometheus/pushgateway

    ```bash
    [root@yum ~]# cat args 
    # TYPE test1_metric counter
    test1_metric{label="val1"} 42
    # TYPE another_metric gauge
    # HELP another_metric Just an example.
    another_metric 2398.283
    [root@yum ~]#
    [root@yum ~]#
    [root@yum ~]# cat args | curl -v --data-binary @- http://127.0.0.1:9091/metrics/job/some_job/instance/some_instance
    * About to connect() to 127.0.0.1 port 9091 (#0)
    *   Trying 127.0.0.1...
    * Connected to 127.0.0.1 (127.0.0.1) port 9091 (#0)
    > POST /metrics/job/some_job/instance/some_instance HTTP/1.1
    > User-Agent: curl/7.29.0
    > Host: 127.0.0.1:9091
    > Accept: */*
    > Content-Length: 149
    > Content-Type: application/x-www-form-urlencoded
    > 
    * upload completely sent off: 149 out of 149 bytes
    < HTTP/1.1 200 OK
    < Date: Thu, 30 Sep 2021 04:43:25 GMT
    < Content-Length: 0
    < 
    * Connection #0 to host 127.0.0.1 left intact
    ```

    





## HTTP PUT





## HTTP POST

```python
import requests

def push_to_gateway(cli_active, cli_waiting):
    job_name = 'pgbouncer_monitor'
    instance = '192.168.100.200'
    url = 'http://192.168.100.100:9091/metrics/job/%s/instance/%s' % (job_name, instance)

    data_temp = '''# TYPE cli_active gauge
cli_active{port="5432"} %s
# TYPE cli_waiting gauge
# HELP cli_waiting Just an example.
cli_waiting{port="5432"} %s
    '''
    try:
        requests.post(url, data=data_temp % (cli_active, cli_waiting))
    except Exception as ex:
        logging.ERROR("push error: {}".format(ex))
```





## HTTP DELETE



# 配置 prometheus 从 pushgateway 获取数据











