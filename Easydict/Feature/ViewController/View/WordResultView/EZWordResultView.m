//
//  EZWordResultView.m
//  Bob
//
//  Created by tisfeng on 2022/11/9.
//  Copyright © 2022 izual. All rights reserved.
//

#import "EZWordResultView.h"
#import "NSColor+MyColors.h"
#import "EZHoverButton.h"
#import "EZLabel.h"
#import "NSTextView+Height.h"
#import "EZConst.h"
#import "EZFixedQueryWindow.h"
#import "NSString+MM.h"
#import "EZLayoutManager.h"
#import "EZWindowManager.h"
#import "EZLinkButton.h"
#import "NSImage+EZResize.h"
#import "EZQueryService.h"
#import "EZBlueTextButton.h"
#import "EZMyLabel.h"

static const CGFloat kHorizontalMargin_8 = 8;
static const CGFloat kVerticalMargin_12 = 12;
static const CGFloat kVerticalPadding_8 = 8;

@interface EZWordResultView () <NSTextViewDelegate>

@property (nonatomic, strong) EZQueryResult *result;

@end


@implementation EZWordResultView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.wantsLayer = YES;
        self.layer.cornerRadius = EZCornerRadius_8;
        [self.layer excuteLight:^(CALayer *layer) {
            layer.backgroundColor = NSColor.resultViewBgLightColor.CGColor;
        } drak:^(CALayer *layer) {
            layer.backgroundColor = NSColor.resultViewBgDarkColor.CGColor;
        }];
    }
    return self;
}

- (void)refreshWithResult:(EZQueryResult *)result {
    self.result = result;
    EZTranslateWordResult *wordResult = result.wordResult;
    
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    __block NSView *lastView = nil;
    NSFont *textFont = [NSFont systemFontOfSize:14];
    NSFont *typeTextFont = textFont;
    NSColor *typeTextColor = [NSColor mm_colorWithHexString:@"#7A7A7A"];
    
    NSString *errorMsg = result.error.localizedDescription;
    
    mm_weakify(self);
    
    if (result.wordResult) {
        NSTextField *wordTextField = nil;
        wordTextField = [NSTextField mm_make:^(NSTextField *_Nonnull textField) {
            mm_strongify(self);
            [self addSubview:textField];
            textField.stringValue = result.text;
            [textField excuteLight:^(id _Nonnull x) {
                [x setTextColor:NSColor.resultTextLightColor];
            } drak:^(id _Nonnull x) {
                [x setTextColor:NSColor.resultTextDarkColor];
            }];
            textField.font = [NSFont boldSystemFontOfSize:22];
            textField.selectable = YES;
            textField.editable = NO;
            textField.bordered = NO;
            textField.backgroundColor = NSColor.clearColor;
            [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                if (lastView) {
                    make.top.equalTo(lastView.mas_bottom).offset(kVerticalPadding_8);
                } else {
                    make.top.offset(kVerticalPadding_8);
                }
                make.left.mas_equalTo(kHorizontalMargin_8);
            }];
        }];
        wordTextField.mas_key = @"wordTextField";
        lastView = wordTextField;
    }
    
    if (result.normalResults.count || errorMsg.length > 0) {
        NSTextField *typeTextField;
        __block CGFloat exceptedWidth = 0;

        if (result.wordResult) {
            typeTextField = [[NSTextField new] mm_put:^(NSTextField *_Nonnull textField) {
                mm_strongify(self);

                [self addSubview:textField];
                textField.stringValue = NSLocalizedString(@"explain", nil);
                textField.maximumNumberOfLines = 1;
                textField.font = typeTextFont;
                textField.editable = NO;
                textField.bordered = NO;
                textField.textColor = typeTextColor;
                textField.backgroundColor = NSColor.clearColor;
                [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                    if (lastView) {
                        make.top.equalTo(lastView.mas_bottom).offset(kVerticalMargin_12);
                    } else {
                        make.top.offset(kVerticalMargin_12);
                    }
                    make.left.mas_equalTo(kHorizontalMargin_8);
                    exceptedWidth += kHorizontalMargin_8;
                }];
            }];
            typeTextField.mas_key = @"typeTextField_normalResults";
            
            [typeTextField layoutSubtreeIfNeeded];
        }
        
        
        exceptedWidth += ceil(typeTextField.width);
        
        NSString *text = result.translatedText ?: errorMsg;
        
        EZLabel *resultLabel = [[EZLabel alloc] init];
        [self addSubview:resultLabel];
        resultLabel.text = text;
        resultLabel.delegate = self;
        
        
        [resultLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self).offset(-kHorizontalMargin_8);
            exceptedWidth += kHorizontalMargin_8;

            if (typeTextField) {
                make.top.equalTo(typeTextField);
                make.left.equalTo(typeTextField.mas_right);
            } else {
                if (lastView) {
                    make.top.equalTo(lastView.mas_bottom).offset(kVerticalMargin_12);
                } else {
                    make.top.equalTo(self).offset(kVerticalMargin_12);
                }
                
                CGFloat leftPadding = 5;
                exceptedWidth += leftPadding;
                make.left.equalTo(self).offset(leftPadding);
            }
        }];
        resultLabel.mas_key = @"resultLabel_normalResults";
        lastView = resultLabel;
        
        [self updateLabelHeight:resultLabel exceptedWidth:exceptedWidth];
    }
    
    [wordResult.phonetics enumerateObjectsUsingBlock:^(EZTranslatePhonetic *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSTextField *nameTextFiled = [NSTextField mm_make:^(NSTextField *_Nonnull textField) {
            mm_strongify(self);

            [self addSubview:textField];
            textField.stringValue = obj.name;
            textField.textColor = typeTextColor;
            textField.font = textFont;
            textField.editable = NO;
            textField.bordered = NO;
            textField.backgroundColor = NSColor.clearColor;
            [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.offset(kHorizontalMargin_8);
                if (idx == 0) {
                    if (lastView) {
                        make.top.equalTo(lastView.mas_bottom).offset(kVerticalMargin_12);
                    } else {
                        make.top.offset(kHorizontalMargin_8);
                    }
                } else {
                    make.top.equalTo(lastView.mas_bottom).offset(5);
                }
            }];
        }];
        nameTextFiled.mas_key = @"nameTextFiled_phonetics";
        
        // 部分没有音标文本
        NSTextField *valueTextField = nil;
        if (obj.value.length) {
            valueTextField = [NSTextField mm_make:^(NSTextField *_Nonnull textField) {
                mm_strongify(self);

                [self addSubview:textField];
                textField.stringValue = [NSString stringWithFormat:@"/ %@ /", obj.value];
                [textField excuteLight:^(id _Nonnull x) {
                    [x setTextColor:NSColor.resultTextLightColor];
                } drak:^(id _Nonnull x) {
                    [x setTextColor:NSColor.resultTextDarkColor];
                }];
                textField.font = textFont;
                textField.selectable = YES;
                textField.editable = NO;
                textField.bordered = NO;
                textField.backgroundColor = NSColor.clearColor;
                [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.left.equalTo(nameTextFiled.mas_right).offset(kHorizontalMargin_8);
                    make.centerY.equalTo(nameTextFiled);
                }];
            }];
            valueTextField.mas_key = @"valueTextField_phonetics";
        }
        
        EZHoverButton *audioButton = [[EZHoverButton alloc] init];
        [self addSubview:audioButton];
        audioButton.image = [NSImage imageNamed:@"audio"];
        audioButton.toolTip = @"播放音频";
        [audioButton mas_makeConstraints:^(MASConstraintMaker *make) {
            NSView *leftView = valueTextField ?: nameTextFiled;
            make.left.equalTo(leftView.mas_right).offset(4);
            make.centerY.equalTo(valueTextField ?: nameTextFiled);
            make.width.height.mas_equalTo(23);
        }];
        
        mm_weakify(self);
        [audioButton setClickBlock:^(EZButton *_Nonnull button) {
            NSLog(@"click audioButton");
            mm_strongify(self);
            if (self.playAudioBlock) {
                self.playAudioBlock(self, result.text);
            }
        }];
        audioButton.mas_key = @"audioButton_phonetics";
        lastView = audioButton;
    }];
    
    [wordResult.parts enumerateObjectsUsingBlock:^(EZTranslatePart *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSTextField *partTextFiled = nil;
        __block CGFloat exceptedWidth = 0;
        
        if (obj.part.length) {
            partTextFiled = [NSTextField mm_make:^(NSTextField *_Nonnull textField) {
                mm_strongify(self);

                [self addSubview:textField];
                textField.stringValue = obj.part;
                textField.textColor = typeTextColor;
                textField.font = typeTextFont;
                textField.editable = NO;
                textField.bordered = NO;
                textField.backgroundColor = NSColor.clearColor;
                [textField setContentCompressionResistancePriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
                [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.left.offset(kHorizontalMargin_8);
                    exceptedWidth += kHorizontalMargin_8;
                    
                    if (lastView) {
                        if (idx == 0) {
                            make.top.equalTo(lastView.mas_bottom).offset(kVerticalMargin_12);
                        } else {
                            make.top.equalTo(lastView.mas_bottom).offset(kVerticalPadding_8);
                        }
                    } else {
                        make.top.offset(kVerticalMargin_12);
                    }
                }];
            }];
            partTextFiled.mas_key = @"partTextFiled_parts";
            
            // Since use string calculate textField width incorrectly 😓
            [partTextFiled layoutSubtreeIfNeeded];
        }
        
        EZLabel *meanLabel = [EZLabel new];
        [self addSubview:meanLabel];
        NSString *text = [NSString mm_stringByCombineComponents:obj.means separatedString:@"; "];
        meanLabel.text = text;
        meanLabel.delegate = self;
        
       exceptedWidth += ceil(partTextFiled.width);
        
        [meanLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self).offset(-kHorizontalMargin_8);
            exceptedWidth += kHorizontalMargin_8;
            
            if (partTextFiled) {
                make.top.equalTo(partTextFiled);
                CGFloat leftLeading = 5;
                make.left.equalTo(partTextFiled.mas_right).offset(leftLeading);
                exceptedWidth += leftLeading;
            } else {
                make.left.equalTo(self).offset(kHorizontalMargin_8);
                exceptedWidth += kHorizontalMargin_8;

                if (lastView) {
                    CGFloat topPadding = kVerticalPadding_8;
                    if (idx == 0) {
                        topPadding = kVerticalMargin_12;
                    }
                    make.top.equalTo(lastView.mas_bottom).offset(topPadding);
                } else {
                    make.top.offset(kHorizontalMargin_8);
                }
            }
        }];
        meanLabel.mas_key = @"meanTextField_parts";
        lastView = meanLabel;
        
        [self updateLabelHeight:meanLabel exceptedWidth:exceptedWidth];
    }];
    
    [wordResult.exchanges enumerateObjectsUsingBlock:^(EZTranslateExchange *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSTextField *nameTextFiled = [NSTextField mm_make:^(NSTextField *_Nonnull textField) {
            mm_strongify(self);

            [self addSubview:textField];
            textField.stringValue = [NSString stringWithFormat:@"%@:", obj.name];
            [textField excuteLight:^(id _Nonnull x) {
                [x setTextColor:NSColor.resultTextLightColor];
            } drak:^(id _Nonnull x) {
                [x setTextColor:NSColor.resultTextDarkColor];
            }];
            textField.font = textFont;
            textField.selectable = YES;
            textField.editable = NO;
            textField.bordered = NO;
            textField.backgroundColor = NSColor.clearColor;
            [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.offset(kHorizontalMargin_8);
                if (lastView) {
                    if (idx == 0) {
                        make.top.equalTo(lastView.mas_bottom).offset(kVerticalMargin_12);
                    } else {
                        make.top.equalTo(lastView.mas_bottom).offset(kVerticalPadding_8);
                        ;
                    }
                } else {
                    make.top.offset(kHorizontalMargin_8);
                }
            }];
        }];
        nameTextFiled.mas_key = @"nameTextFiled_exchanges";
        
        [obj.words enumerateObjectsUsingBlock:^(NSString *_Nonnull word, NSUInteger idx, BOOL *_Nonnull stop) {
            EZBlueTextButton *wordButton = [[EZBlueTextButton alloc] init];
            [self addSubview:wordButton];
            [wordButton setTitle:word];

            [wordButton mas_makeConstraints:^(MASConstraintMaker *make) {
                if (idx == 0) {
                    make.left.equalTo(nameTextFiled.mas_right);
                } else {
                    make.left.equalTo(lastView.mas_right).offset(5);
                }
                make.centerY.equalTo(nameTextFiled);
            }];
            mm_weakify(self);
            [wordButton setClickBlock:^(EZButton * _Nonnull button) {
                mm_strongify(self);
                if (self.clickTextBlock) {
                    self.clickTextBlock(self, word);
                    self.copyTextBlock(self, word);
                }
            }];
            wordButton.mas_key = @"wordButton_words";
            
            lastView = wordButton;
        }];
    }];
    
    __block NSString *lastSimpleWordPart = nil;
    
    [wordResult.simpleWords enumerateObjectsUsingBlock:^(EZTranslateSimpleWord *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSTextField *partTextFiled = nil;
        if (obj.part.length && (!lastSimpleWordPart || ![obj.part isEqualToString:lastSimpleWordPart])) {
            // 添加 part label
            partTextFiled = [NSTextField mm_make:^(NSTextField *_Nonnull textField) {
                mm_strongify(self);

                [self addSubview:textField];
                textField.stringValue = obj.part;
                textField.textColor = typeTextColor;
                textField.font = textFont;
                textField.editable = NO;
                textField.bordered = NO;
                textField.backgroundColor = NSColor.clearColor;
                [textField mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.left.offset(kHorizontalMargin_8);
                    if (lastView) {
                        make.top.equalTo(lastView.mas_bottom).offset(kVerticalPadding_8);
                    } else {
                        make.top.offset(kVerticalPadding_8);
                    }
                }];
            }];
            partTextFiled.mas_key = @"partTextFiled_simpleWords";
            
            lastSimpleWordPart = obj.part;
        }
        
        __block CGFloat exceptedWidth = 0;

        EZBlueTextButton *wordButton = [[EZBlueTextButton alloc] init];
        [self addSubview:wordButton];
        [wordButton setTitle:obj.word];
        [wordButton mas_makeConstraints:^(MASConstraintMaker *make) {
            CGFloat leftOffset = kHorizontalMargin_8 - 2;
            exceptedWidth += leftOffset;
            make.left.offset(leftOffset); // Since button has been expanded, so need to be shifted to the left.
            if (partTextFiled) {
                make.top.equalTo(partTextFiled.mas_bottom).offset(5);
            } else {
                if (lastView) {
                    make.top.equalTo(lastView.mas_bottom).offset(kVerticalPadding_8);
                } else {
                    make.top.offset(kHorizontalMargin_8);
                }
            }
        }];
        
        exceptedWidth += (wordButton.width + 2 * wordButton.expandValue);
        
        mm_weakify(self);
        [wordButton setClickBlock:^(EZButton * _Nonnull button) {
            mm_strongify(self);
            if (self.clickTextBlock) {
                self.clickTextBlock(self, obj.word);
                self.copyTextBlock(self, obj.word);
            }
        }];
        wordButton.mas_key = @"wordButton_simpleWords";
        
        
        NSString *meanText = [NSString mm_stringByCombineComponents:obj.means separatedString:@"; "] ?: @"";
        
        EZLabel *meanLabel = [[EZLabel alloc] init];
        meanLabel.text = meanText;
        
        [self addSubview:meanLabel];
        [meanLabel excuteLight:^(id _Nonnull x) {
            [x setTextColor:NSColor.resultTextLightColor];
        } drak:^(id _Nonnull x) {
            [x setTextColor:NSColor.resultTextDarkColor];
        }];

        [meanLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(wordButton).offset(3); // Since word button has expand vlaue

            CGFloat leftOffset = 2;
            make.left.equalTo(wordButton.mas_right).offset(leftOffset);
            exceptedWidth += leftOffset;
            
            make.right.lessThanOrEqualTo(self).offset(-kHorizontalMargin_8);
            exceptedWidth += kHorizontalMargin_8;
        }];
        
        meanLabel.mas_key = @"meanLabel_simpleWords";
        lastView = meanLabel;
        
        [self updateLabelHeight:meanLabel exceptedWidth:exceptedWidth];
    }];
    
    EZHoverButton *audioButton = [[EZHoverButton alloc] init];
    [self addSubview:audioButton];
    audioButton.image = [NSImage imageNamed:@"audio"];
    audioButton.toolTip = @"播放音频";
    
    [audioButton setClickBlock:^(EZButton * _Nonnull button) {
        NSLog(@"audioActionBlock");
        mm_strongify(self);
        if (self.playAudioBlock) {
            self.playAudioBlock(self, self.copiedText);
        }
    }];
    audioButton.mas_key = @"audioButton";
    
    
    EZHoverButton *textCopyButton = [[EZHoverButton alloc] init];
    [self addSubview:textCopyButton];
    
    textCopyButton.image = [NSImage imageNamed:@"copy"];
    textCopyButton.toolTip = @"复制";
    
    [textCopyButton setClickBlock:^(EZButton * _Nonnull button) {
        NSLog(@"copyActionBlock");
        mm_strongify(self);
        if (self.copyTextBlock) {
            self.copyTextBlock(self, self.copiedText);
        }
    }];
    textCopyButton.mas_key = @"copyButton";
    
    CGFloat kTopMargin_10 = 10;
    CGFloat kRightMargin = 3;
    
    [audioButton mas_makeConstraints:^(MASConstraintMaker *make) {
        if (lastView) {
            make.top.equalTo(lastView.mas_bottom).offset(kTopMargin_10);
        } else {
            make.top.equalTo(self).offset(kTopMargin_10);
        }
        
        // ???: Must set bottom ?
        make.bottom.equalTo(self);
        make.left.offset(8);
        make.width.height.mas_equalTo(EZAudioButtonWidth_25);
    }];
    
    [textCopyButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(audioButton.mas_right).offset(kRightMargin);
        make.width.height.bottom.equalTo(audioButton);
    }];
    
    lastView = audioButton;
    
    
    EZLinkButton *linkButton = [[EZLinkButton alloc] init];
    [self addSubview:linkButton];
  
    NSImage *linkImage = [NSImage imageWithSystemSymbolName:@"link" accessibilityDescription:nil];
    linkImage = [linkImage resizeToSize:CGSizeMake(EZAudioButtonImageWidth_15, EZAudioButtonImageWidth_15)];
    linkButton.image = linkImage;
    linkButton.toolTip = @"Link";
    linkButton.link = [result.service wordLink];

    [linkButton excuteLight:^(NSButton *linkButton) {
        linkButton.image = [linkImage imageWithTintColor:[NSColor imageTintLightColor]];
    } drak:^(NSButton *linkButton) {
        linkButton.image = [linkImage imageWithTintColor:[NSColor imageTintDarkColor]];
    }];
    linkButton.mas_key = @"linkButton";
    
    [linkButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(textCopyButton.mas_right).offset(kRightMargin);
        make.width.height.bottom.equalTo(audioButton);
    }];
    
    
    [self mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(lastView);
    }];
}

/// Calcuate label height manually.
- (void)updateLabelHeight:(EZLabel *)label exceptedWidth:(CGFloat)exceptedWidth {
    // ???: 很奇怪，比如实际计算结果为 364，但界面渲染却是 364.5 😑
    CGFloat width = self.width - exceptedWidth;
    //    NSLog(@"text: %@, width: %@", label.text, @(width));
    
    CGFloat height = [label getHeightWithWidth:width]; // 397 ?
    //    NSLog(@"height: %@", @(height));
    
    //    height = [label getTextViewHeightWithWidth:width]; // 377
    //    NSLog(@"height: %@", @(height));
    
    [label mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(height));
        make.width.mas_equalTo(width);
    }];
}

- (NSString *)copiedText {
    return self.result.translatedText;
}

#pragma mark - NSTextViewDelegate

- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    // escape key
    if (commandSelector == @selector(cancelOperation:)) {
        //        NSLog(@"escape: %@", textView);
        [[EZWindowManager shared] closeFloatingWindow];
        return NO;
    }
    return NO;
}

@end