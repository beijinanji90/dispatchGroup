# dispatchGroup
1、模拟多个异步网络，同时结束
2、第一种使用dispatch_group_create() + dispatch_group_enter + dispatch_group_leave
3、第二种dispatch_group_create() + dispatch_semaphore_wait + dispatch_semaphore_signal
