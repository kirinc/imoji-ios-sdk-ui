//
//  ImojiSDKUI
//
//  Created by Nima Khoshini
//  Copyright (C) 2015 Imoji
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//

#import "IMSuggestionCategoryViewCell.h"
#import <Masonry/Masonry.h>
#import <ImojiSDKUI/IMAttributeStringUtil.h>

@implementation IMSuggestionCategoryViewCell {

}


- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self.imojiView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.and.centerX.equalTo(self);
            make.width.and.height.equalTo(@52.0f);
        }];

        self.titleView.adjustsFontSizeToFitWidth = YES;
        self.titleView.font = [IMAttributeStringUtil montserratLightFontWithSize:10.5f];
        self.titleView.textColor = [UIColor colorWithRed:57.0f / 255.0f green:61.0f / 255.0f blue:73.0f / 255.0f alpha:1.0f];

        [self.titleView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.imojiView.mas_bottom).offset(5.0f);
            make.width.and.centerX.equalTo(self);
            make.bottom.equalTo(self);
        }];
    }

    return self;
}

@end
