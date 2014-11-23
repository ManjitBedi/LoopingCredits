//
//  CreditsViewController.h
//
//  Created by Manjit Bedi on 2013-12-16.
//
//

#import <UIKit/UIKit.h>


@interface CreditsViewController : UIViewController <UIGestureRecognizerDelegate, UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITapGestureRecognizer *tapGestureRecognizer;
@property (weak, nonatomic) IBOutlet UIButton *button;
- (IBAction)tapHandler:(UITapGestureRecognizer *)sender;
- (IBAction)toggle3DEffect;
@end
