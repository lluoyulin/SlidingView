//
//  SlidingViewController.h
//  
//
//  Created by freedom on 15/5/4.
//  Copyright (c) 2015年 freedom_luo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SlidingViewController : UIViewController<UIPageViewControllerDelegate,UIPageViewControllerDataSource,UIScrollViewDelegate>

- (instancetype)initWithViewControllers:(NSArray *)viewControllers;

@end
