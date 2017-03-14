//
//  ViewController.m
//  dispatchBarrierPhone
//
//  Created by chenfenglong on 2017/3/13.
//  Copyright © 2017年 chenfenglong. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic,copy) NSString *textName;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self addTextObserve];
}

- (void)addTextObserve
{
    [self addObserver:self forKeyPath:@"textName" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"textName"]) {
        NSLog(@"发生变化了");
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
}

- (void)useDispatchGroupSemaphoreSignal
{
    //信号量
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    //创建全局并行
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    //任务一
    dispatch_group_async(group, queue, ^{
        [self getAdvertList:^{ //这个block是此网络任务异步请求结束时调用的,代表着网络请求的结束.
            //一个任务结束时标记一个信号量
            dispatch_semaphore_signal(semaphore);
        }];
    });

    //任务二
    dispatch_group_async(group, queue, ^{
        [self getHotCultureList:^{
            dispatch_semaphore_signal(semaphore);
        }];
    });
    
    dispatch_group_notify(group, queue, ^{
        //6个任务,6个信号等待.
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        NSLog(@"我全部都结束了之后了");
    });
}

- (void)useDispatchGroupEnterAndLeave
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    //通过dispatch_group_enter模拟信号量
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    dispatch_async(queue, ^{
        [self getHotCultureList:^{
            dispatch_group_leave(group);
        }];
    });
    
    dispatch_group_enter(group);
    dispatch_async(queue, ^{
        [self getAdvertList:^{
            dispatch_group_leave(group);
        }];
    });
    
    dispatch_group_wait(group, 2.0);
    
    dispatch_group_notify(group, queue, ^{
        NSLog(@"group里面全部执行完毕了");
    });
    
    NSLog(@"group_notify外面的");
}

- (void)getHotCultureList:(void(^)())finish{
    dispatch_queue_t newQueue = dispatch_queue_create("com.instashop.log.new", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(newQueue, ^{
        [NSThread sleepForTimeInterval:3];
        finish();
    });

}

-(void)getAdvertList:(void(^)())finish{
    //网络请求..成功后调用一下finish,失败也调用finish
    dispatch_queue_t queue = dispatch_queue_create("com.instashop.log", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        [NSThread sleepForTimeInterval:5];
        finish();
    });
}



@end
