# JCRefresh
An easy Refresh for iOS.

![image](https://github.com/JCleqiang/JCRefresh/blob/master/snap.gif)


- 用法
```
#import "UIScrollView+Refresh.h"

// 添加刷新控件
self.tableView.jc_refreshHeader = [JCRefresh refresh];
    
// 添加刷新事件监听
[self.tableView.jc_refreshHeader addTarget:self action:@selector(loadData) forControlEvents:UIControlEventValueChanged];

// 结束刷新
[self.tableView.jc_refreshHeader endRefresh];
```
