//
//  UISearchBar.h
//  UIKit
//
//  Created by Peter Steinberger on 23.03.11.
//
/*
 * Copyright (c) 2011, The Iconfactory. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of The Iconfactory nor the names of its contributors may
 *    be used to endorse or promote products derived from this software without
 *    specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE ICONFACTORY BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "UIView.h"
#import "UITextField.h"
#import "UIButton.h"

@protocol UISearchBarDelegate;
@class UISearchLayer;
@class UISearchField;
@class UIKey;

@protocol UISearchLayerContainerViewProtocol <NSObject>
@required
- (UIWindow *)window;
- (CALayer *)layer;
- (BOOL)isHidden;
- (BOOL)isDescendantOfView:(UIView *)view;
- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;
@end

@protocol UISearchLayerTextDelegate <NSObject>
@required
- (BOOL)_textShouldBeginEditing;
- (void)_textDidBeginEditing;
- (BOOL)_textShouldEndEditing;
- (void)_textDidEndEditing;
- (BOOL)_textShouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;

@optional
- (void)_textDidChange;
- (void)_textDidChangeSelection;
- (void)_textDidReceiveReturnKey;
- (void)_searchScopeDidChange;
- (void)_searchCancelButtonClicked;
@end

@interface UISearchBar : UIView  <UISearchLayerContainerViewProtocol, UISearchLayerTextDelegate>{
    UISearchField *_searchField;
    BOOL _showsCancelButton;
    id<UISearchBarDelegate> _delegate;
    NSString *_placeholder;
	
    UIColor *_tintColor;
    BOOL _showsScopeBar;
    NSInteger _selectedScopeButtonIndex;
    NSArray *_scopeButtonTitles;
    
    NSString *identifier;
    
    UISearchLayer *_searchLayer;
    UIButton *_cancelButton;
    BOOL showsScopeBar;
    
	struct {
        BOOL shouldBeginEditing : 1;
        BOOL didBeginEditing : 1;
        BOOL shouldEndEditing : 1;
        BOOL didEndEditing : 1;
        BOOL textDidChange : 1;
        BOOL shouldChangeText : 1;
		BOOL searchButtonClicked : 1;
		BOOL bookmarkButtonClicked : 1;
		BOOL resultsButtonClicked : 1;
		BOOL selectedScopeButtonChanged : 1;
		BOOL doCommandBySelector : 1;
		BOOL didChange : 1;
    } _delegateHas;
}

@property (nonatomic, copy) NSString *text;
@property (nonatomic,assign) id<UISearchBarDelegate> delegate;
@property (nonatomic) BOOL showsCancelButton;
@property (nonatomic,copy) NSString *placeholder;
@property (nonatomic,retain) UIColor *tintColor;             // default is nil
@property (nonatomic, retain) UISearchLayer *searchLayer;
@property (nonatomic, retain) UIButton *cancelButton;
@property (nonatomic, assign) BOOL showsScopeBar;
@property (nonatomic, assign) NSInteger selectedScopeButtonIndex;
@property (nonatomic, retain) NSArray *scopeButtonTitles;
@property (nonatomic, retain) NSString *identifier;
@end


@protocol UISearchBarDelegate <NSObject>

@optional

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar;
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar;
- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar;
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar;
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText;
- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar;
- (void)searchBarBookmarkButtonClicked:(UISearchBar *)searchBar;
- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar;
- (void)searchBarResultsListButtonClicked:(UISearchBar *)searchBar;

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope;

@end
