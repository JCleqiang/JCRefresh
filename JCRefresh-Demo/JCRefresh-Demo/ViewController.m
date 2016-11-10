//
//  ViewController.m
//  JCRefresh-Demo
//
//  Created by admin on 16/11/10.
//  Copyright © 2016年 静持大师. All rights reserved.
//

#import "ViewController.h" 
#import "UIScrollView+Refresh.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>
/** 数据源 */
@property (nonatomic, strong) NSMutableArray *listArrayM;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"JCRefresh";
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.listArrayM = [NSMutableArray arrayWithObjects:[NSNull new], [NSNull new],nil];
    
    // 添加刷新控件
    self.tableView.jc_refreshHeader = [JCRefresh refresh];
    [self.tableView.jc_refreshHeader addTarget:self action:@selector(loadData) forControlEvents:UIControlEventValueChanged];
}

- (void)loadData {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.listArrayM addObjectsFromArray:@[[NSNull new], [NSNull new]]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView.jc_refreshHeader endRefresh];
            
            [self.tableView reloadData];
        });
    });
}


#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.listArrayM.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString * const kCellID = @"__cellId__";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellID];
        cell.backgroundColor = [UIColor lightGrayColor];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"第 %ld 行", indexPath.row];
    
    return cell;
}
@end
