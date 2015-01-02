//
//  ViewController.m
//  Example
//
//  Created by Christian Roman on 1/1/15.
//  Copyright (c) 2015 Christian Roman. All rights reserved.
//

#import "ViewController.h"
#import "CRMediaPickerController.h"

@import MediaPlayer;

@interface ViewController () <CRMediaPickerControllerDelegate>

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIView *videoView;

@property (nonatomic, strong) IBOutlet UIView *overlayView;

@property (nonatomic, strong) MPMoviePlayerController *moviePlayer;

@property (nonatomic, strong) CRMediaPickerController *mediaPickerController;
@property (nonatomic, assign) CRMediaPickerControllerMediaType selectedMediaType;
@property (nonatomic, assign) CRMediaPickerControllerSourceType selectedSourceType;

@property (nonatomic, assign) BOOL allowsEditing;
@property (nonatomic, assign) BOOL cameraOverlay;
@property (nonatomic, assign) NSInteger deviceCameraSelected;

@end

@implementation ViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        _selectedMediaType = CRMediaPickerControllerMediaTypeImage | CRMediaPickerControllerMediaTypeVideo; // Both
        
        _selectedSourceType = CRMediaPickerControllerSourceTypePhotoLibrary |
        CRMediaPickerControllerSourceTypeCamera |
        CRMediaPickerControllerSourceTypeSavedPhotosAlbum |
        CRMediaPickerControllerSourceTypeLastPhotoTaken; // Prompt
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)dealloc
{
    _mediaPickerController = nil;
    
    [self.moviePlayer stop];
    [self.moviePlayer.view removeFromSuperview];
    self.moviePlayer = nil;
}

- (IBAction)mediaTypeSegmentedControlValueChanged:(id)sender
{
    UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
    
    switch (segmentedControl.selectedSegmentIndex) {
        case 0:
            self.selectedMediaType = CRMediaPickerControllerMediaTypeImage | CRMediaPickerControllerMediaTypeVideo;
            break;
        case 1:
            self.selectedMediaType = CRMediaPickerControllerMediaTypeImage;
            break;
        case 2:
            self.selectedMediaType = CRMediaPickerControllerMediaTypeVideo;
            break;
        default:
            break;
    }
}

- (IBAction)sourceTypeSegmentedControlValueChanged:(id)sender
{
    UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
    
    switch (segmentedControl.selectedSegmentIndex) {
        case 0:
            self.selectedSourceType =  CRMediaPickerControllerSourceTypePhotoLibrary |
            CRMediaPickerControllerSourceTypeCamera |
            CRMediaPickerControllerSourceTypeSavedPhotosAlbum |
            CRMediaPickerControllerSourceTypeLastPhotoTaken;
            break;
        case 1:
            self.selectedSourceType = CRMediaPickerControllerSourceTypePhotoLibrary;
            break;
        case 2:
            self.selectedSourceType = CRMediaPickerControllerSourceTypeCamera;
            break;
        case 3:
            self.selectedSourceType = CRMediaPickerControllerSourceTypeSavedPhotosAlbum;
            break;
        case 4:
            self.selectedSourceType = CRMediaPickerControllerSourceTypeLastPhotoTaken;
        default:
            break;
    }
}

- (IBAction)cameraOverlaySwitchValueChanged:(id)sender
{
    UISwitch *switchControl = (UISwitch *)sender;
    self.cameraOverlay = switchControl.isOn;
}

- (IBAction)allowsEditingSwitchValueChanged:(id)sender
{
    UISwitch *switchControl = (UISwitch *)sender;
    self.allowsEditing = switchControl.isOn;
}

- (IBAction)deviceCameraSegmentedControlValueChanged:(id)sender
{
    UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
    self.deviceCameraSelected = segmentedControl.selectedSegmentIndex;
}

- (IBAction)selectMediaButtonTapped:(id)sender
{
    self.mediaPickerController = [[CRMediaPickerController alloc] init];
    self.mediaPickerController.delegate = self;
    self.mediaPickerController.mediaType = self.selectedMediaType;
    self.mediaPickerController.sourceType = self.selectedSourceType;
    self.mediaPickerController.allowsEditing = self.allowsEditing;
    self.mediaPickerController.cameraDevice = (UIImagePickerControllerCameraDevice) self.deviceCameraSelected;
    
    if (self.cameraOverlay) {
        self.mediaPickerController.showsCameraControls = NO;
        [[NSBundle mainBundle] loadNibNamed:@"OverlayView" owner:self options:nil];
        self.mediaPickerController.cameraOverlayView = self.overlayView;
        self.overlayView = nil;
    }
    
    [self.mediaPickerController show];
}

- (IBAction)cancelOverlayViewButtonTapped:(id)sender
{
    [self.mediaPickerController dismiss];
}

- (IBAction)takePictureViewButtonTapped:(id)sender
{
    [self.mediaPickerController takePicture];
}

#pragma mark - CPDMediaPickerControllerDelegate

- (void)CRMediaPickerController:(CRMediaPickerController *)mediaPickerController didFinishPickingAsset:(ALAsset *)asset error:(NSError *)error
{
    if (!error) {
        
        if (asset) {
            
            if ([[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]) {
                
                ALAssetRepresentation *representation = asset.defaultRepresentation;
                UIImage *image = [UIImage imageWithCGImage:representation.fullScreenImage];
                self.imageView.image = image;
                
            } else if ([[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {
                
                self.moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:asset.defaultRepresentation.url];
                self.moviePlayer.movieSourceType = MPMediaTypeMovie;
                self.moviePlayer.controlStyle = MPMovieControlStyleDefault;
                self.moviePlayer.scalingMode = MPMovieScalingModeAspectFit;
                self.moviePlayer.repeatMode = MPMovieRepeatModeNone;
                self.moviePlayer.allowsAirPlay = NO;
                self.moviePlayer.shouldAutoplay = NO;
                
                self.moviePlayer.view.frame = self.videoView.bounds;
                self.moviePlayer.view.autoresizingMask = (UIViewAutoresizing)(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
                [self.videoView addSubview:self.moviePlayer.view];
                
                [self.moviePlayer prepareToPlay];
                
            }
            
        } else {
            NSLog(@"No media selected");
        }
        
    } else {
        NSLog(@"%@", error.localizedDescription);
    }
}

- (void)CRMediaPickerControllerDidCancel:(CRMediaPickerController *)mediaPickerController
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

@end
