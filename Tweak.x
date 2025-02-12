#import "Headers.h"
#import "BUIAlertView.h"

static NSArray *confirmIDs;

static void settingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {

CFPreferencesAppSynchronize(CFSTR("com.sharedRoutine.confirmkill"));
confirmIDs = nil;
confirmIDs = (__bridge_transfer NSArray *)CFPreferencesCopyAppValue(CFSTR("ConfirmIDs"),CFSTR("com.sharedRoutine.confirmkill"));

}

%group iOS8Hooks
%hook SBAppSwitcherController
-(void)switcherScroller:(id)arg1 displayItemWantsToBeRemoved:(SBDisplayItem *)item {
	void (^resetScrollViews)() = ^{
		for (UIScrollView *scrollView in ((UIScrollView *)[[self pageController] valueForKey:@"_scrollView"]).subviews) {
			if ([scrollView isKindOfClass:UIScrollView.class]) {
				scrollView.contentOffset = CGPointZero;
			}
		}
	};

	if ([confirmIDs containsObject:item.displayIdentifier]) {
		BUIAlertView *av = [[BUIAlertView alloc] initWithTitle:@"Confirm Removal" message:@"Are you sure you want to close this App?" delegate:nil cancelButtonTitle:@"No" otherButtonTitles:@"Yes!", nil];
			[av showWithDismissBlock:^(UIAlertView *alertView, NSInteger buttonIndex, NSString *buttonTitle) {
	  		if ([buttonTitle isEqualToString:@"Yes!"]) {
	    		%orig;
	  		} else {
	  			[UIView animateWithDuration:0.3f animations:resetScrollViews];
	  		}
		}];
	} else {
		%orig;
	}
}

%end
%end

%group iOS7Hooks
%hook SBAppSliderController

- (void)sliderScroller:(SBAppSliderScrollingViewController *)scroller itemWantsToBeRemoved:(NSUInteger)index {

	void (^resetScrollViews)() = ^{
		for (UIScrollView *scrollView in self.contentScrollView.subviews) {
			if ([scrollView isKindOfClass:UIScrollView.class]) {
				scrollView.contentOffset = CGPointZero;
			}
		}
	};

    if ([confirmIDs containsObject:[self _displayIDAtIndex:index]]) {
    	BUIAlertView *av = [[BUIAlertView alloc] initWithTitle:@"Confirm Removal" message:@"Are you sure you want to close this App?" delegate:nil cancelButtonTitle:@"No" otherButtonTitles:@"Yes!", nil];
			[av showWithDismissBlock:^(UIAlertView *alertView, NSInteger buttonIndex, NSString *buttonTitle) {
	  		if ([buttonTitle isEqualToString:@"Yes!"]) {
	    		%orig;
	  		} else {
	  			[UIView animateWithDuration:0.3f animations:resetScrollViews];
	  		}
		}];
    } else {
    	%orig;
    }
}

%end
%end

%ctor {

	if (iOS8) {
		%init(iOS8Hooks);
	} else if (iOS7) {
		%init(iOS7Hooks);
	}

	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),NULL,settingsChanged,CFSTR("com.sharedRoutine.confirmkill.settingschanged"),NULL,CFNotificationSuspensionBehaviorDeliverImmediately);

}
