//
//  ALFPSStatus.h
//  ALFPSStatusDemo
//
//  Created by arien on 16/7/20.
//  Copyright © 2016年 ArienLau. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ALFPSStatus : NSObject

+ (ALFPSStatus *)shareInstance;
- (void)start;
- (void)end;

@end
