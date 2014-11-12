//
//  XYZAddToDoItemViewController.m
//  ToDoList
//
//  Created by Simon Murtha Smith on 9/15/14.
//  Copyright (c) 2014 Simon Murtha Smith. All rights reserved.
//

#import "XYZAddToDoItemViewController.h"

//#import "HMAccount.h"

#import <SlabClient/SLCrypto.h>

//#import <AFNetworking.h>

@interface XYZAddToDoItemViewController ()
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;

@end

@implementation XYZAddToDoItemViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.textField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if (sender == self.cancelButton) return;

    if (self.textField.text.length > 0) {
        self.toDoItem = [[NSMutableDictionary alloc] init];
        if (self.imageView.image != nil) {
            CGSize newSize = CGSizeMake(600, 600);
            UIGraphicsBeginImageContext( newSize );
            [self.imageView.image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
            UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();

            NSData *imageData = UIImageJPEGRepresentation(newImage, 0.3);
            self.toDoItem[@"image"] = [SLCrypto stringWithHexFromData:imageData];
        }
        [self.toDoItem setValue: self.textField.text forKey:@"title"];
        [self.toDoItem setValue: @NO forKey:@"completed"];
        [self.toDoItem setValue: @NO forKey:@"logged"];
    }
}

-(BOOL)textFieldShouldReturn:(UITextField*)textField;
{
    [textField resignFirstResponder];

    [self performSegueWithIdentifier:@"UnwindToList" sender:self];

    return YES;
}


- (IBAction)addPhoto:(id)sender {

    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;

    [self presentViewController:picker animated:YES completion:NULL];
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {

    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    self.imageView.image = chosenImage;

    [picker dismissViewControllerAnimated:YES completion:NULL];

}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {

    [picker dismissViewControllerAnimated:YES completion:NULL];
    
}

@end
