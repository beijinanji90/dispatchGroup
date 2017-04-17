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

/*
 * 1、这个可以模拟多个异步任务，然后每个任务之间还需要按照顺序的执行
 * 2、通过NSOperation来控制A、B、C的执行顺序
 * 3、通过信号量来控制器某一个任务的异步执行的时候，什么时候这个任务执行完毕
 */
- (void)useNSOpeationAndSemaphoreSignal
{
    NSBlockOperation *blockOperation1 = [NSBlockOperation blockOperationWithBlock:^{
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"%@",@"operation1");
            dispatch_semaphore_signal(semaphore);
        });
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }];
    
    NSBlockOperation *blockOperation2 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"%@",@"operation2");
    }];
    
    NSBlockOperation *blockOperation3 = [NSBlockOperation blockOperationWithBlock:^{
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"%@",@"operation3");
            dispatch_semaphore_signal(semaphore);
        });
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }];
    
    NSBlockOperation *blockOperation4 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"%@",@"operation4");
    }];
    [blockOperation2 addDependency:blockOperation1];
    [blockOperation3 addDependency:blockOperation2];
    [blockOperation4 addDependency:blockOperation3];
    
    NSOperationQueue *quere = [NSOperationQueue new];
    [quere addOperation:blockOperation1];
    [quere addOperation:blockOperation2];
    [quere addOperation:blockOperation3];
    [quere addOperation:blockOperation4];
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
