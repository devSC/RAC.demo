//
//  ViewController.m
//  TestRAC
//
//  Created by Wilson Yuan on 16/5/25.
//  Copyright © 2016年 Wilson-Yuan. All rights reserved.
//

#import "ViewController.h"
#import <ReactiveCocoa.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *throttleButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    @weakify(self);
    RACSignal *errorSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        return nil;
    }];
    //
    RACSignal *signal = [self rac_signalForSelector:@selector(viewDidAppear:)];
    /*
    [signal.deliverOnMainThread subscribeNext:^(id x) {
        NSLog(@"view did appear signal%@", x);
    }];
     */
    
    RACSignal *buttonSignal = [self.throttleButton rac_signalForControlEvents:UIControlEventTouchUpInside];
    //throttle:节流, 收到next信号后,将会等待1秒,如果在这期间还收到了信号,则保存最新的信号,并重新开始即时, 类似于coco中的performSelete...delay:
    /*
    [[buttonSignal throttle:1].deliverOnMainThread subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
     */
    
    //当2个信号都send next后, 才会向下传递 这里没有先后发送next的顺序
    /*
    [[signal combineLatestWith:buttonSignal].deliverOnMainThread subscribeNext:^(id x) {
        NSLog(@"combineLatestWith: %@", x);
    }];
     */
    
    //两个结合的signal,如果有一方优先发出错误,则,此信号将会优先完成
    /*
    [[buttonSignal combineLatestWith:[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendError:@"Error message"];
        return nil;
    }] delay:10]] subscribeNext:^(id x) {
        NSLog(@"combineLatestWith error: success: %@", x);
    } error:^(NSError *error) {
        NSLog(@"combineLatestWith error: %@", error);
    }];
     */
    
    //delay: 信号正常发送后,如果需要将等待后面信号完成后将会收到next信号
    /*
    [[buttonSignal combineLatestWith:[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        //        @strongify(self);
        [subscriber sendNext:@"Success"];
        [subscriber sendCompleted];
        return nil;
    }] delay:10]] subscribeNext:^(RACTuple *x) {
        NSLog(@"combineLatestWith error: success: %@", x);
    } error:^(NSError *error) {
        NSLog(@"combineLatestWith error: %@", error);
    }];
     */
    
    //信号的初始化, 完成等
    /*
    [[[[[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        //success
        BOOL testSuccess = 0;
        if (testSuccess) {
            [subscriber sendNext:@"Success"];
            [subscriber sendCompleted];
        }
        else {
            [subscriber sendError:@"Error"]; //will ignore delay timeinterver.
        }
        return nil;
    }] delay:2] initially:^{
        NSLog(@"signal initially");
    }] finally:^{
        NSLog(@"signal completed");
    }] deliverOnMainThread] subscribeNext:^(id x) {
        NSLog(@"signal send next: %@", x);
    } error:^(NSError *error) {
        NSLog(@"signal send error");
    }];
    */
    
    //combine..reduce, 收到信号后,可以做进一步处理,将处理后的新信号,返回
    /*
    RACSignal *stringSignal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"This is a string signal"];
        [subscriber sendCompleted];
        return nil;
    }] delay:2];
    
    RACSignal *intSignal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@(99019200)];
        [subscriber sendCompleted];
        return nil;
    }] delay:3];
    
    [[RACSignal combineLatest:@[stringSignal, intSignal] reduce:^id(NSString *string, NSNumber *number){
        return [NSString stringWithFormat:@"%@----%@", string, number];
    }] subscribeNext:^(id x) {
        NSLog(@"%@", x);
    }];
    */
    
    //then, 当string signal completed后,执行int signal, 同样,如果有错误,则立即发出, 并且不用执行int signal
    /*
     RACSignal *stringSignal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
     [subscriber sendNext:@"This is a string signal"];
     [subscriber sendNext:@"This is a string signal-1"];
     [subscriber sendNext:@"This is a string signal-2"];
     [subscriber sendCompleted];
     //        [subscriber sendError:@"error"];
     return [RACDisposable disposableWithBlock:^{
     
     }];
     }] delay:2];
     
     RACSignal *intSignal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
     [subscriber sendNext:@(99019200)];
     [subscriber sendCompleted];
     return [RACDisposable disposableWithBlock:^{
     
     }];
     }] delay:3];
     
    [[stringSignal then:^RACSignal *{
        return intSignal;
    }] subscribeNext:^(id x) {
        NSLog(@"then next: %@", x);
    } error:^(NSError *error) {
        NSLog(@"then error: %@", error);
    }];
     */
    //
    
#if 0
    RACSignal *stringSignal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"This is a string signal"];
        [subscriber sendNext:@"This is a string signal-1"];
        [subscriber sendNext:@"This is a string signal-2"];
        [subscriber sendCompleted];
        //        [subscriber sendError:@"error"];
        return [RACDisposable disposableWithBlock:^{
            
        }];
    }] delay:2];
    
    RACSignal *intSignal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@(99019200)];
        [subscriber sendCompleted];
        return [RACDisposable disposableWithBlock:^{
            
        }];
    }] delay:3];
    //concat 将信号有顺序的组织起来返回, 并且是等前一个信号completed后,再进行下面的任务
    [[stringSignal concat:intSignal] subscribeNext:^(id x) {
        NSLog(@"concat success: %@", x);
    } error:^(NSError *error) {
        NSLog(@"concat error: %@", error);
    }];
#endif
    
#if 0
    //定时器
    [[RACSignal interval:1 onScheduler:[RACScheduler mainThreadScheduler]] subscribeNext:^(id x) {
        NSLog(@"RACScheduler: %@", x);
    } error:^(NSError *error) {
        NSLog(@"RACScheduler: error: %@", error);
    }];
#endif
    
#if 0
    //takeUntil:  直到cancelSignal send next or complete or error, 信号都有效
    RACSignal *timerSignal = [RACSignal interval:1 onScheduler:[RACScheduler mainThreadScheduler]];
    
    RACSignal *cancelSignal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:nil];
        [subscriber sendCompleted];
        return [RACDisposable disposableWithBlock:^{
            
        }];
    }] delay:4];
    
    [[timerSignal takeUntil:cancelSignal] subscribeNext:^(id x) {
        NSLog(@"RACScheduler: %@", x);
    } error:^(NSError *error) {
        NSLog(@"RACScheduler: error: %@", error);
    }];
    
#endif
    
#if 0
    //takeUntilReplacement:  直到cancelSignal send next or complete or error, 之前信号作废, 换做新的信号
    RACSignal *timerSignal = [RACSignal interval:1 onScheduler:[RACScheduler mainThreadScheduler]];
    
    RACSignal *cancelSignal = [RACSignal interval:2 onScheduler:[RACScheduler mainThreadScheduler]];
    
    [[timerSignal takeUntilReplacement:cancelSignal] subscribeNext:^(id x) {
        NSLog(@"RACScheduler: %@", x);
    } error:^(NSError *error) {
        NSLog(@"RACScheduler: error: %@", error);
    }];
    
#endif


#if 0
    //catch: 如果信号send error, 则返回新的信号. 否则,继续执行
    RACSignal *stringSignal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
//        [subscriber sendNext:@"This is a string signal"];
//        [subscriber sendNext:@"This is a string signal-1"];
//        [subscriber sendNext:@"This is a string signal-2"];
//        [subscriber sendCompleted];
            [subscriber sendError:@"error"];
        return [RACDisposable disposableWithBlock:^{
            
        }];
    }] delay:2];
    
    RACSignal *intSignal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@(99019200)];
        [subscriber sendCompleted];
        return [RACDisposable disposableWithBlock:^{
            
        }];
    }] delay:3];
    
    [[stringSignal catch:^RACSignal *(NSError *error) {
        NSLog(@"catch error: %@", error);
        return intSignal;
    }] subscribeNext:^(id x) {
        NSLog(@"catch success: %@", x);
    } error:^(NSError *error) {
        NSLog(@"int signal error: %@", error);
    }];
    
#endif
    
    
#if 0
    //try: 将signal sendNext中的值,进行其他处理, 如: 写入文件等, 如果想入成功,则可以返回yes,
    RACSignal *stringSignal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                [subscriber sendNext:@"This is a string signal"];
                [subscriber sendNext:@"This is a string signal-1"];
                [subscriber sendNext:@"This is a string signal-2"];
                [subscriber sendCompleted];
//        [subscriber sendError:@"error"];
        return [RACDisposable disposableWithBlock:^{
            
        }];
    }] delay:2];
    
    [[stringSignal try:^BOOL(NSString *value, NSError *__autoreleasing *errorPtr) {
        NSLog(@"%@, %p", value, &errorPtr);
        if ([value isEqualToString:@"This is a string signal-2"]) {
            *errorPtr = [NSError errorWithDomain:@"sdfsdfs" code:1002 userInfo:nil];
            return NO;
        }
        else {
            return YES;
        }
    }] subscribeNext:^(id x) {
        NSLog(@"try success: %@", x);
    } error:^(NSError *error) {
        NSLog(@"try failed: %@", error);
    }];

#endif
    
    
#if 0
    //tryMap: 同try, 这里可以处理数组
    RACSignal *stringSignal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"This is a string signal"];
        [subscriber sendNext:@"This is a string signal-1"];
        [subscriber sendNext:@"This is a string signal-2"];
        [subscriber sendCompleted];
        //        [subscriber sendError:@"error"];
        return [RACDisposable disposableWithBlock:^{
            
        }];
    }] delay:2];
    
    [[stringSignal tryMap:^id(id value, NSError *__autoreleasing *errorPtr) {
        NSLog(@"%@, %p", value, &errorPtr);
        if ([value isEqualToString:@"This is a string signal-2"]) {
            *errorPtr = [NSError errorWithDomain:@"sdfsdfs" code:1002 userInfo:nil];
            return nil;
        }
        else {
            return @"=======";
        }
    }] subscribeNext:^(id x) {
        NSLog(@"try success: %@", x);
    } error:^(NSError *error) {
        NSLog(@"try failed: %@", error);
    }];
    
#endif
    
    
#if 0
    //defer: 延迟调用, 当defer signal 被subscribe时, 才会返回真正的信号
    RACSignal *deferSignal = [RACSignal defer:^RACSignal *{
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [subscriber sendNext:@"this is a defer signal"];
            [subscriber sendCompleted];
            
            return nil;
        }];
    }] ;
    
    [deferSignal subscribeNext:^(id x) {
        NSLog(@"defer: %@", x);
    } error:^(NSError *error) {
        NSLog(@"defer error: %@", error);
    }];
    
#endif
    
#if 0
    //将会交换信号根据case中的配置.
//    [RACSignal switch:<#(RACSignal *)#> cases:<#(NSDictionary *)#> default:<#(RACSignal *)#>]
    
#endif
    
#if 0
    //+ (RACSignal *)if:(RACSignal *)boolSignal then:(RACSignal *)trueSignal else:(RACSignal *)falseSignal;
    //类似于 if ... else ..,
    [[RACSignal if:[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [subscriber sendNext:@(1)];
        [subscriber sendCompleted];
//        [subscriber sendError:@"nil"];
        return nil;
        
    }] delay:2] then:[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"This is true signal"];
        [subscriber sendCompleted];
        return nil;
    }] else:[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"This is false signal"];
        [subscriber sendCompleted];
        return nil;
    }]] subscribeNext:^(id x) {
        NSLog(@"if signal: %@", x);
    } error:^(NSError *error) {
        NSLog(@"if signal error: %@", error);
    }];
    
#endif
    
#if 0 //reduceApply 带验证
    RACSignal *returnSignal = [RACSignal return:^(NSNumber *a, NSNumber *b) {
        return @(a.integerValue + b.integerValue);
    }];
    
    RACSignal *sums = [[RACSignal combineLatest:@[returnSignal, @(2), @(8)]] reduceApply];
    
    [sums subscribeNext:^(id x) {
        NSLog(@"%reduce apply: @", x);
    } error:^(NSError *error) {
        NSLog(@"reduce apply error: %@", error);
    }];
    
#endif
    
#if 1
#endif
    
#if 1
#endif
    //falatten
    ///待验证
//    RACSignal *stringSignal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
//        [subscriber sendNext:@"This is a string signal"];
//        [subscriber sendNext:@"This is a string signal-1"];
//        [subscriber sendNext:@"This is a string signal-2"];
//        [subscriber sendCompleted];
//        //        [subscriber sendError:@"error"];
//        return [RACDisposable disposableWithBlock:^{
//
//        }];
//    }] delay:2];
//
//    RACSignal *intSignal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
//        [subscriber sendNext:@(99019200)];
//        [subscriber sendCompleted];
//        return [RACDisposable disposableWithBlock:^{
//
//        }];
//    }] delay:3];

//    [[[stringSignal flatten:10] deliverOnMainThread] subscribeNext:^(id x) {
//        NSLog(@"%@", x);
//    }];
    
#if 0
    //first .... 待验证
    RACSignal *stringSignal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"This is a string signal"];
        [subscriber sendNext:@"This is a string signal-1"];
        [subscriber sendNext:@"This is a string signal-2"];
        [subscriber sendCompleted];
        //        [subscriber sendError:@"error"];
        return [RACDisposable disposableWithBlock:^{
            
        }];
    }] delay:2];

    [stringSignal.deliverOnMainThread subscribeNext:^(id x) {
        NSLog(@"first: %@", x);
    } error:^(NSError *error) {
        
    } completed:^{
        NSLog(@"first: %@", [stringSignal first]);
    }];
    
#endif

#if 0
    //switchToLatest .... 待验证 将sendnext中的信号
    RACSignal *stringSignal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"This is a string signal"];
        [subscriber sendNext:@"This is a string signal-1"];
        [subscriber sendNext:@"This is a string signal-2"];
        [subscriber sendCompleted];
        //        [subscriber sendError:@"error"];
        return [RACDisposable disposableWithBlock:^{
            
        }];
    }] delay:2];
    
    [[stringSignal switchToLatest].deliverOnMainThread subscribeNext:^(id x) {
        NSLog(@"first: %@", x);
    } error:^(NSError *error) {
        
    }];
    
#endif
    
#if 0
    //RACScheduler 相当于NSTimer,但有很多可以玩耍的东东
    RACScheduler *scheduler = [RACScheduler scheduler];
    [scheduler afterDelay:2 schedule:^{
        NSLog(@"after delay 2 second be invoked");
    }];
#endif
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
