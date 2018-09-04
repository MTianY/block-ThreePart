//
//  main.m
//  block-test1
//
//  Created by 马天野 on 2018/9/5.
//  Copyright © 2018年 Maty. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^test1Block)(void);

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        __block int age = 10;
        
        test1Block block = ^{
            
            age = 20;
            
            NSLog(@"age = %d",age);
        };
        block();
        
    }
    return 0;
}
