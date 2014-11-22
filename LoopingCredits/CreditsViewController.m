//
//  CreditsViewController.m
//
//  Created by Manjit Bedi on 2013-12-16.
//
//

#import <QuartzCore/QuartzCore.h>


#import "CreditsViewController.h"

@interface CreditsViewController ()
@property (strong, nonatomic) NSAttributedString *creditsString;
@property CGFloat heightOfTextBody;
@property NSUInteger numberOfLines;
@property BOOL userInterruption;
@property CGFloat duration;
@property CGFloat velocity;
@end

@implementation CreditsViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    CGFloat tHeight;
    CGFloat tWidth;
    tHeight = self.view.bounds.size.width;
    tWidth = self.view.bounds.size.height;
    _scrollView.frame = CGRectMake(0, 0, tWidth, tHeight);
    _tapGestureRecognizer.enabled = NO;
    
    NSString *fileName = @"credits";
    
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        fileName = [fileName stringByAppendingString:@"_ipad"];
    } else {
        fileName = [fileName stringByAppendingString:@"_iphone"];
    }
    
    // This is a new feature in iOS 7.  The HTML must not include any links...
    NSURL *url = [[NSBundle mainBundle] URLForResource:fileName withExtension:@"html"];
    NSError *error = nil;
    self.creditsString = [[NSAttributedString alloc] initWithFileURL:url
                                                             options:nil
                                                  documentAttributes:NULL
                                                               error:&error];
    
    [self viewSetup];
    
    CGFloat fontAverageSize;
    // TODO: if the fonts change in the HTML files, these needs to be updated.
    fontAverageSize = 26.0f;
    
    _velocity = fontAverageSize * 3.0f; // 3 lines per second
    _duration  = _scrollView.contentSize.height / _velocity;
    
    [self setupScrollPerspective];
}

// Credit to the source of this method:
//
// https://www.cocoacontrols.com/controls/swscrollview
- (void) setupScrollPerspective {
    
    CATransform3D transform = CATransform3DIdentity;
    //z distance
    float distance = [[UIScreen mainScreen] bounds].size.height;
    float ratio    = [[UIScreen mainScreen] bounds].size.height/[[UIScreen mainScreen] bounds].size.height;
    transform.m34 = - ratio / distance;
    transform = CATransform3DRotate(transform, 60.0f * M_PI / 180.0f, 1.f, 0.0f, 0.0f);
    _scrollView.layer.transform = transform;
    _scrollView.layer.zPosition = distance * ratio;
    _scrollView.layer.position = CGPointMake([[UIScreen mainScreen] bounds].size.width/2, [[UIScreen mainScreen] bounds].size.height/3);
}



- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self performSelector:@selector(animateCredits) withObject:self afterDelay:0.1];
}

#pragma mark - set up scroll view
// Insert a text view into the scroll view and set the content size such that the we fake scrolling
// infinitely.
//
// The content area height is : scroll view height + text view height + scroll view height.
//
//    +------------------------------------+
//    |                                    |
//    |                                    |
//    |                                    |
//    |               empty                |
//    |                                    |
//    |                                    |
//    |                                    |
//    |                                    |
//    +------------------------------------+
//    |                                    |
//    |                                    |
//    |                                    |
//    |                                    |
//    |             Text view              |
//    |                                    |
//    |                                    |
//    |                                    |
//    |                                    |
//    +------------------------------------+
//    |                                    |
//    |                                    |
//    |                                    |
//    |               empty                |
//    |                                    |
//    |                                    |
//    |                                    |
//    |                                    |
//    +------------------------------------+
//
- (void) viewSetup {
    CGPoint point = CGPointMake(0, _scrollView.frame.size.height);
    
    // Position the text view just outside the visible area.
    UITextView *textView = [self createTextViewAtCoord:point];
    [_scrollView addSubview:textView];
    
    // Need know adjust the frame size for the text view to show the full body of text
    _heightOfTextBody = [self textViewHeightForAttributedText:_creditsString andWidth:_scrollView.frame.size.width];
    CGRect tempRect = CGRectMake(textView.frame.origin.x, textView.frame.origin.y, textView.frame.size.width, _heightOfTextBody);
    textView.frame = tempRect;
    
    CGSize newSize = CGSizeMake(_scrollView.frame.size.width, _scrollView.frame.size.height * 2 + tempRect.size.height);
    _scrollView.contentSize = newSize;
    
#ifdef DEBUG
    NSLog(@"scrollview content size %@",  NSStringFromCGSize(_scrollView.contentSize));
#endif
}


- (CGFloat) textViewHeightForAttributedText:(NSAttributedString *)text andWidth:(CGFloat)width {
    UITextView *textView = [[UITextView alloc] init];
    [textView setAttributedText:text];
    CGSize size = [textView sizeThatFits:CGSizeMake(width, FLT_MAX)];
    return size.height;
}


// We want the credits offscreen initially. The y value is offset by the height of the scroll view.
- (UITextView *) createTextViewAtCoord:(CGPoint) point {
    CGRect viewFrame = CGRectMake(point.x, point.y, _scrollView.frame.size.width, _scrollView.frame.size.height);
    UITextView *textView = [[UITextView alloc] initWithFrame:viewFrame];
    textView.attributedText = _creditsString;
    textView.backgroundColor = [UIColor clearColor];
    textView.opaque = NO;
    textView.userInteractionEnabled = NO; // The scrolling is done by the scroll view.
    textView.allowsEditingTextAttributes = NO;
    textView.selectable = NO;
    
    return textView;
}

//
//  In the completion block for the animation, the method is called to start the sequence all over thus the animation keeps looping.
//
- (void) animateCredits {
    
    NSLog(@"animate credits");
    
    NSLog(@"layer speed %f", _scrollView.layer.speed);
    NSLog(@"layer timeOffset %f", _scrollView.layer.timeOffset);
    
    // Letting the user interact when an animation is playing is a bad experience.
//    _scrollView.userInteractionEnabled = NO;
    
    [UIView animateWithDuration:_duration
                          delay:0.2f
                        options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         CGPoint newOffset = CGPointMake(0, _scrollView.contentSize.height  - _scrollView.frame.size.height /2);
                         NSLog(@"content offset %@", NSStringFromCGPoint(newOffset));
                         _scrollView.contentOffset = newOffset;
                     }
                     completion:^(BOOL finished){
                         // If finished is false, the user may have interruped the animation.
                         if(finished) {
                             _scrollView.contentOffset = CGPointMake(0, 0);
                            // Need to adjust the duration as it may be have been changed during a user
                            // interaction.
                            _duration = _scrollView.contentSize.height / _velocity;
                            // This keeps the animation looping.
                            [self performSelector:@selector(animateCredits) withObject:self afterDelay:0.1];
                         } else {
                             NSLog(@"animation did not finish");
                         }
                     }];

}


// Some code copied from stack overflow:
// http://stackoverflow.com/questions/15119839/uiview-animation-block-pause-both-the-animation-and-the-completion-code
// Referencing a tech note from Apple:
// https://developer.apple.com/library/ios/qa/qa1673/_index.html
-(void)pauseLayer:(CALayer*)layer {
    CFTimeInterval pausedTime = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
    layer.speed = 0.0;
    layer.timeOffset = pausedTime;
    
//    NSLog(@"layer offset %@", layer
}


-(void)resumeLayer:(CALayer*)layer {
    CFTimeInterval pausedTime = [layer timeOffset];
    layer.speed = 1.0;
    layer.timeOffset = 0.0;
    layer.beginTime = 0.0;
    CFTimeInterval timeSincePause = [layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    layer.beginTime = timeSincePause;
}


#pragma mark - tap gesture handler
- (IBAction)tapHandler:(UITapGestureRecognizer *)sender {

    NSLog(@"tap event");
    
    if(sender.state == UIGestureRecognizerStateRecognized && _userInterruption == NO) {
        _userInterruption = YES;
        [self pauseLayer:_scrollView.layer];
        CGPoint offset = [_scrollView.layer.presentationLayer bounds].origin;
        NSLog(@"offset %@",  NSStringFromCGPoint(offset));
        [_scrollView.layer removeAllAnimations];
        for (CALayer* sublayer in [_scrollView.layer sublayers])
            [sublayer removeAllAnimations];

        [_scrollView setContentOffset:offset animated:NO];
        
    } else if(sender.state == UIGestureRecognizerStateEnded ) {
        _userInterruption = NO;
        //[self resumeLayer:_scrollView.layer];
        [self performSelector:@selector(resumeAnimation) withObject:nil afterDelay:0.5];
    }
}


- (void) resumeAnimation {
    //_scrollView.contentOffset = CGPointMake(0, 0);
    _scrollView.layer.timeOffset = 0.0;
    _scrollView.layer.speed = 1.0;
    
    CGFloat newDistance = _scrollView.contentSize.height - _scrollView.contentOffset.y;
    _duration = newDistance / _velocity;
    
    [self animateCredits];
}

#pragma mark - scroll view delegate methods

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSLog(@"scrolling ended");
    _userInterruption = NO;
    [self performSelector:@selector(resumeAnimation) withObject:nil afterDelay:1.0];
}

- (void) scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    _userInterruption = YES;
    [self pauseLayer:_scrollView.layer];
    CGPoint offset = [_scrollView.layer.presentationLayer bounds].origin;
    NSLog(@"offset %@",  NSStringFromCGPoint(offset));
    [_scrollView.layer removeAllAnimations];
    for (CALayer* sublayer in [_scrollView.layer sublayers])
        [sublayer removeAllAnimations];
    [_scrollView setContentOffset:offset animated:NO];
    [self performSelector:@selector(resumeAnimation) withObject:nil afterDelay:1.0];
}

@end
