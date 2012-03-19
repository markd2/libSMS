/*
 SMSChatViewController.m
 
 Copyright (c) 2011, Alex Silverman
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

#import "SMSChatViewController.h"
#import "NSDateFormatter+SMS.h"
#import "UIImage+SMS.h"
#import "SMSTableView.h"


@implementation UIColor (SMSChatViewController)

+ (id)chatBackgroundColor
{
	return [UIColor colorWithRed:0.826 green:0.858 blue:0.911 alpha:1.000];
}

+ (id)dateTextColor
{
	return [UIColor colorWithRed:0.427 green:0.427 blue:0.427 alpha:1.000];
}

@end


static NSDateFormatter *SMSChatViewControllerDateFormatter = nil;

@implementation SMSMessageCell

@synthesize message;

+ (void)initialize
{
	SMSChatViewControllerDateFormatter = [NSDateFormatter mediumFormatter];
}

- (id)init
{
	return [self initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    static NSString *SMSMessageCellId = @"SMSMessageCellId";
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SMSMessageCellId];
    
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	self.selectionStyle = UITableViewCellSelectionStyleNone;
	
	dateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	dateLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	dateLabel.backgroundColor = [UIColor chatBackgroundColor];
	dateLabel.textColor = [UIColor dateTextColor];
	dateLabel.font = [UIFont boldSystemFontOfSize:14];
	dateLabel.textAlignment = UITextAlignmentCenter;
	dateLabel.hidden = YES;
	[self.contentView addSubview:dateLabel];
	
	chatBubble = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 32)];
	chatBubble.autoresizingMask = UIViewAutoresizingFlexibleHeight;
	chatBubble.contentMode = UIViewContentModeScaleToFill;
	[self.contentView addSubview:chatBubble];
	
	messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 5, 60, 22)];
	messageLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	messageLabel.backgroundColor = [UIColor clearColor];
	messageLabel.numberOfLines = 0;
	messageLabel.font = [UIFont systemFontOfSize:16];
	[chatBubble addSubview:messageLabel];
	
	return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	dateLabel.frame = CGRectMake(0, 3, self.contentView.bounds.size.width, 16);
	
	messageLabel.text = [message message];
	
	CGSize size = [message size];
	
    BOOL dateVisible = [message dateVisible];
	if (dateVisible) {
		dateLabel.text = [SMSChatViewControllerDateFormatter stringFromDate:[message date]];
		dateLabel.hidden = NO;
	} else
		dateLabel.hidden = YES;
	
	if ([message isIncoming]) {
		chatBubble.frame = CGRectMake(0, (dateVisible ? 22 : 0), size.width, (dateVisible ? size.height-22 : size.height));
		UIImage *bubble = [UIImage imageNamed:@"SMSIncomingTextBubble.png"];
		if (bubble == nil)
			bubble = [UIImage smsImageNamed:@"SMSIncomingTextBubble" scale:SMSImageScaleDefault];
		chatBubble.image = [bubble stretchableImageWithLeftCapWidth:24 topCapHeight:17];
		chatBubble.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
	} else {
		chatBubble.frame = CGRectMake(self.contentView.bounds.size.width-size.width, (dateVisible ? 22 : 0), size.width, (dateVisible ? size.height-22 : size.height));
		UIImage *bubble = [UIImage imageNamed:@"SMSOutgoingTextBubble.png"];
		if (bubble == nil)
			bubble = [UIImage smsImageNamed:@"SMSOutgoingTextBubble" scale:SMSImageScaleDefault];
		chatBubble.image = [bubble stretchableImageWithLeftCapWidth:24 topCapHeight:17];
		chatBubble.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
	}
}

@end


@implementation SMSChatViewController

@synthesize delegate, messageLengthLimit;

- (id)init
{
	self = [super initWithNibName:nil bundle:nil];
	messages = [[NSMutableArray alloc] init];
	return self;
}

- (void)loadView
{
    [super loadView];
    
    _tableView = [[SMSTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
	_tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_tableView.dataSource = self;
	_tableView.delegate = self;
	[self.view addSubview:_tableView];
	
	chatField = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 290, 40)];
	chatField.userInteractionEnabled = YES;
    chatField.autoresizesSubviews = YES;
	chatField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
	chatField.contentMode = UIViewContentModeScaleToFill;
	UIImage *field = [UIImage smsImageNamed:@"SMSChatField" scale:SMSImageScaleDefault];
	chatField.image = [field stretchableImageWithLeftCapWidth:100 topCapHeight:0];
	[self.view addSubview:chatField];
	
	textField = [[UITextField alloc] initWithFrame:CGRectMake(18, 11, 190, 21)];
	textField.delegate = self;
	[textField addTarget:self action:@selector(textDidChange:) forControlEvents:UIControlEventEditingChanged];
	textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	textField.borderStyle = UITextBorderStyleNone;
	textField.font = [UIFont systemFontOfSize:15];
	textField.returnKeyType = UIReturnKeySend;
	[chatField addSubview:textField];
	
	sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
	sendButton.frame = CGRectMake(226, 7, 59, 26);
	sendButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
	[sendButton setBackgroundImage:[UIImage smsImageNamed:@"SMSSendButton" scale:SMSImageScaleDefault] forState:UIControlStateNormal];
	[sendButton setTitle:@"Send" forState:UIControlStateNormal];
	[sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:15];
	sendButton.enabled = NO;
	[sendButton addTarget:self action:@selector(sendMessage:) forControlEvents:UIControlEventTouchUpInside];
	[chatField addSubview:sendButton];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	self.view.backgroundColor = [UIColor chatBackgroundColor];
    
    _tableView.backgroundColor = [UIColor chatBackgroundColor];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.contentInset = UIEdgeInsetsMake(5, 0, 5, 0);
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keybWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keybWillHide:) name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keybDidHide:) name:UIKeyboardDidHideNotification object:nil];
	
	[self performSelector:@selector(scrollToBottom:) withObject:nil afterDelay:0.01];
}

- (void)viewDidLayoutSubviews
{
    CGRect bounds = [self.view bounds];
	self.tableView.frame = CGRectMake(0, 0, bounds.size.width, bounds.size.height-40);
	chatField.frame = CGRectMake(0, bounds.size.height-40, bounds.size.width, 40);
    textField.frame = CGRectMake(18, 11, bounds.size.width-100, 21);
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    self.tableView = nil;
	chatField = nil;
	textField = nil;
	sendButton = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Keyboard notifications

- (void)keybWillShow:(NSNotification *)notification
{
	if (![textField isFirstResponder])
		return;
	
	CGRect bounds = [self.view bounds];
	
	NSDictionary *userInfo = [notification userInfo];
	
	NSValue *frm = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
	CGRect keybFrame;
	[frm getValue:&keybFrame];
    keybFrame = [self.view convertRect:keybFrame fromView:(UIWindow *)[notification object]];
	
	[UIView beginAnimations:nil context:NULL];
	
	NSValue *ac = [userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
	UIViewAnimationCurve animCurve = 0;
	[ac getValue:&animCurve];
	[UIView setAnimationCurve:animCurve];
	
	NSValue *ad = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
	NSTimeInterval animDur = 0;
	[ad getValue:&animDur];
	[UIView setAnimationDuration:animDur];

	self.tableView.frame = CGRectMake(0, 0, bounds.size.width, keybFrame.origin.y-40);
	chatField.frame = CGRectMake(0, keybFrame.origin.y-40, bounds.size.width, 40);
	
	[UIView commitAnimations];
	
    if ([messages count] > 0)
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[messages count]-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (void)keybWillHide:(NSNotification *)notification
{
	if (![textField isFirstResponder])
		return;
	
	NSDictionary *userInfo = [notification userInfo];
	
	[UIView beginAnimations:nil context:NULL];
	
	NSValue *ac = [userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
	UIViewAnimationCurve animCurve = 0;
	[ac getValue:&animCurve];
	[UIView setAnimationCurve:animCurve];
	
	NSValue *ad = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
	NSTimeInterval animDur = 0;
	[ad getValue:&animDur];
	[UIView setAnimationDuration:animDur-0.05];
	
	[self viewDidLayoutSubviews];

	[UIView commitAnimations];
}

- (void)keybDidHide:(NSNotification *)notification
{
	[self viewDidLayoutSubviews];
}

#pragma mark - Messages

- (void)scrollToBottom:(BOOL)animated
{
	if ([messages count] == 0)
		return;
	[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[messages count]-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:animated];
}

- (void)_sortMessages
{
    NSSortDescriptor *dateSort = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
	NSArray *sortDescriptors = [NSArray arrayWithObject:dateSort];
	[messages sortUsingDescriptors:sortDescriptors];
}

- (void)setMessages:(NSArray *)msgs
{
	[messages removeAllObjects];
	[messages addObjectsFromArray:msgs];
	
    [self _sortMessages];
    
	[self.tableView reloadData];
	[self scrollToBottom:YES];
}

- (void)addMessages:(NSArray *)msgs
{
	[messages addObjectsFromArray:msgs];
	
    [self _sortMessages];
	
	[self.tableView reloadData];
	[self scrollToBottom:YES];
}

- (void)removeMessages:(NSArray *)msgs
{
	[messages removeObjectsInArray:msgs];
	
    [self _sortMessages];
	
	[self.tableView reloadData];
	[self scrollToBottom:YES];
}

- (void)sendMessage:(id)sender
{	
	if ([delegate respondsToSelector:@selector(chatViewController:didSendMessage:)])
		[delegate chatViewController:self didSendMessage:[textField text]];
}

- (void)clearCurrentMessage
{
	[textField resignFirstResponder];
	textField.text = nil;
	sendButton.enabled = NO;
}

#pragma mark - UITextField delegate

- (BOOL)textField:(UITextField *)tf shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (messageLengthLimit > 0) {
        if ([[textField.text stringByReplacingCharactersInRange:range withString:string] length] > messageLengthLimit)
            return NO;
    }
    return YES;
}

- (void)textDidChange:(UITextField *)tf
{
	sendButton.enabled = ([textField.text length] > 0);
}

- (BOOL)textFieldShouldReturn:(UITextField *)tf
{
	[self sendMessage:nil];
	return NO;
}

#pragma mark - Table View methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [messages count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGRect bounds = [self.tableView bounds];
	CGFloat w = 0.5*bounds.size.width;
	id<SMSMessage> thisMessage = [messages objectAtIndex:indexPath.row];
	CGSize s = [[thisMessage message] sizeWithFont:[UIFont systemFontOfSize:16] constrainedToSize:CGSizeMake(w, CGFLOAT_MAX)];
	s.width += 40;
	s.height += 18;
	
	if (indexPath.row == 0) {
		thisMessage.dateVisible = YES;
		s.height += 22;
	} else {
		NSDate *thisDate = [thisMessage date];
		NSDate *previousDate = [[messages objectAtIndex:indexPath.row-1] date];
		if ([thisDate timeIntervalSinceDate:previousDate] > 300) {
			thisMessage.dateVisible = YES;
			s.height += 22;
		} else
			thisMessage.dateVisible = NO;
	}
	
	thisMessage.size = s;
	return s.height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    static NSString *SMSMessageCellId = @"SMSMessageCellId";
    
    SMSMessageCell *cell = (SMSMessageCell *)[tableView dequeueReusableCellWithIdentifier:SMSMessageCellId];
    if (cell == nil)
        cell = [[SMSMessageCell alloc] init];
    
    id<SMSMessage> thisMessage = [messages objectAtIndex:indexPath.row];
	[cell setMessage:thisMessage];
    
    return cell;
}

@end