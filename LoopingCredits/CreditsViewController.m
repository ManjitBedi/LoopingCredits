//
//  CreditsViewController.m
//
//  Created by Manjit Bedi on 2013-12-16.
//
//

#import <QuartzCore/QuartzCore.h>


#import "CreditsViewController.h"

@interface CreditsViewController ()
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITapGestureRecognizer *tapGestureRecognizer;
@property (weak, nonatomic) IBOutlet UIButton *button;

@property (strong, nonatomic) NSAttributedString *creditsString;
@property CGFloat heightOfTextBody;
@property NSUInteger numberOfLines;
@property BOOL userInterruption;
@property CGFloat duration;
@property BOOL use3DTransform;
@property CGFloat velocity;


- (IBAction)tapHandler:(UITapGestureRecognizer *)sender;
- (IBAction)toggle3DEffect;

@end

@implementation CreditsViewController

- (void) viewDidLoad {
    [super viewDidLoad];

    // Use this hack if the desired orientation is Landscape.
    // and or modify viewSetup and invoke it in the viewDidAppear method...
//    CGFloat tHeight;
//    CGFloat tWidth;
//    tHeight = self.view.bounds.size.width;
//    tWidth = self.view.bounds.size.height;
//    _scrollView.frame = CGRectMake(0, 0, tWidth, tHeight);
    _tapGestureRecognizer.enabled = NO;

    NSString *fileName = @"credits";

    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        fileName = [fileName stringByAppendingString:@"_ipad"];
    } else {
        fileName = [fileName stringByAppendingString:@"_iphone"];
    }

    // This is a new feature introduced in iOS 7.  The HTML must not include any links...
    NSURL *url = [[NSBundle mainBundle] URLForResource:fileName withExtension:@"html"];
    NSError *error = nil;
    self.creditsString = [[NSAttributedString alloc] initWithFileURL:url options: @{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType} documentAttributes:nil error:&error];

}

// Credit to the source of this method:
//
// https://www.cocoacontrols.com/controls/swscrollview
- (void) applyPerspectiveTransform {
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


- (void) removePerspectiveTransform {
    _scrollView.layer.transform = CATransform3DIdentity;
    _scrollView.layer.zPosition = 0;
    _scrollView.layer.position = CGPointMake(0.5,0.5);
}


- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self viewSetup];
    CGFloat fontAverageSize;
    fontAverageSize = 26.0f;
    self.velocity = fontAverageSize * 3.0f; // 3 lines per second
    self.duration  = self.scrollView.contentSize.height / self.velocity;
    [self performSelector:@selector(animateCredits) withObject:self afterDelay:0.1];
}

#pragma mark - set up scroll view
// Insert a text view into the scroll view and set the content size such that the we can fake
// scrolling infinitely.
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
    [self.scrollView addSubview:textView];

    // Need know adjust the frame size for the text view to show the full body of text
    self.heightOfTextBody = [self textViewHeightForAttributedText:_creditsString andWidth:_scrollView.frame.size.width];
    CGRect tempRect = CGRectMake(textView.frame.origin.x, textView.frame.origin.y, textView.frame.size.width, self.heightOfTextBody);
    textView.frame = tempRect;

    CGSize newSize = CGSizeMake(self.scrollView.frame.size.width, self.scrollView.frame.size.height * 2 + tempRect.size.height);
    self.scrollView.contentSize = newSize;

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
#ifdef DEBUG
    NSLog(@"animate credits");
    NSLog(@"layer speed %f", self.scrollView.layer.speed);
    NSLog(@"layer timeOffset %f", self.scrollView.layer.timeOffset);
#endif
    
    __weak CreditsViewController *weakSelf = self;
    [UIView animateWithDuration:_duration
                          delay:0.2f
                        options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         CGPoint newOffset = CGPointMake(0, weakSelf.scrollView.contentSize.height  - weakSelf.scrollView.frame.size.height /2);
                         NSLog(@"content offset %@", NSStringFromCGPoint(newOffset));
                         weakSelf.scrollView.contentOffset = newOffset;
                     }
                     completion:^(BOOL finished){
                         // If finished is false, the user may have interruped the animation.
                         if(finished) {
                             weakSelf.scrollView.contentOffset = CGPointMake(0, 0);
                            // Need to adjust the duration as it may be have been changed during a user
                            // interaction.
                            weakSelf.duration = weakSelf.scrollView.contentSize.height / weakSelf.velocity;
                            // This keeps the animation looping.
                            [self performSelector:@selector(animateCredits) withObject:self afterDelay:0.1];
                         } else {
                             NSLog(@"animation did not finish");
                         }
                     }];
    
    [UIView animateWithDuration:_duration
                          delay:0.2f
                        options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionRepeat  | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         CGPoint newOffset = CGPointMake(0, weakSelf.scrollView.contentSize.height  - weakSelf.scrollView.frame.size.height /2);
                         NSLog(@"content offset %@", NSStringFromCGPoint(newOffset));
                         weakSelf.scrollView.contentOffset = newOffset;
                     }
                     completion:^(BOOL finished){
                         // If finished is false, the user may have interruped the animation.
                         if(!finished) {
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
}


-(void)resumeLayer:(CALayer*)layer {
    CFTimeInterval pausedTime = [layer timeOffset];
    layer.speed = 1.0;
    layer.timeOffset = 0.0;
    layer.beginTime = 0.0;
    CFTimeInterval timeSincePause = [layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    layer.beginTime = timeSincePause;
}


#pragma mark - button events
- (IBAction)toggle3DEffect{
    
    if(_use3DTransform){
        _use3DTransform = NO;
        _button.selected = NO;
        [self removePerspectiveTransform];
    } else {
        _use3DTransform = YES;
        _button.selected= YES;
        [self applyPerspectiveTransform];
    }
}

#pragma mark - tap gesture handler
- (IBAction)tapHandler:(UITapGestureRecognizer *)sender {
#ifdef DEBUG
    NSLog(@"tap event");
#endif
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
#ifdef DEBUG
    NSLog(@"scrolling ended");
#endif

    [self performSelector:@selector(resumeAnimation) withObject:nil afterDelay:1.0];
}


- (void) scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if(_userInterruption == NO) {
#ifdef DEBUG
        NSLog(@"stop animation");
#endif
        _userInterruption = YES;
        [self pauseLayer:_scrollView.layer];
        CGPoint offset = [_scrollView.layer.presentationLayer bounds].origin;
#ifdef DEBUG
        NSLog(@"offset %@",  NSStringFromCGPoint(offset));
#endif
        [_scrollView.layer removeAllAnimations];
        for (CALayer* sublayer in [_scrollView.layer sublayers])
            [sublayer removeAllAnimations];
        [_scrollView setContentOffset:offset animated:NO];
        [self performSelector:@selector(resumeAnimation) withObject:nil afterDelay:1.0];
    }
}

@end
