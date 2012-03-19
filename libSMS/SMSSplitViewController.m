/*
 SMSSplitViewController.m
 
 Copyright (c) 2010, Alex Silverman
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 2. Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 
 3. Neither the name of Alex Silverman nor the
 names of its contributors may be used to endorse or promote products
 derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "SMSSplitViewController.h"


@interface SMSSplitViewController ()

- (void)addViewControllerSubviews;
- (void)layoutSubviewsForOrientation:(BOOL)isPortrait;

@end


@implementation SMSSplitViewController

@synthesize style, viewControllers, dividerView;
@synthesize masterPortraitSize, portraitPadding, masterLandscapeSize, landscapePadding;

- (id)init
{
    return [self initWithStyle:SMSSplitViewStyleLeft];
}

- (id)initWithStyle:(SMSSplitViewStyle)s;
{
	self = [super init];
    if (self) {
        style = s;
        masterPortraitSize = 320.0;
        portraitPadding = 2.0;
        masterLandscapeSize = 320.0;
        landscapePadding = 2.0;
    }
    return self;
}

- (void)loadView
{
	UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
	v.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    v.autoresizesSubviews = NO;
	v.backgroundColor = [UIColor blackColor];
	self.view = v;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
    if (viewControllers)
        [self addViewControllerSubviews];
    if (dividerView)
        [self.view addSubview:dividerView];
}

#pragma mark - Views

- (void)setViewControllers:(NSArray *)vcs
{
	if ([vcs count] != 2) {
		[NSException raise:@"SMSInvalidViewControllers" format:@"Attempted to set %d view controllers to a split view. SMSSplitViewController only accepts 2 view controller.", [vcs count]];
		return;
	}

	for (UIViewController *thisVC in viewControllers) {
        [thisVC willMoveToParentViewController:nil];
        [thisVC.view removeFromSuperview];
        [thisVC removeFromParentViewController];
	}
	
	viewControllers = [vcs copy];
    
    if ([self isViewLoaded]) {
        [self addViewControllerSubviews];
        [self viewDidLayoutSubviews];
    }
}

- (void)addViewControllerSubviews
{
    for (UIViewController *thisVC in viewControllers)
        [self addChildViewController:thisVC];
    
	UIViewController *masterVC = [viewControllers objectAtIndex:0];
    if (dividerView.superview == self.view)
        [self.view insertSubview:masterVC.view belowSubview:dividerView];
    else
        [self.view addSubview:masterVC.view];
	
	UIViewController *detailVC = [viewControllers objectAtIndex:1];
    detailVC.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    if (style == SMSSplitViewStyleLeft || style == SMSSplitViewStyleRight)
        [self.view insertSubview:detailVC.view belowSubview:masterVC.view];
    else
        [self.view addSubview:detailVC.view];

    for (UIViewController *thisVC in viewControllers)
        [thisVC didMoveToParentViewController:self];
}

- (void)setDividerView:(UIView *)aView
{
    [dividerView removeFromSuperview];
    dividerView = aView;
    
    if ([self isViewLoaded]) {
        [self.view addSubview:dividerView];
        [self viewDidLayoutSubviews];
    }
}

- (void)viewDidLayoutSubviews
{
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    [self layoutSubviewsForOrientation:UIInterfaceOrientationIsPortrait(interfaceOrientation)];
}

- (void)layoutSubviewsForOrientation:(BOOL)isPortrait
{
	if (viewControllers == nil)
		return;

	UIViewController *masterVC = [viewControllers objectAtIndex:0];
	UIViewController *detailVC = [viewControllers objectAtIndex:1];

    CGRect b = self.view.bounds;
	CGFloat width = b.size.width;
	CGFloat height = b.size.height;

    CGFloat masterSize = (isPortrait ? masterPortraitSize : masterLandscapeSize);
    CGFloat padding = (isPortrait ? portraitPadding : landscapePadding);

    switch (style) {
        case SMSSplitViewStyleLeft:
        {
            masterVC.view.frame = CGRectMake(0, 0, masterSize, height);
            CGFloat detailXOrigin = masterSize + padding;
            detailVC.view.frame = CGRectMake(detailXOrigin, 0, width-detailXOrigin, height);
            
            dividerView.frame = CGRectMake(masterSize, 0, padding, height);
        } break;
            
        case SMSSplitViewStyleRight:
        {
            CGFloat masterXOrigin = width - masterSize;
            masterVC.view.frame = CGRectMake(masterXOrigin, 0, masterSize, height);
            CGFloat detailWidth = masterXOrigin - padding;
            detailVC.view.frame = CGRectMake(0, 0, detailWidth, height);
            
            dividerView.frame = CGRectMake(detailWidth, 0, padding, height);
        } break;
            
        case SMSSplitViewStyleTop:
        {
            masterVC.view.frame = CGRectMake(0, 0, width, masterSize);
            CGFloat detailYOrigin = masterSize+padding;
            detailVC.view.frame = CGRectMake(0, detailYOrigin, width, height-detailYOrigin);
            
            dividerView.frame = CGRectMake(0, masterSize, width, padding);
        } break;
            
        case SMSSplitViewStyleBottom:
        {
            CGFloat masterYOrigin = height - masterSize;
            masterVC.view.frame = CGRectMake(0, masterYOrigin, width, masterSize);
            CGFloat detailHeight = masterYOrigin - padding;
            detailVC.view.frame = CGRectMake(0, 0, width, detailHeight);
            
            dividerView.frame = CGRectMake(0, detailHeight, width, padding);
        } break;
    }
    
    [dividerView layoutIfNeeded];
}

@end