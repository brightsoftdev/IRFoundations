//
//  IRPaginatedView.m
//  IRFoundations
//
//  Created by Evadne Wu on 4/17/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import "IRPaginatedView.h"

@interface IRPaginatedView () <UIScrollViewDelegate>

- (void) irInitialize;
- (BOOL) requiresVisiblePageAtIndex:(NSUInteger)anIndex;
- (void) ensureViewAtIndexVisible:(NSUInteger)anIndex;
- (void) removeOffscreenViews;

- (CGRect) pageRectForIndex:(NSUInteger)anIndex;
- (UIView *) existingViewForPageAtIndex:(NSUInteger)anIndex; // may return nil if page is not there

- (void) insertPageView:(UIView *)aView atIndex:(NSUInteger)anIndex; // swaps out existing object, calls methods if necessary
- (void) removePageView:(UIView *)aView fromIndex:(NSUInteger)anIndex; // swaps out existing object, calls methods if necessary

@property (nonatomic, readwrite, retain) UIScrollView *scrollView;

@property (nonatomic, readwrite, retain) NSMutableArray *allViews; // count equals number of pages, and contains either the UIView, or a NSNull if the view is determined to be unnecessary

@end


@implementation IRPaginatedView
@synthesize currentPage, numberOfPages;
@synthesize delegate, horizontalSpacing, scrollView, allViews;

- (id) initWithFrame:(CGRect)frame {

	self = [super initWithFrame:frame];
	if (!self) return nil;
	
	[self irInitialize];
	
	return self;

}

- (id) initWithCoder:(NSCoder *)aDecoder {

	self = [super initWithCoder:aDecoder];
	if (!self) return nil;
	
	[self irInitialize];
	
	return self;

}

- (void) irInitialize {

	self.scrollView = [[[UIScrollView alloc] initWithFrame:self.bounds] autorelease];
	self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.scrollView.pagingEnabled = YES;
	self.scrollView.bounces = YES;
	self.scrollView.alwaysBounceHorizontal = YES;
	self.scrollView.showsHorizontalScrollIndicator = NO;
	self.scrollView.showsVerticalScrollIndicator = NO;
	self.scrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
	self.scrollView.autoresizesSubviews = NO;
	self.scrollView.delegate = self;
	
	[self addSubview:self.scrollView];

}

- (void) reloadViews {

	for (UIView *aView in self.allViews)
	if ([aView isKindOfClass:[UIView class]])
	[aView removeFromSuperview];

	self.numberOfPages = [self.delegate numberOfViewsInPaginatedView:self];
	self.allViews = [[[NSArray irArrayByRepeatingObject:[NSNull null] count:self.numberOfPages] mutableCopy] autorelease];
	
	if ((self.currentPage + 1) <= numberOfPages)
	[self ensureViewAtIndexVisible:self.currentPage];
	
	[self setNeedsLayout];

}

- (void) setHorizontalSpacing:(CGFloat)newSpacing {

	NSParameterAssert(newSpacing > 0);

	if (horizontalSpacing == newSpacing)
	return;
	
	[self willChangeValueForKey:@"horizontalSpacing"];
	horizontalSpacing = newSpacing;
	[self didChangeValueForKey:@"horizontalSpacing"];
	
	[self setNeedsLayout];
	[self scrollToPageAtIndex:self.currentPage animated:NO];

}

- (void) setFrame:(CGRect)newFrame {

	if (CGRectEqualToRect(newFrame, self.frame))
		return;
		
	[super setFrame:newFrame];
	
	[self setNeedsLayout];
	[self scrollToPageAtIndex:self.currentPage animated:NO];
	
}

- (CGRect) pageRectForIndex:(NSUInteger)anIndex {

	return (CGRect){
	
		{ 1.0f * (float)self.horizontalSpacing + anIndex * self.scrollView.bounds.size.width, 0 },
		self.bounds.size
	
	};

}

- (BOOL) requiresVisiblePageAtIndex:(NSUInteger)anIndex {

	CGPoint currentScrollViewOffset = self.scrollView.contentOffset;
	
	if (CGRectContainsPoint([self pageRectForIndex:(anIndex - 1)], currentScrollViewOffset))
		return YES;
	
	if (CGRectContainsPoint([self pageRectForIndex:anIndex], currentScrollViewOffset))
		return YES;
	
	if (CGRectContainsPoint([self pageRectForIndex:(anIndex + 1)], currentScrollViewOffset))
		return YES;
		
	return NO;

}

- (void) ensureViewAtIndexVisible:(NSUInteger)anIndex {

	if ([self existingViewForPageAtIndex:anIndex])
	return;
	
	UIView *requestedView = [self.delegate viewForPaginatedView:self atIndex:anIndex];
	NSParameterAssert(requestedView);
	
	[self insertPageView:requestedView atIndex:anIndex];
	[self setNeedsLayout];

}

- (void) removeOffscreenViews {

	[[[self.allViews copy] autorelease] enumerateObjectsUsingBlock: ^ (id viewOrNull, NSUInteger idx, BOOL *stop) {
		
		if ([self existingViewForPageAtIndex:idx])
		if (![self requiresVisiblePageAtIndex:idx])
		[self removePageView:(UIView *)viewOrNull fromIndex:idx];
	
	}];

}

- (void) insertPageView:(UIView *)aView atIndex:(NSUInteger)anIndex {

	NSParameterAssert(aView);
	NSParameterAssert(![self existingViewForPageAtIndex:anIndex]);
	
	UIViewController *viewController = [self.delegate viewControllerForSubviewAtIndex:anIndex inPaginatedView:self];
	[self.allViews replaceObjectAtIndex:anIndex withObject:aView];
	
	[viewController viewWillAppear:NO];
	[self.scrollView addSubview:aView];
	[self setNeedsLayout];
	[viewController viewDidAppear:NO];

}

- (void) removePageView:(UIView *)aView fromIndex:(NSUInteger)anIndex {

	NSParameterAssert(aView);
	NSParameterAssert([self existingViewForPageAtIndex:anIndex]);
	
	UIViewController *viewController = [self.delegate viewControllerForSubviewAtIndex:anIndex inPaginatedView:self];
	[self.allViews replaceObjectAtIndex:anIndex withObject:[NSNull null]];
	
	[viewController viewWillDisappear:NO];
	[aView removeFromSuperview];
	[self.scrollView setNeedsLayout];
	[viewController viewWillDisappear:NO];

}

- (UIView *) existingViewForPageAtIndex:(NSUInteger)anIndex {

	id objectAtIndex = [self.allViews objectAtIndex:anIndex];

	if ([objectAtIndex isKindOfClass:[NSNull class]] || ![objectAtIndex isKindOfClass:[UIView class]])
	return nil;

	return (UIView *)objectAtIndex;

}

- (NSUInteger) indexOfPageAtCurrentContentOffset {

	CGFloat pageWidth = [self pageRectForIndex:0].size.width;
	if (pageWidth == 0) return 0;
	 
	CGFloat offsetX = self.scrollView.contentOffset.x;
	
	NSInteger firstIndex = (NSInteger)floorf(offsetX / pageWidth);
	NSInteger secondIndex = firstIndex + 1;
	
	CGRect firstIntersection = CGRectIntersection([self pageRectForIndex:(NSUInteger)firstIndex], (CGRect){ self.scrollView.contentOffset, self.scrollView.frame.size });
	CGRect secondIntersection = CGRectIntersection([self pageRectForIndex:(NSUInteger)secondIndex], (CGRect){ self.scrollView.contentOffset, self.scrollView.frame.size });
	
	CGFloat firstArea = (CGRectIsEmpty(firstIntersection) || CGRectIsNull(firstIntersection) || CGRectIsInfinite(firstIntersection)) ? 0 : CGRectGetWidth(firstIntersection) * CGRectGetHeight(firstIntersection);
	CGFloat secondArea = (CGRectIsEmpty(secondIntersection) || CGRectIsNull(secondIntersection) || CGRectIsInfinite(secondIntersection)) ? 0 : CGRectGetWidth(secondIntersection) * CGRectGetHeight(secondIntersection);
	
	return (NSUInteger)((firstArea < secondArea) ? secondIndex : MAX(0, firstIndex));

}

- (void) scrollToPageAtIndex:(NSUInteger)anIndex animated:(BOOL)animate {

	[self.scrollView scrollRectToVisible:IRCGSizeGetCenteredInRect(self.bounds.size, [self pageRectForIndex:anIndex], 0.0f, YES) animated:animate];

}

- (void) scrollViewDidScroll:(UIScrollView *)aScrollView {

	NSUInteger index = 0; for (index = 0; index < self.numberOfPages; index++) {
	
		if ([self requiresVisiblePageAtIndex:index])
			[self ensureViewAtIndexVisible:index];
	
		[self existingViewForPageAtIndex:index].frame = [self pageRectForIndex:index];

	}
	
	self.currentPage = [self indexOfPageAtCurrentContentOffset];

}

- (void) layoutSubviews {

	[super layoutSubviews];
	
	//	Bug, don’t set the same frame or it will not bounce at all
	CGRect newFrame = CGRectInset(self.bounds, -1 * self.horizontalSpacing, 0);
	if (!CGRectEqualToRect(self.scrollView.frame, newFrame))
		self.scrollView.frame = newFrame;
	
	self.scrollView.contentSize = (CGSize){
		CGRectGetWidth(self.scrollView.bounds) * self.numberOfPages,
		CGRectGetHeight(self.scrollView.bounds)
	};
	
	[self scrollViewDidScroll:self.scrollView];
	
}

- (UIView *) existingPageAtIndex:(NSUInteger)anIndex {
	
	id object = nil;
	@try { object = [self.allViews objectAtIndex:anIndex]; }@catch (NSException *e) { };
	
	if (![object isKindOfClass:[UIView class]])
	return nil;
	
	return (UIView *)object;

}

- (void) dealloc {

	[super dealloc];

}


@end
