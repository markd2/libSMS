/*
 SMSChatViewController.h
 
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

#import <UIKit/UIKit.h>
#import "SMSViewController.h"


@protocol SMSMessage <NSObject>

@property (nonatomic) BOOL dateVisible;
@property (nonatomic) CGSize size;
- (NSString *)message;
- (BOOL)isIncoming;
- (NSDate *)date;

@end


@interface UIColor (SMSChatViewController)

+ (id)chatBackgroundColor;
+ (id)dateTextColor;

@end


@interface SMSMessageCell : UITableViewCell {
	id<SMSMessage> message;
	
	UILabel *dateLabel;
	UIImageView *chatBubble;
	UILabel *messageLabel;
}
@property (nonatomic, strong) id<SMSMessage> message;

@end


@protocol SMSChatViewControllerDelegate;

@interface SMSChatViewController : SMSViewController <UITableViewDataSource, UITableViewDelegate> {
	UIImageView *chatField;
	UITextField *textField;
	UIButton *sendButton;
	
	NSMutableArray *messages;
}
@property (nonatomic, weak) id<SMSChatViewControllerDelegate> delegate;
@property (nonatomic) NSUInteger messageLengthLimit;

- (void)setMessages:(NSArray *)msgs;
- (void)addMessages:(NSArray *)msgs;
- (void)removeMessages:(NSArray *)msgs;

- (void)clearCurrentMessage;

@end


@protocol SMSChatViewControllerDelegate <NSObject>

- (void)chatViewController:(SMSChatViewController *)chatVC didSendMessage:(NSString *)msg;

@end