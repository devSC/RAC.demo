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
@property (strong, nonatomic) RACCommand *commond;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
//    [self testCommonMethod];
//    [self testCommond];
//    [self testCommondConcurentExcution];
//    [self testReplay];
//    [self testConcat];
//    [self testFlatter];
//    [self testFlattermap];
//    [self testThen];
    
    [self testSwitching];
    
}

- (void)testSwitching {
    //Switching
    //-switchToLatest方法用于含有多个信号的信号(signal-of-signals)，它总是输出(forwards)最新的信号的值。
    
    RACSubject *letters = [RACSubject subject];
    RACSubject *numbers = [RACSubject subject];
    RACSubject *signalOfSignals = [RACSubject subject];
    
    RACSignal *switched = [signalOfSignals switchToLatest];
    
    // Outputs: A B 1 D
    [switched subscribeNext:^(NSString *x) {
        NSLog(@"%@", x);
    }];
    
    [signalOfSignals sendNext:letters]; //swith to letter
    [letters sendNext:@"A"];
    [letters sendNext:@"B"];
    
    [signalOfSignals sendNext:numbers]; //swith to number
    [letters sendNext:@"C"];
    [numbers sendNext:@"1"];
    
    [signalOfSignals sendNext:letters]; //swith to letter
    [numbers sendNext:@"2"];
    [letters sendNext:@"D"];
}

- (void)testFlatter {
    //Flattening--压缩
    //-flatten方法用来将包含多个流的流(stream-of-streams)合并成一个流：
    
    RACSequence *letters = [@"A B C D E F G H I" componentsSeparatedByString:@" "].rac_sequence;
    RACSequence *numbers = [@"1 2 3 4 5 6 7 8 9" componentsSeparatedByString:@" "].rac_sequence;
    RACSequence *sequenceOfSequences = @[ letters, numbers ].rac_sequence;
    
    // Contains: A B C D E F G H I 1 2 3 4 5 6 7 8 9
    RACSequence *flattened = [sequenceOfSequences flatten];
    NSLog(@"flattened: %@", flattened.array);
    
}

- (void)testFlatterSignal {
    //信号也能被合并：
    
    RACSubject *letters = [RACSubject subject];
    RACSubject *numbers = [RACSubject subject];
    RACSignal *signalOfSignals = [RACSignal createSignal:^ RACDisposable * (id<RACSubscriber> subscriber) {
        [subscriber sendNext:letters];
        [subscriber sendNext:numbers];
        [subscriber sendCompleted];
        return nil;
    }];
    
    RACSignal *flattened = [signalOfSignals flatten];
    
    // Outputs: A 1 B C 2
    [flattened subscribeNext:^(NSString *x) {
        NSLog(@"%@", x);
    }];
    
    [letters sendNext:@"A"];
    [numbers sendNext:@"1"];
    [letters sendNext:@"B"];
    [letters sendNext:@"C"];
    [numbers sendNext:@"2"];
}

- (void)testConcat {
    RACSequence *letters = [@"A B C D E F G H I" componentsSeparatedByString:@" "].rac_sequence;
    RACSequence *numbers = [@"1 2 3 4 5 6 7 8 9" componentsSeparatedByString:@" "].rac_sequence;
    
    // Contains: A B C D E F G H I 1 2 3 4 5 6 7 8 9
    RACSequence *concatenated = [letters concat:numbers];
    NSLog(@"%@", concatenated.array);

}

- (void)testFlattermap {
    /*
    Mapping and flattening
    -flattenMap:方法被用来将流中的每个值加入到一个新的流中。然后所有返回的流将被压缩成一个流。相当于在-map:之后进行-flatten:。
    
    这可以用来修改或者扩展序列:
     */
    
    RACSequence *numbers = [@"1 2 3 4 5 6 7 8 9" componentsSeparatedByString:@" "].rac_sequence;
    
    NSLog(@"numbers: %@", numbers.array);
    
    // Contains: 1 1 2 2 3 3 4 4 5 5 6 6 7 7 8 8 9 9
    RACSequence *extended = [numbers flattenMap:^(NSString *num) {
        return @[ num, num ].rac_sequence;
    }];
    
    NSLog(@"extended: %@", extended.array);
    
    // Contains: 1_ 3_ 5_ 7_ 9_
    RACSequence *edited = [numbers flattenMap:^(NSString *num) {
        if (num.intValue % 2 == 0) {
            return [RACSequence empty];
        } else {
            NSString *newNum = [num stringByAppendingString:@"_"];
            return [RACSequence return:newNum]; 
        }
    }];
    
    NSLog(@"edited: %@", edited.array);
}

- (void)testThen {
    //-then:启动原始的信号，等待它完成，之后只传递值到一个新的信号：
    
    RACSignal *letters = [@"A B C D E F G H I" componentsSeparatedByString:@" "].rac_sequence.signal;
    
    // The new signal only contains: 1 2 3 4 5 6 7 8 9
    //
    // But when subscribed to, it also outputs: A B C D E F G H I
    RACSignal *sequenced = [[letters doNext:^(NSString *letter) {
        NSLog(@"doNext: %@", letter);
    }] then:^RACSignal *{
        return [@"1 2 3 4 5 6 7 8 9" componentsSeparatedByString:@" "].rac_sequence.signal;
    }];
    
    [sequenced subscribeNext:^(id x) {
        NSLog(@"subscribe: %@", x);;
    }];
}

- (void)testReplay {
    RACMulticastConnection *stringSignal = [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:[NSDate date]];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"Send again");
            [subscriber sendNext:[NSDate date]];
            [subscriber sendCompleted];
        });
        return nil;
    }] replay] publish] ;
    
    [stringSignal.signal subscribeNext:^(id x) {
        NSLog(@"subscribe1 : %@", x);
    }];
    
    [[stringSignal.signal delay:2] subscribeNext:^(id x) {
        NSLog(@"subscribe2 : %@", x);
    }];
    
    [stringSignal connect];
}

- (void)testCommond {
    _commond = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        NSLog(@"excute input: %@", input);
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [subscriber sendNext:input];
            [subscriber sendCompleted];
            //            dispatch_safe_after(1, ^{
            //            });
            return nil;
        }];
    }];
    
    
    [_commond.executing subscribeNext:^(id x) {
        NSLog(@"executing: %@", x);
    }];
    
//    ///1. 可以拿到最新的执行信号
//    [_commond.executionSignals subscribeNext:^(RACSignal *x) {
//        NSLog(@"excution: %@", x); //信号
//        
//        //打印出信号中的值
//        [x subscribeNext:^(id x) {
//            
//        }];
//    }];
//    
//    //1.1或者:直接使用 switchToLastest 来获取最新的信号
//    [_commond.executionSignals.switchToLatest subscribeNext:^(RACSignal *x) {
//        NSLog(@"excution: %@", x); //值
//    }];
    
    ///
    [_commond execute:@(1)];
    [_commond execute:@(2)];
    [_commond execute:@(3)];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [_commond execute:@"end"];
    });
    
    //Commond一旦在执行中, 会始终等之前执行的信号返回complete, 并且忽视在执行过程中的调用.
    /* log
    2017-04-10 12:31:25.269 TestRAC[11455:656525] executing: 0
    2017-04-10 12:31:25.270 TestRAC[11455:656525] excute input: 1
    2017-04-10 12:31:25.304 TestRAC[11455:656525]  INFO: Reveal Server started (Protocol Version 25).
    2017-04-10 12:31:25.320 TestRAC[11455:656525] executing: 1
    2017-04-10 12:31:25.321 TestRAC[11455:656525] executing: 0
    2017-04-10 12:31:26.475 TestRAC[11455:656525] excute input: end
    2017-04-10 12:31:26.476 TestRAC[11455:656525] executing: 1
    2017-04-10 12:31:26.476 TestRAC[11455:656525] executing: 0
    */
}

- (void)testCommondConcurentExcution {
    _commond = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        NSLog(@"excute input: %@", input);
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [subscriber sendNext:input];
            [subscriber sendCompleted];
            //            dispatch_safe_after(1, ^{
            //            });
            return nil;
        }];
    }];
    _commond.allowsConcurrentExecution = YES;
    
    [_commond.executing subscribeNext:^(id x) {
        NSLog(@"executing: %@", x);
    }];
    
    ///
    [_commond execute:@(1)];
    [_commond execute:@(2)];
    [_commond execute:@(3)];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [_commond execute:@"end"];
    });
    
    
    //Commond一旦在执行中, 会始终等之前执行的信号返回complete, 并且忽视在执行过程中的调用.
    /* log
     2017-04-10 12:31:25.269 TestRAC[11455:656525] executing: 0
     2017-04-10 12:31:25.270 TestRAC[11455:656525] excute input: 1
     2017-04-10 12:31:25.304 TestRAC[11455:656525]  INFO: Reveal Server started (Protocol Version 25).
     2017-04-10 12:31:25.320 TestRAC[11455:656525] executing: 1
     2017-04-10 12:31:25.321 TestRAC[11455:656525] executing: 0
     2017-04-10 12:31:26.475 TestRAC[11455:656525] excute input: end
     2017-04-10 12:31:26.476 TestRAC[11455:656525] executing: 1
     2017-04-10 12:31:26.476 TestRAC[11455:656525] executing: 0
     */
}

- (void)testCommonMethod {
    
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
    //RACScheduler 相当于NSTimer,但有很多可以玩耍的东东
    RACScheduler *scheduler = [RACScheduler scheduler];
    [scheduler afterDelay:2 schedule:^{
        NSLog(@"after delay 2 second be invoked");
    }];
#endif
    
#if 0
    RACSignal *stringSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:[NSDate date]];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"Send again");
            [subscriber sendNext:[NSDate date]];
            [subscriber sendCompleted];
        });
        return nil;
    }];
    
    
    [stringSignal subscribeNext:^(id x) {
        NSLog(@"subscribe1 : %@", x);
    }];
    
    [[stringSignal delay:2] subscribeNext:^(id x) {
        NSLog(@"subscribe2 : %@", x);
    }];
    
    /* ---log---
     2016-12-13 16:48:21.496 TestRAC[21119:1579595] subscribe1 : 2016-12-13 08:47:03 +0000
     2016-12-13 16:48:29.005 TestRAC[21119:1579595]  INFO: Reveal Server started (Protocol Version 25).
     2016-12-13 16:48:29.022 TestRAC[21119:1579595] Send again
     2016-12-13 16:48:29.022 TestRAC[21119:1579595] subscribe1 : 2016-12-13 08:48:29 +0000
     2016-12-13 16:48:38.973 TestRAC[21119:1579595] subscribe2 : 2016-12-13 08:48:24 +0000
     2016-12-13 16:48:38.973 TestRAC[21119:1579595] Send again
     2016-12-13 16:49:00.873 TestRAC[21119:1579595] subscribe2 : 2016-12-13 08:48:38 +0000
     */
#endif
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
