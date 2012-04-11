/*
 SMSViewController.m
 
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

#import "SMSViewController.h"

#ifdef TARGET_iOS
#import "SMSLoadingView.h"
#endif


SMSOrientation SMSDefaultPhoneRotationMask = 0;
SMSOrientation SMSDefaultPadRotationMask = 0;


@implementation SMSViewController

#ifdef TARGET_iOS
@synthesize loadingView;
#endif
@synthesize firstResponder, popup;
//@synthesize tableView=_tableView;

#pragma mark - Class Methods

+ (void)setDefaultRotationMask:(SMSOrientation)aRotationMask
{
	SMSDefaultPhoneRotationMask = aRotationMask;
	SMSDefaultPadRotationMask = aRotationMask;
}

+ (void)setDefaultPhoneRotationMask:(SMSOrientation)aRotationMask
{
	SMSDefaultPhoneRotationMask = aRotationMask;
}

+ (void)setDefaultPadRotationMask:(SMSOrientation)aRotationMask
{
	SMSDefaultPadRotationMask = aRotationMask;
}

#pragma mark - Instance Methods

- (id)init
{
    return [self initWithNibName:nil bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
        notificationObservers = [[NSMutableSet alloc] init];
    return self;
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	self.firstResponder = nil;
    //self.tableView = nil;
}

- (void)dealloc
{
    for (id observer in notificationObservers)
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    
    //self.httpRequest = nil;
#ifdef TARGET_iOS
    self.loadingView = nil;
#endif
    
    self.popup = nil;
}

#pragma mark - Transitions

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //[self.tableView flashScrollIndicators];
}

#pragma mark - Rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	UIUserInterfaceIdiom uiIdiom = UI_USER_INTERFACE_IDIOM();
	if ((uiIdiom == UIUserInterfaceIdiomPhone && SMSDefaultPhoneRotationMask > 0) || (uiIdiom == UIUserInterfaceIdiomPad && SMSDefaultPadRotationMask > 0)) {
		SMSOrientation mask = 0;
		if (uiIdiom == UIUserInterfaceIdiomPhone)
			mask = SMSDefaultPhoneRotationMask;
		else
			mask = SMSDefaultPadRotationMask;
		
		switch (interfaceOrientation) {
			case UIInterfaceOrientationPortrait:
				return (mask&SMSOrientationPortrait)>0;
			case UIInterfaceOrientationPortraitUpsideDown:
				return (mask&SMSOrientationPortraitUpsideDown)>0;
			case UIInterfaceOrientationLandscapeLeft:
				return (mask&SMSOrientationLandscapeLeft)>0;
			case UIInterfaceOrientationLandscapeRight:
				return (mask&SMSOrientationLandscapeRight)>0;
			default:
				return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
		}
	} else 
		return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	self.popup = nil;
}

#pragma mark - Loading View

#ifdef TARGET_iOS
- (void)setLoadingView:(SMSLoadingView *)lv
{
    [loadingView dismiss];
    loadingView = lv;
}
#endif

#pragma mark - First Responder

- (void)setFirstResponder:(id)fr
{
    if (fr == nil)
        [firstResponder resignFirstResponder];
    firstResponder = fr;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (firstResponder)
		self.firstResponder = nil;
	else
		[super touchesBegan:touches withEvent:event];
}

#pragma mark - UITextField delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	self.firstResponder = textField;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
	firstResponder = nil;
	return YES;
}

#pragma mark - UITextView delegate

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	self.firstResponder = textView;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
	if ([text isEqualToString:@"\n"]) {
		[textView resignFirstResponder];
		return NO;
	} else
		return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
	firstResponder = nil;
	return YES;
}

#pragma mark - Popup

- (void)setPopup:(id)aPopup
{
	if ([popup isKindOfClass:[UIActionSheet class]]) {
		UIActionSheet *actionSheet = (UIActionSheet *)popup;
		[actionSheet dismissWithClickedButtonIndex:actionSheet.cancelButtonIndex animated:YES];
	} else if ([popup respondsToSelector:@selector(dismissPopoverAnimated:)]) {
        [popup dismissPopoverAnimated:YES];
        if ([[popup delegate] respondsToSelector:@selector(popoverControllerDidDismissPopover:)])
            [[popup delegate] popoverControllerDidDismissPopover:popup];
    }
	
    if ([popup delegate] == self)
        [popup setDelegate:nil];
	popup = aPopup;
	[popup setDelegate:self];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (actionSheet == popup)
        popup = nil;
}

- (void)popoverControllerDidDismissPopover:(id)pc
{
	if (pc == popup)
        popup = nil;
}

#pragma mark - UIScrollView delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!shadow)
        return;
    
    if (!scrollView.dragging)
        return;
    
    static CGFloat yOffset = 0;
    
    CGFloat diff = scrollView.contentOffset.y - yOffset;
    if (diff > 2) {
        [UIView animateWithDuration:0.2
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             shadow.alpha = 1.0;
                         }
                         completion:nil];
        yOffset = scrollView.contentOffset.y;
    } else if (diff < -2) {
        [UIView animateWithDuration:0.2
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             shadow.alpha = 0.0;
                         }
                         completion:nil];
        yOffset = 0;
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!shadow)
        return;
    
    if (!decelerate) {
        [UIView animateWithDuration:0.5
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             shadow.alpha = 0.0;
                         }
                         completion:nil];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (!shadow)
        return;
    
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         shadow.alpha = 0.0;
                     }
                     completion:nil];
}

@end