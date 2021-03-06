//
//  JCRefresh.h
//  JCRefresh-Demo
//
//  Created by admin on 16/11/10.
//  Copyright © 2016年 静持大师. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, JCRefreshState) {
    JCRefreshNormalState, // 未刷新
    JCRefreshPullingState, // 即将刷新
    JCRefreshIngState, // 刷新中
};

@interface JCRefresh : UIControl

+ (instancetype)refresh;

/**
 开始刷新
 */
- (void)beginRefreshing;

/**
 结束刷新
 */
- (void)endRefresh;


@end
