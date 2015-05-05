//
//  SlidingViewController.m
//  
//
//  Created by freedom on 15/5/4.
//  Copyright (c) 2015年 freedom_luo. All rights reserved.
//

#import "SlidingViewController.h"

static const CGFloat SEGMENTED_VIEW_HEIGHT = 40.0;//顶部滚动视图高度
static const CGFloat SEGMENTED_VIEW_Y=64.0;//顶部滚动视图Y位置
static const CGFloat SELECTOR_Y_BUFFER = 104.0;//顶部滚动视图中选中标识Y位置
static const CGFloat SELECTOR_HEIGHT = 1.0; //顶部滚动视图中选中标识高度

@interface SlidingViewController ()

@property (nonatomic) UIScrollView *pageScrollView;
@property (nonatomic) NSInteger currentPageIndex;//当前选中栏目索引
@property (nonatomic, strong) UIScrollView *segmentedView;//顶部滚动视图
@property (nonatomic, strong) UIView *selectionBar;//顶部滚动视图选中标识
@property (nonatomic, strong) NSMutableArray *viewControllerArray;//显示的视图集合
@property (nonatomic, strong) UIPageViewController *pageController;
@property (nonatomic, strong) NSMutableArray *segmentedTitleArray;//顶部滚动视图中栏目名称集合
@property (nonatomic, assign) BOOL alreadyLayout;//是否布局

@end

@implementation SlidingViewController

- (instancetype)initWithViewControllers:(NSArray *)viewControllers
{
    if (self = [super init])
    {
        self.currentPageIndex = 0;
        _segmentedTitleArray = [NSMutableArray array];
        _viewControllerArray = [NSMutableArray arrayWithArray:viewControllers];
        _pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    }
    
    return self;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if(_alreadyLayout == NO) {
        [self setupPageViewController];
        [self setupSegmentButtons];
        
        _alreadyLayout = YES;
    }
}

/**
 *  初始化滚动视图中栏目
 */
-(void)setupSegmentButtons
{
    self.automaticallyAdjustsScrollViewInsets = NO;
    _segmentedView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, SEGMENTED_VIEW_Y, ScreenWidth, SEGMENTED_VIEW_HEIGHT)];
    _segmentedView.backgroundColor = [UIColor whiteColor];
    _segmentedView.bounces = YES;
    _segmentedView.showsHorizontalScrollIndicator=NO;
    _segmentedView.pagingEnabled = YES;
    [self.view addSubview:_segmentedView];
    
    //获取顶部滚动视图标题
    [_viewControllerArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [_segmentedTitleArray addObject:((UIViewController *)obj).title];
    }];
    
    //添加顶部滚动视图
    CGFloat previousButtonX=10.0;//上一个新闻类型的X坐标
    for (int i = 0; i<_viewControllerArray.count; i++)
    {
        UIButton *button = [[UIButton alloc] init];
        button.backgroundColor = [UIColor clearColor];
        button.tag = i+1;
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [button setTitle:[_segmentedTitleArray objectAtIndex:i] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(tapSegmentButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [_segmentedView addSubview:button];
        
        //自动调整新闻类型宽度
        NSDictionary *attributes = @{NSFontAttributeName:button.titleLabel.font};
        CGSize fontSize=[button.titleLabel.text boundingRectWithSize:CGSizeMake(ScreenWidth,SEGMENTED_VIEW_HEIGHT) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil].size;
        button.frame=CGRectMake(previousButtonX, 0, fontSize.width, SEGMENTED_VIEW_HEIGHT);
        previousButtonX+=fontSize.width+20;
    }
    
    //动态计算顶部滚动视图的内容宽度
    CGRect headScrollViewRect=CGRectZero;
    for (UIView *subview in _segmentedView.subviews) {
        headScrollViewRect=CGRectUnion(headScrollViewRect, subview.frame);
    }
    _segmentedView.contentSize=CGSizeMake(headScrollViewRect.size.width+10, 0);
    
    [self setupSelector];
}

/**
 *  初始化第一个为默认选中
 */
-(void)setupSelector
{
    UIButton *button=(UIButton *)[_segmentedView viewWithTag:1];//获取第一个栏目
    _selectionBar = [[UIView alloc]initWithFrame:CGRectMake(button.frame.origin.x, SELECTOR_Y_BUFFER,button.frame.size.width, SELECTOR_HEIGHT)];
    _selectionBar.backgroundColor = [UIColor redColor];
    [self.view addSubview:_selectionBar];
}

/**
 *  初始化pageview
 */
-(void)setupPageViewController
{
    _pageController.delegate = self;
    _pageController.dataSource = self;
    [_pageController setViewControllers:@[[_viewControllerArray objectAtIndex:0]] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    
    CGRect frame = self.view.bounds;
    frame.size.height -= (SEGMENTED_VIEW_HEIGHT + SEGMENTED_VIEW_Y);
    frame.origin.y = SEGMENTED_VIEW_Y + SEGMENTED_VIEW_HEIGHT;
    _pageController.view.frame = frame;
    [_pageController willMoveToParentViewController:self];
    [self addChildViewController:_pageController];
    [self.view addSubview:_pageController.view];
    [_pageController didMoveToParentViewController:self];
    
    [self syncScrollView];
}

/**
 *  初始化scrollview
 */
-(void)syncScrollView
{
    for (UIView* view in _pageController.view.subviews)
    {
        if([view isKindOfClass:[UIScrollView class]])
        {
            self.pageScrollView = (UIScrollView *)view;
            self.pageScrollView.delegate = self;
        }
    }
}

/**
 *  滚动视图中栏目的点击动作
 *
 *  @param button
 */
-(void)tapSegmentButtonAction:(UIButton *)button
{
    NSInteger tempIndex = self.currentPageIndex;
    __weak typeof(self) weakSelf = self;
    if (button.tag-1 > tempIndex) {
        for (int i = (int)tempIndex+1; i<=button.tag-1; i++) {
            [_pageController setViewControllers:@[[_viewControllerArray objectAtIndex:i]] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:^(BOOL complete){
                if (complete) {
                    [weakSelf updateCurrentPageIndex:i];
                }
            }];
        }
    }
    else if (button.tag-1 < tempIndex) {
        for (int i = (int)tempIndex-1; i >= button.tag-1; i--) {
            [_pageController setViewControllers:@[[_viewControllerArray objectAtIndex:i]] direction:UIPageViewControllerNavigationDirectionReverse animated:YES completion:^(BOOL complete){
                if (complete) {
                    [weakSelf updateCurrentPageIndex:i];
                }
            }];
        }
    }
}

/**
 *  更新当前选中索引
 *
 *  @param newIndex 当前选中索引
 */
-(void)updateCurrentPageIndex:(int)newIndex
{
    self.currentPageIndex = newIndex;
}

#pragma scrollview委托
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [UIView animateWithDuration:0.25 animations:^{
        UIButton *button=(UIButton *)[_segmentedView viewWithTag:_currentPageIndex+1];//获取选中栏目
        NSInteger offset=(button.frame.origin.x+button.frame.size.width)-ScreenWidth;//选中栏目和屏幕的偏移量
        if (offset>0) {//选中栏目超出屏幕
            [_segmentedView setContentOffset:CGPointMake(offset+10, 0) animated:YES];
            
            _selectionBar.frame=CGRectMake(button.frame.origin.x-offset-10, SELECTOR_Y_BUFFER, button.frame.size.width, SELECTOR_HEIGHT);
        }
        else{//选中栏目未超出屏幕
            [_segmentedView setContentOffset:CGPointMake(0, 0) animated:YES];
            
            _selectionBar.frame=CGRectMake(button.frame.origin.x, SELECTOR_Y_BUFFER, button.frame.size.width, SELECTOR_HEIGHT);
        }
    }];
}

#pragma pageview委托
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSInteger index = [self indexOfController:viewController];
    
    if ((index == NSNotFound) || (index == 0)) {
        return nil;
    }
    
    index--;
    return [_viewControllerArray objectAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSInteger index = [self indexOfController:viewController];
    
    if (index == NSNotFound) {
        return nil;
    }
    index++;
    
    if (index == [_viewControllerArray count]) {
        return nil;
    }
    return [_viewControllerArray objectAtIndex:index];
}

-(void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (completed) {
        self.currentPageIndex = [self indexOfController:[pageViewController.viewControllers lastObject]];
    }
}

-(NSInteger)indexOfController:(UIViewController *)viewController
{
    for (int i = 0; i<[_viewControllerArray count]; i++) {
        if (viewController == [_viewControllerArray objectAtIndex:i])
        {
            return i;
        }
    }
    return NSNotFound;
}


@end
