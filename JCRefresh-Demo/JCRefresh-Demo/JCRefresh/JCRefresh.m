//
//  JCRefresh.m
//  JCRefresh-Demo
//
//  Created by admin on 16/11/10.
//  Copyright © 2016年 静持大师. All rights reserved.
//

#import "JCRefresh.h"

#define JC_SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define JCColor(r, g, b)  [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]
#define JC_THEME_COLOE JCColor(59.0, 84.0, 106.0)

static CGFloat const kRefreshWidthAndHeight = 45.f;
static CGFloat const kLineWidth = 5.f; // j上半部分中 竖线的宽度
static CGFloat const kLineHeight = 16.f; // j上半部分中 竖线的高度
static CGFloat const kInnerRadius = 8.f; // j下半部分中 内圆的半径
static CGFloat const kRefreshingStayHeight = 70.f;
static CGFloat const kRefreshControlHideDuration = 0.5; // 控件从刷新状态重置为默认状态的时间

@interface JCRefresh () {
    CGFloat _defaultCenterY; // 刷新控件初始的中点y值
    BOOL _isRefreshingAnim; // 是否正在执行刷新中的动画，防止用户来回拖动 scrollView 造成重复添加动画
    BOOL _isBeginRefreshing; // 是否已经开始执行刷新，防止用户在未刷新完成的情况下重复触发
}
/** JCRefresh的父控件 */
@property (nonatomic, strong) UIScrollView *superView;
/** 背景灰色的layer，显示 `J` */
@property (nonatomic, strong) CAShapeLayer *bgGrayLayer;
/** 顶部layer，显示 `J` 的上半部分 */
@property (nonatomic, strong) CAShapeLayer *topLayer;
/** 底部layer,显示 `J` 的下半部分, 其实就是四分之一圆 */
@property (nonatomic, strong) CAShapeLayer *bottomLayer;
/** <#Description#> */
@property (nonatomic, assign) CGFloat contentOffsetScale;
/** 控件刷新状态 */
@property (nonatomic, assign) JCRefreshState refreshState;
@end

@implementation JCRefresh

#pragma mark - 初始化
+ (instancetype)refresh {
    return [[self alloc] init];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _defaultCenterY = - kRefreshWidthAndHeight * 0.5;
        
        //
        CGRect tempFrame = self.frame;
        tempFrame.size = CGSizeMake(kRefreshWidthAndHeight, kRefreshWidthAndHeight);
        self.frame = tempFrame;
        
        self.backgroundColor = [UIColor clearColor];
        
        // 添加三个layer
        [self.layer addSublayer:self.bgGrayLayer];
        [self.layer addSublayer:self.topLayer];
        [self.layer addSublayer:self.bottomLayer];
        
        //
        [self drawInLayer];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.center = CGPointMake(self.superView.frame.size.width * 0.5, - self.frame.size.height * 0.5);
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    
    if ([newSuperview isKindOfClass:UIScrollView.class]) {
        self.superView = (UIScrollView *)newSuperview;
        
        [newSuperview addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    }
}

#pragma mark - Observer
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentOffset"]) {
        // 处理 contentOffsetY 值改变
        [self contentOffsetYDidChanged];
    }
}

#pragma mark - Setter
- (void)setContentOffsetScale:(CGFloat)contentOffsetScale {
    _contentOffsetScale = (contentOffsetScale >= 1? 1: contentOffsetScale);
}

- (void)setRefreshState:(JCRefreshState)refreshState {
    _refreshState = refreshState;
    
    switch (refreshState) {
        case JCRefreshNormalState: {
            // 移除两个layer的路径
            self.bottomLayer.path = nil;
            self.topLayer.path = nil;
            // 为默认状态时，重置属性
            [self.bottomLayer removeAllAnimations];
            self.topLayer.strokeEnd = 1;
            self.bottomLayer.lineWidth = kLineWidth;
            _isRefreshingAnim = NO;
            // 重置是否开始刷新的状态
            _isBeginRefreshing = NO;
        }
            break;
            
        case JCRefreshPullingState: {
            
        }
            break;
            
        case JCRefreshIngState: {
            // 调整顶部距离
            UIEdgeInsets inset = self.superView.contentInset;
            // 将原有的顶部距离加上刷新控件的高度
            inset.top = inset.top + kRefreshingStayHeight;
            // 调整
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:kRefreshControlHideDuration animations:^{
                    self.superView.contentInset = inset;
                    [self.superView setContentOffset:CGPointMake(0, -inset.top) animated:NO];
                } completion:^(BOOL finished) {
                    // 需要调用外界的刷新方法
                    [self sendActionsForControlEvents:UIControlEventValueChanged];
                }];
            });
        }
            break;
    }
}

#pragma mark - Public
- (void)beginRefreshing {
    if (_isBeginRefreshing) {
        return;
    }
    
    _isBeginRefreshing = YES;
    
    UIEdgeInsets contentInsetY = self.superView.contentInset;
    [UIView animateWithDuration:0.25 animations:^{
        [self.superView setContentOffset:CGPointMake(0, -contentInsetY.top - kRefreshingStayHeight) animated:NO];
    } completion:^(BOOL finished) {
        self.refreshState = JCRefreshIngState;
        [self drawInLayer];
    }];
}

- (void)endRefresh {
    // 执行转圈的layer的线宽的动画
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"lineWidth"];
    animation.toValue = @0;
    animation.duration = 0.5;
    // 设置最终线宽为 0,保证动画执行完毕之后不再显示
    self.bottomLayer.lineWidth = 0;
    [self.bottomLayer addAnimation:animation forKey:nil];
    
    // 重置 contentInset
    UIEdgeInsets inset = self.superView.contentInset;
    inset.top = inset.top - kRefreshingStayHeight;
    
    [UIView animateWithDuration:kRefreshControlHideDuration animations:^{
        self.superView.contentInset = inset;
        [self.superView setContentOffset:CGPointMake(0, -inset.top) animated:NO];
    } completion:^(BOOL finished) {
        self.refreshState = JCRefreshNormalState;
    }];
}

#pragma mark - Private
- (void)contentOffsetYDidChanged {
    CGFloat contentOffsetY = self.superView.contentOffset.y;
    
    // 1. 设置 控件的 y 值
    // 通过偏移量与顶部间距计算数当前控件的中心点
    CGFloat result = (contentOffsetY + self.superView.contentInset.top) * 0.5;
    // 判断计算出来的值是否比默认的Y值还要小，如果小，就设置该 y 值
    if (result < _defaultCenterY) {
        self.center = CGPointMake(self.center.x, result);
    }
    else{
        // 否则继续设置为默认Y值
        self.center = CGPointMake(self.center.x, _defaultCenterY);
    }
    
    // 2. 更改控件的状态
    if (self.superView.isDragging) {
        // 如果空白中心点小于控件的默认中心y值，并且当前状态是默认状态，就进入 `松手就刷新的状态`
        if (result < _defaultCenterY && self.refreshState == JCRefreshNormalState) {
            self.refreshState =  JCRefreshPullingState;
        }
        else if (result >= _defaultCenterY && self.refreshState == JCRefreshPullingState) {
            // 如果空白中心点大于等于控件的默认中心y值，并且当前状态是默认状态，就进入 `默认状态`
            self.refreshState =  JCRefreshNormalState;
        }
    }
    else {
        // 用户已松手，判断当前状态如果是 `pulling` 状态就进行刷新状态
        if (self.refreshState == JCRefreshPullingState) {
            self.refreshState = JCRefreshIngState;
        }
    }
    
    // 3. 计算 scale
    // 通过拖动的距离计算.公式为：比例 = 拖动的距离 / 控件的高度
    CGFloat scale = -(self.superView.contentOffset.y + self.superView.contentInset.top) / kRefreshingStayHeight;
    self.contentOffsetScale = scale;
    
    // 重新绘制内容
    [self drawInLayer];
}

- (void)drawInLayer {
    CGFloat startAngle = M_PI * 0.5;
    CGFloat endAngle = 0;
    
    CGPoint arcCenter = CGPointMake(kRefreshWidthAndHeight * 0.5, kRefreshWidthAndHeight * 0.5);
    
    if (self.refreshState == JCRefreshIngState) { // 正在刷新
        if (_isRefreshingAnim) {
            return;
        }
        
        _isRefreshingAnim = YES; // 调整执行动画属性为true
        self.bgGrayLayer.path = nil; // 清空背景灰色的layer
        
        // 1. 底部半圆到整圆
        UIBezierPath *bottomPath = [UIBezierPath bezierPathWithArcCenter:arcCenter radius:kInnerRadius + kLineWidth * 0.5 startAngle:0 endAngle:M_PI * 2 - 0.1 clockwise:YES];
        self.bottomLayer.path = bottomPath.CGPath;
        
        // 执行动画
        CABasicAnimation *bottomAnim = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        bottomAnim.fromValue = [NSNumber numberWithFloat:0.25];
        bottomAnim.toValue = [NSNumber numberWithFloat:1.0];
        bottomAnim.duration = 0.15;
        [self.bottomLayer addAnimation:bottomAnim forKey:nil];
        
        // 2. 顶部Path, 竖线变短动画
        UIBezierPath *topPath = [UIBezierPath bezierPath];
        topPath.lineCapStyle = kCGLineCapSquare;
        [topPath moveToPoint:CGPointMake(arcCenter.x + kInnerRadius + kLineWidth * 0.5, arcCenter.y)];
        [topPath addLineToPoint:CGPointMake(arcCenter.x + kInnerRadius + kLineWidth * 0.5, arcCenter.y - (_contentOffsetScale - 0.5) * 2 * kLineHeight)];
        self.topLayer.path = topPath.CGPath;
        
        // 竖线变短动画
        CABasicAnimation *topAnim = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        topAnim.fromValue = [NSNumber numberWithFloat:1.0];
        topAnim.toValue = [NSNumber numberWithFloat:0];
        topAnim.duration = 0.15;
        self.topLayer.strokeEnd = 0;
        [self.topLayer addAnimation:topAnim forKey:nil];
        
        // 3. 0.15秒之后 转圈
        dispatch_async(dispatch_get_main_queue(), ^{
            // 执行转圈动画
            UIBezierPath *bottomPath = [UIBezierPath bezierPathWithArcCenter:arcCenter radius:kInnerRadius + kLineWidth * 0.5 startAngle:0 endAngle:M_PI * 2 - 0.1 clockwise:YES];
            self.bottomLayer.path = bottomPath.CGPath;
            
            // 围绕 z 轴转圈
            CABasicAnimation *bottomAnim = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
            bottomAnim.fromValue = [NSNumber numberWithFloat:0];
            bottomAnim.toValue = [NSNumber numberWithFloat:2 * M_PI];
            bottomAnim.duration = 0.5;
            bottomAnim.repeatCount = MAXFLOAT;
            [self.bottomLayer addAnimation:bottomAnim forKey:@"runaroundAnim"];
        });
        
        // 直接返回，不再执行下面的代码
        return;
    }
    
    // 绘制默认状态与松手就刷新状态的代码
    // 绘制灰色J背景 layer 内容
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:arcCenter radius:kInnerRadius startAngle:startAngle endAngle:endAngle clockwise:NO]; // 画 1/4 圆
    [path addLineToPoint:CGPointMake(path.currentPoint.x, arcCenter.y - kLineHeight)]; // 添加左边竖线
    [path addLineToPoint:CGPointMake(path.currentPoint.x + kLineWidth, path.currentPoint.y)]; // 添加顶部横线
    [path addLineToPoint:CGPointMake(path.currentPoint.x, arcCenter.y + kLineHeight)]; // 添加右边竖线
    [path addArcWithCenter:arcCenter radius:kInnerRadius + kLineWidth startAngle:endAngle endAngle:startAngle - 0.05 clockwise:YES]; // 添加外圆
    
    [path closePath];
    
    self.bgGrayLayer.path = path.CGPath;
    
    
    // 通过比例绘制填充 layer
    // 如果小于0.016.在画半圆的时候会反方向画，所以加个判断
    if (self.contentOffsetScale < 0.016) {
        self.bgGrayLayer.path = nil;
        self.bottomLayer.path = nil;
        self.topLayer.path = nil;
        return;
    }
    
    UIBezierPath *(^PathBlock)(CGFloat) = ^(CGFloat contentOffsetScale){
        // 记录传入的比例
        CGFloat scale = self.contentOffsetScale;
        
        // 如果比例大于 0.5，那么设置为 0.5
        scale = (scale > 0.5? 0.5: scale);
        
        // 计算出开始角度与结束角度
        CGFloat targetStartAngle = startAngle;
        CGFloat targetEndAngle = startAngle - startAngle * scale * 2;
        
        // 初始化 path 并返回
        UIBezierPath *drawPath = [UIBezierPath bezierPathWithArcCenter:arcCenter radius:kInnerRadius + kLineWidth * 0.5 startAngle:targetStartAngle endAngle:targetEndAngle clockwise:NO];
        
        return drawPath;
    };
    
    self.bottomLayer.path = PathBlock(_contentOffsetScale).CGPath;
    
    // 判断如果拖动比例小于0.5，只画半圆
    if (_contentOffsetScale <= 0.5) {
        self.topLayer.path = nil;
    }else {
        // 画顶部竖线
        UIBezierPath *topPath = [UIBezierPath bezierPath];
        topPath.lineCapStyle = kCGLineCapSquare;
        [topPath moveToPoint:CGPointMake(arcCenter.x + kInnerRadius + kLineWidth * 0.5, arcCenter.y)];
        [topPath addLineToPoint:CGPointMake(arcCenter.x + kInnerRadius + kLineWidth * 0.5, arcCenter.y - (_contentOffsetScale - 0.5) * 2 * kLineHeight)];
        self.topLayer.path = topPath.CGPath;
    }
}

- (void)dealloc {
    [self.superView removeObserver:self forKeyPath:@"contentOffset"];
}

#pragma mark - Lazy
- (CAShapeLayer *)bgGrayLayer {
    if (!_bgGrayLayer) {
        CAShapeLayer *bgGrayLayer = [[CAShapeLayer alloc] init];
        bgGrayLayer.fillColor = JCColor(222.0, 226.0, 229.0).CGColor;
        _bgGrayLayer = bgGrayLayer;
    }
    return _bgGrayLayer;
}

- (CAShapeLayer *)topLayer {
    if (!_topLayer) {
        CAShapeLayer *topLayer = [[CAShapeLayer alloc] init];
        topLayer.strokeColor = JC_THEME_COLOE.CGColor;
        topLayer.lineWidth = kLineWidth;
        _topLayer = topLayer;
    }
    return _topLayer;
}

- (CAShapeLayer *)bottomLayer {
    if (!_bottomLayer) {
        CAShapeLayer *bottomLayer = [[CAShapeLayer alloc] init];
        bottomLayer.fillColor = [UIColor clearColor].CGColor;
        bottomLayer.strokeColor = JC_THEME_COLOE.CGColor;
        bottomLayer.lineWidth = kLineWidth;
        bottomLayer.frame = self.bounds;
        _bottomLayer = bottomLayer;
    }
    return _bottomLayer;
}


@end
