//
//  UIScrollView+Refresh.m
//  KLRefresh-Demo
//
//  Created by admin on 16/11/10.
//  Copyright © 2016年 静持大师. All rights reserved.
//

#import "UIScrollView+Refresh.h" 
#import <objc/runtime.h>

@implementation UIScrollView (Refresh)

#pragma mark - header
static const char JCRefreshHeaderKey = '\0';


- (void)setJc_refreshHeader:(JCRefresh *)jc_refreshHeader {
    if (jc_refreshHeader != self.jc_refreshHeader) {
        // 删除旧的，添加新的
        [self.jc_refreshHeader removeFromSuperview];
        [self insertSubview:jc_refreshHeader atIndex:0];
        
        [self layoutSubviews];
        
        // 存储新的
        [self willChangeValueForKey:@"jc_refreshHeader"]; // KVO
        objc_setAssociatedObject(self, &JCRefreshHeaderKey, jc_refreshHeader, OBJC_ASSOCIATION_ASSIGN);
        [self didChangeValueForKey:@"jc_refreshHeader"]; // KVO
    }
}

- (JCRefresh *)jc_refreshHeader {
    return objc_getAssociatedObject(self, &JCRefreshHeaderKey);
}


@end
