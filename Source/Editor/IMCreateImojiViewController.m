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

#import "IMCreateImojiViewController.h"
#import "IMCreateImojiView.h"
#import "IMTagCollectionView.h"
#import "IMResourceBundleUtil.h"
#import "IMImojiObject.h"
#import "IMImojiSession.h"
#import "IMCreateImojiAssistantViewController.h"
#import "IMPopInAnimatedTransition.h"
#import "IMCreateImojiUITheme.h"
#import <Masonry/Masonry.h>


@interface IMCreateImojiViewController () <IMCreateImojiViewDelegate, UIViewControllerTransitioningDelegate, UIToolbarDelegate>

@property(nonatomic, readonly) UIBarButtonItem *undoButton;
@property(nonatomic, readonly) UIBarButtonItem *cancelCreationButton;
@property(nonatomic, readonly) UIBarButtonItem *backToTraceButton;
@property(nonatomic, readonly) UIBarButtonItem *helpButton;
@property(nonatomic, readonly) UIBarButtonItem *finishTraceButton;
@property(nonatomic, readonly) UIBarButtonItem *finishTagButton;
@property(nonatomic, readonly) UIBarButtonItem *navigationTitle;

@property(nonatomic, readonly) UIView *creationView;
@property(nonatomic, readonly) UIView *tagView;

@property(nonatomic, readonly) IMTagCollectionView *tagCollectionView;
@property(nonatomic, readonly) UIToolbar *navigationToolbar;
@property(nonatomic, readonly) UIToolbar *traceToolbar;

@property(nonatomic, readonly) UIImageView *imojiPreview;

@property(nonatomic, strong) NSMutableArray *traceViewButtons;
@property(nonatomic, strong) NSArray *tagViewButtons;
@end

@implementation IMCreateImojiViewController {
}

- (instancetype)initWithSourceImage:(UIImage *)sourceImage session:(IMImojiSession *)session {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _sourceImage = sourceImage;
        _session = session;
    }

    return self;
}

- (void)loadView {
    [super loadView];

    UIView *view = [UIView new];

    _creationView = [UIView new];
    _tagView = [UIView new];

    _tagCollectionView = [IMTagCollectionView new];
    _navigationToolbar = [UIToolbar new];
    _traceToolbar = [UIToolbar new];

    _imojiEditor = [IMCreateImojiView new];
    _undoButton = [[UIBarButtonItem alloc] initWithImage:[IMCreateImojiUITheme instance].trimScreenUndoButtonImage
                                                   style:UIBarButtonItemStylePlain
                                                  target:self
                                                  action:@selector(performUndo)];
    _helpButton = [[UIBarButtonItem alloc] initWithImage:[IMCreateImojiUITheme instance].trimScreenHelpButtonImage
                                                   style:UIBarButtonItemStyleDone
                                                  target:self
                                                  action:@selector(showHelpScreen)];
    _cancelCreationButton = [[UIBarButtonItem alloc] initWithImage:[IMCreateImojiUITheme instance].trimScreenCancelButtonImage
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(cancelImageEdit)];
    _backToTraceButton = [[UIBarButtonItem alloc] initWithImage:[IMCreateImojiUITheme instance].tagScreenBackButtonImage
                                                          style:UIBarButtonItemStylePlain
                                                         target:self
                                                         action:@selector(showTrimView)];
    _finishTraceButton = [[UIBarButtonItem alloc] initWithImage:[IMCreateImojiUITheme instance].trimScreenFinishTraceButtonImage
                                                          style:UIBarButtonItemStyleDone
                                                         target:self
                                                         action:@selector(showTagScreen)];
    _finishTagButton = [[UIBarButtonItem alloc] initWithImage:[IMCreateImojiUITheme instance].tagScreenFinishButtonImage
                                                        style:UIBarButtonItemStylePlain
                                                       target:self
                                                       action:@selector(finishEditing)];

    _navigationTitle = [[UIBarButtonItem alloc] initWithTitle:[[IMResourceBundleUtil localizedStringForKey:@"createImojiHeaderTrim"] uppercaseString]
                                                        style:UIBarButtonItemStylePlain
                                                       target:nil
                                                       action:nil];

    [_navigationTitle setTitleTextAttributes:@{
                    NSFontAttributeName : [IMCreateImojiUITheme instance].tagScreenNavigationBarFont,
                    NSForegroundColorAttributeName : [IMCreateImojiUITheme instance].trimScreenTintColor
            }
                                    forState:UIControlStateNormal];

    _imojiPreview = [UIImageView new];

    _imojiEditor.editorDelegate = self;

    [self.imojiEditor loadImage:self.sourceImage];

    self.finishTagButton.enabled = YES;
    self.finishTraceButton.enabled = self.undoButton.enabled = NO;

    _imojiEditor.backgroundColor = [UIColor clearColor];
    view.backgroundColor = [IMCreateImojiUITheme instance].createViewBackgroundColor;

    [view addSubview:self.tagView];
    [view addSubview:self.creationView];
    [view addSubview:self.navigationToolbar];
    [view addSubview:self.traceToolbar];

    self.tagView.hidden = YES;
    self.imojiPreview.contentMode = UIViewContentModeScaleAspectFit;

    [self.creationView addSubview:self.imojiEditor];
    [self.tagView addSubview:self.imojiPreview];
    [self.tagView addSubview:self.tagCollectionView];

    self.traceToolbar.items = @[
            self.undoButton,
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
            self.finishTraceButton
    ];
    self.traceToolbar.tintColor = [IMCreateImojiUITheme instance].trimScreenTintColor;

    // to hide the top border
    self.traceToolbar.clipsToBounds = YES;
    [self.traceToolbar setBackgroundImage:[UIImage new]
                       forToolbarPosition:UIBarPositionAny
                               barMetrics:UIBarMetricsDefault];

    self.traceViewButtons = [NSMutableArray arrayWithArray:@[
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
            self.navigationTitle,
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
            self.helpButton
    ]];
    [self determineCancelCreationButtonVisibility];

    self.tagViewButtons = @[
            self.backToTraceButton,
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
            self.navigationTitle,
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
            self.finishTagButton
    ];

    self.navigationToolbar.items = self.traceViewButtons;
    self.navigationToolbar.tintColor = [IMCreateImojiUITheme instance].trimScreenTintColor;
    self.navigationToolbar.clipsToBounds = YES;
    self.navigationToolbar.delegate = self;
    [self.navigationToolbar setBackgroundImage:[UIImage new]
                            forToolbarPosition:UIBarPositionAny
                                    barMetrics:UIBarMetricsDefault];

    [self.tagView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.navigationToolbar.mas_bottom).offset(10);
        make.width.and.left.and.bottom.equalTo(view);
    }];

    [self.imojiPreview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.and.centerX.equalTo(self.tagView);
        make.width.and.height.equalTo(self.tagView.mas_width).dividedBy(3);
    }];

    [self.tagCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.imojiPreview.mas_bottom);
        make.width.equalTo(self.tagView).multipliedBy(.8f);
        make.centerX.and.bottom.equalTo(self.tagView);
    }];

    [self.navigationToolbar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.and.top.equalTo(view);
        make.height.equalTo(@50);
    }];

    [self.traceToolbar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.and.bottom.equalTo(view);
        make.height.equalTo(@90);
    }];

    [self.creationView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(view);
    }];

    [self.imojiEditor mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.creationView);
    }];

    self.view = view;

    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)performUndo {
    if ([self.imojiEditor canUndo]) {
        [self.imojiEditor undo];
        [self updateTrimButtonStates];
    }
}

- (void)showHelpScreen {
    IMCreateImojiAssistantViewController *assistantViewController =
            [IMCreateImojiAssistantViewController createAssistantViewControllerWithSession:self.session];

    assistantViewController.transitioningDelegate = self;
    assistantViewController.modalPresentationStyle = UIModalPresentationCustom;

    [self presentViewController:assistantViewController
                       animated:YES
                     completion:nil];
}

#pragma mark Delegate Dispatching

- (void)finishEditing {
    if (self.createDelegate && [self.createDelegate respondsToSelector:@selector(userDidFinishCreatingImoji:withError:fromViewController:)]) {
        [self.session createImojiWithImage:self.imojiEditor.outputImage
                                      tags:self.tagCollectionView.tags.array
                                  callback:^(IMImojiObject *imoji, NSError *error) {
                                      [self.createDelegate userDidFinishCreatingImoji:imoji withError:error fromViewController:self];
                                  }];
    }
}

- (void)cancelImageEdit {
    if (self.createDelegate && [self.createDelegate respondsToSelector:@selector(userDidCancelImageEdit:)]) {
        [self.createDelegate userDidCancelImageEdit:self];
    }
}

#pragma mark Showing/Hiding Tag and Trim Screens

- (void)showTagScreen {
    self.tagView.hidden = NO;
    self.traceToolbar.hidden = YES;
    self.tagView.layer.opacity = 0.0f;

    self.imojiPreview.image = self.imojiEditor.borderedOutputImage;

    self.navigationToolbar.clipsToBounds = NO;
    [self.navigationToolbar setBackgroundImage:nil
                            forToolbarPosition:UIBarPositionTop
                                    barMetrics:UIBarMetricsDefault];
    self.navigationToolbar.barTintColor = [IMCreateImojiUITheme instance].tagScreenNavigationToolbarBarTintColor;

    [UIView animateWithDuration:.5f
                     animations:^{
                         self.tagView.layer.opacity = 1.0f;
                         self.creationView.layer.opacity = 0.0f;
                         self.navigationToolbar.tintColor = [IMCreateImojiUITheme instance].tagScreenTintColor;

                         [_navigationTitle setTitleTextAttributes:@{
                                         NSFontAttributeName : [IMCreateImojiUITheme instance].tagScreenNavigationBarFont,
                                         NSForegroundColorAttributeName : self.navigationToolbar.tintColor
                                 }
                                                         forState:UIControlStateNormal];
                     }
                     completion:^(BOOL finished) {
                         self.creationView.hidden = YES;
                         [self.navigationTitle setTitle:[IMResourceBundleUtil localizedStringForKey:@"createImojiHeaderTag"]];
                         self.navigationToolbar.items = self.tagViewButtons;

                         self.tagCollectionView.tagInputFieldShouldBeFirstResponder = YES;
                     }
    ];
}

- (void)showTrimView {
    if (self.creationView.hidden) {
        self.creationView.hidden = NO;
        self.traceToolbar.hidden = NO;
        self.navigationToolbar.items = self.traceViewButtons;
        self.tagCollectionView.tagInputFieldShouldBeFirstResponder = YES;

        self.navigationToolbar.clipsToBounds = YES;
        [self.navigationToolbar setBackgroundImage:[UIImage new]
                                forToolbarPosition:UIBarPositionTop
                                        barMetrics:UIBarMetricsDefault];

        [UIView animateWithDuration:.5f
                         animations:^{
                             self.tagView.layer.opacity = 0.0f;
                             self.creationView.layer.opacity = 1.0f;
                             self.navigationToolbar.tintColor = [IMCreateImojiUITheme instance].trimScreenTintColor;

                             [_navigationTitle setTitleTextAttributes:@{
                                             NSFontAttributeName : [IMCreateImojiUITheme instance].trimScreenNavigationBarFont,
                                             NSForegroundColorAttributeName : [IMCreateImojiUITheme instance].trimScreenTintColor
                                     }
                                                             forState:UIControlStateNormal];
                         }
                         completion:^(BOOL finished) {
                             self.tagView.hidden = YES;
                             [self.navigationTitle setTitle:[IMResourceBundleUtil localizedStringForKey:@"createImojiHeaderTrim"]];
                         }];
    }
}

#pragma mark Toolbar Management

- (void)determineCancelCreationButtonVisibility {
    [self.traceViewButtons removeObject:self.cancelCreationButton];

    // add a close view button
    if (self.createDelegate && [self.createDelegate respondsToSelector:@selector(userDidCancelImageEdit:)]) {
        [self.traceViewButtons insertObject:self.cancelCreationButton atIndex:0];
    }

    self.navigationToolbar.items = self.traceViewButtons;
}

#pragma mark Public Methods

- (void)reset {
    [self showTrimView];
    [self.imojiEditor reset];
}

#pragma mark Property Accessor's

- (void)setCreateDelegate:(id <IMCreateImojiViewControllerDelegate>)createDelegate {
    BOOL changed = _createDelegate != createDelegate;
    _createDelegate = createDelegate;

    if (changed && self.navigationToolbar) {
        [self determineCancelCreationButtonVisibility];
    }
}

#pragma mark UIViewController overrides

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark IMCreateImojiViewDelegate

- (void)userDidUpdatePathInEditorView:(IMCreateImojiView *)editorView {
    [self updateTrimButtonStates];
}

- (void)updateTrimButtonStates {
    self.undoButton.enabled = self.imojiEditor.canUndo;
    self.finishTraceButton.enabled = self.imojiEditor.hasOutputImage;
}

#pragma mark Navigation Toolbar Delegate

- (UIBarPosition)positionForBar:(id <UIBarPositioning>)bar {
    return UIBarPositionTop;
}

#pragma mark UIViewControllerTransitioningDelegate

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                   presentingController:(UIViewController *)presenting
                                                                       sourceController:(UIViewController *)source {
    IMPopInAnimatedTransition *transition = [IMPopInAnimatedTransition new];
    transition.presenting = YES;
    return transition;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    return [IMPopInAnimatedTransition new];
}

#pragma mark Initialization

+ (instancetype)controllerWithSourceImage:(UIImage *)sourceImage session:(IMImojiSession *)session {
    return [[self alloc] initWithSourceImage:sourceImage session:session];
}

@end
