//
//  CRMediaPickerController.m
//  Christian Roman
//
//  Created by Christian Roman on 9/4/14.
//  Copyright (c) 2014 Christian Roman. All rights reserved.
//

#import "CRMediaPickerController.h"

@import MobileCoreServices.UTCoreTypes;
@import AssetsLibrary;
@import AVFoundation;

@interface CRMediaPickerController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate, UIPopoverControllerDelegate>

@property (nonatomic, strong, readwrite) UIImagePickerController *imagePickerController;
@property (nonatomic, assign) BOOL lastMediaFlag;
@property (nonatomic, strong) UIPopoverController *popoverController;

@end

@implementation CRMediaPickerController

#pragma mark - ALAssetsLibrary

+ (ALAssetsLibrary *)defaultAssetsLibrary
{
    static dispatch_once_t onceQueue;
    static ALAssetsLibrary *__defaultAssetsLibrary = nil;
    dispatch_once(&onceQueue, ^{
        __defaultAssetsLibrary = [[ALAssetsLibrary alloc] init];
    });
    return __defaultAssetsLibrary;
}

#pragma mark - NSObject

- (instancetype)init
{
    self = [super init];
    if (self) {
        _mediaType = CRMediaPickerControllerMediaTypeImage;
        _sourceType = (CRMediaPickerControllerSourceType)(CRMediaPickerControllerSourceTypePhotoLibrary | CRMediaPickerControllerSourceTypeCamera);
        _showsCameraControls = YES;
        _cameraViewTransform = CGAffineTransformIdentity;
    }
    return self;
}

- (void)dealloc
{
    _imagePickerController = nil;
}

#pragma mark - Getters/Setters

- (void)setCameraFlashMode:(UIImagePickerControllerCameraFlashMode)cameraFlashMode
{
    _cameraFlashMode = cameraFlashMode;
    self.imagePickerController.cameraFlashMode = cameraFlashMode;
}

#pragma mark - Class Methods

- (void)presentMediaPicker
{
    [self presentMediaPickerWithSourceType:self.sourceType];
}

- (void)show
{
    if (self.sourceType == CRMediaPickerControllerSourceTypeLastPhotoTaken
        || self.sourceType == CRMediaPickerControllerSourceTypePhotoLibrary
        || self.sourceType == CRMediaPickerControllerSourceTypeCamera
        || self.sourceType == CRMediaPickerControllerSourceTypeSavedPhotosAlbum) {
        [self presentMediaPickerWithSourceType:self.sourceType];
    } else {
        [self chooseMedia];
    }
}

- (void)dismiss
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(CRMediaPickerControllerDidCancel:)]) {
        [self.imagePickerController.presentingViewController dismissViewControllerAnimated:YES completion:^{
            [self.delegate CRMediaPickerControllerDidCancel:self];
        }];
    } else {
        [self.imagePickerController.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
    }
}

- (void)presentMediaPickerWithSourceType:(CRMediaPickerControllerSourceType)sourceType
{
    if (self.lastMediaFlag || (sourceType & CRMediaPickerControllerSourceTypeLastPhotoTaken) == CRMediaPickerControllerSourceTypeLastPhotoTaken) {
        [self getLastMediaTaken];
        return;
    }
    
    UIImagePickerControllerSourceType imagePickerSourceType = [self imagePickerControllerSourceTypeFromMediaSourceType:sourceType];
    
    if (![UIImagePickerController isSourceTypeAvailable:imagePickerSourceType]) {
        
		NSString *photoLibraryNotAvailableMessage = NSLocalizedString(@"Photo Library not available", nil);
        
		if (imagePickerSourceType == UIImagePickerControllerSourceTypeCamera) {
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Camera not available", nil)
                                                                message:nil
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
            [alertView show];
            
        } else if (imagePickerSourceType == UIImagePickerControllerSourceTypePhotoLibrary) {
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:photoLibraryNotAvailableMessage
                                                                message:nil
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
            [alertView show];
            
        } else {
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:photoLibraryNotAvailableMessage
                                                                message:nil
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
            [alertView show];
            
        }
        return;
	}
    
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.modalPresentationStyle = self.delegate.modalPresentationStyle;// UIModalPresentationCurrentContext;
    imagePickerController.sourceType = imagePickerSourceType;
    
    if (imagePickerSourceType == UIImagePickerControllerSourceTypeCamera) {
        imagePickerController.showsCameraControls = self.showsCameraControls;
        imagePickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeAuto;
        
        if (self.cameraOverlayView) {
            self.cameraOverlayView.frame = imagePickerController.cameraOverlayView.frame;
            imagePickerController.cameraOverlayView = self.cameraOverlayView;
            self.cameraOverlayView = nil;
        }
        
        if (!CGAffineTransformEqualToTransform(self.cameraViewTransform, CGAffineTransformIdentity)) {
            imagePickerController.cameraViewTransform = self.cameraViewTransform;
        }
        
        if (self.cameraDevice) {
            imagePickerController.cameraDevice = self.cameraDevice;
        }
        
    }
    
    CRMediaPickerControllerMediaType mediaType = self.mediaType;
    if (mediaType & CRMediaPickerControllerMediaTypeVideo) {
        NSArray *mediaTypes;
        if (mediaType & CRMediaPickerControllerMediaTypeImage) {
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
            } else {
                mediaTypes = @[(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie];
            }
        } else {
            mediaTypes = @[(NSString *)kUTTypeMovie];
        }
        imagePickerController.mediaTypes = mediaTypes;
        
        /*
         CFStringRef mTypes[2] = { kUTTypeImage, kUTTypeMovie };
         CFArrayRef mTypesArray = CFArrayCreate(CFAllocatorGetDefault(), (const void**)mTypes, 2, &kCFTypeArrayCallBacks);
         pickerController.mediaTypes = (__bridge NSArray*)mTypesArray;
         CFRelease(mTypesArray);
         */
        
        if (self.videoQualityType) {
            imagePickerController.videoQuality = self.videoQualityType;
        }
        
        if (self.videoMaximumDuration) {
            imagePickerController.videoMaximumDuration = self.videoMaximumDuration;
        }
        
    }
    
    if (self.allowsEditing) {
        imagePickerController.allowsEditing = self.allowsEditing;
    }
    
    if (self.delegate) {
        
        self.imagePickerController = imagePickerController;
        
        if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)) {//&& (sourceType == UIImagePickerControllerSourceTypePhotoLibrary)) {
            self.popoverController = [self makePopoverController:self.imagePickerController];
            self.popoverController.delegate = self;
            
            [self.popoverController presentPopoverFromRect:CGRectMake(400, 400, 100, 100) inView:self.delegate.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            
            /*
            if (self.showFromBarButtonItem) {
                [self.popoverController presentPopoverFromBarButtonItem:self.showFromBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            } else {
                [self.popoverController presentPopoverFromRect:self.showFromRect inView:self.showFromViewController.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            }
             */
            
        } else {
            [self.delegate presentViewController:self.imagePickerController animated:YES completion:nil];
        }
    }
}

- (UIImagePickerControllerSourceType)imagePickerControllerSourceTypeFromMediaSourceType:(CRMediaPickerControllerSourceType)sourceType
{
    NSAssert(sourceType, nil);
    UIImagePickerControllerSourceType imagePickerSourceType;
    
    switch (sourceType) {
        case CRMediaPickerControllerSourceTypePhotoLibrary:
            imagePickerSourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            break;
        case CRMediaPickerControllerSourceTypeCamera:
            imagePickerSourceType = UIImagePickerControllerSourceTypeCamera;
            break;
        case CRMediaPickerControllerSourceTypeSavedPhotosAlbum:
            imagePickerSourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
            break;
        case CRMediaPickerControllerSourceTypeLastPhotoTaken:
            imagePickerSourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            break;
    }
    
    return imagePickerSourceType;
}

- (CRMediaPickerControllerSourceType)imagePickerControllerSourceTypeFromSourceType:(UIImagePickerControllerSourceType)sourceType
{
    CRMediaPickerControllerSourceType imagePickerSourceType;
    
    switch (sourceType) {
        case UIImagePickerControllerSourceTypePhotoLibrary:
            imagePickerSourceType = CRMediaPickerControllerSourceTypePhotoLibrary;
            break;
        case UIImagePickerControllerSourceTypeCamera:
            imagePickerSourceType = CRMediaPickerControllerSourceTypeCamera;
            break;
        case UIImagePickerControllerSourceTypeSavedPhotosAlbum:
            imagePickerSourceType = CRMediaPickerControllerSourceTypeSavedPhotosAlbum;
            break;
    }
    
    return imagePickerSourceType;
}

- (void)chooseMedia
{
	NSString *cancelButton = NSLocalizedString(@"Cancel", nil);
    
    NSString *mediaTypeString = @"photo or video";
    if ((self.mediaType & CRMediaPickerControllerMediaTypeImage) && !(self.mediaType & CRMediaPickerControllerMediaTypeVideo)) {
        mediaTypeString = @"photo";
    } else if ((self.mediaType & CRMediaPickerControllerMediaTypeVideo) && !(self.mediaType & CRMediaPickerControllerMediaTypeImage)) {
        mediaTypeString = @"video";
    }
    
    NSString *lastTakenLocalizedString = [NSString stringWithFormat:@"Last %@ taken", mediaTypeString];
    
    NSString *lastTakenButton = NSLocalizedString(lastTakenLocalizedString, nil);
    
	NSString *photoLibraryButton = NSLocalizedString(@"Photo Library", nil);
	NSString *savedPhotosButton = NSLocalizedString(@"Saved Photos", nil);
	NSString *cameraButton = NSLocalizedString(@"Camera", nil);
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:nil, nil];
    
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    
    NSInteger idx = 0;
    
    CRMediaPickerControllerSourceType sourceType = self.sourceType;
    
    if (sourceType & CRMediaPickerControllerSourceTypeLastPhotoTaken) {
        [actionSheet addButtonWithTitle:lastTakenButton];
        idx++;
    }
    
    if (sourceType & CRMediaPickerControllerSourceTypePhotoLibrary) {
        [actionSheet addButtonWithTitle:photoLibraryButton];
        idx++;
    }
    
    if (sourceType & CRMediaPickerControllerSourceTypeCamera
        && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [actionSheet addButtonWithTitle:cameraButton];
        idx++;
    }
    
    if (sourceType & CRMediaPickerControllerSourceTypeSavedPhotosAlbum) {
        [actionSheet addButtonWithTitle:savedPhotosButton];
        idx++;
    }
    
    [actionSheet addButtonWithTitle:cancelButton];
    
    [actionSheet setCancelButtonIndex:idx];
    
    if (self.delegate) {
        [actionSheet showInView:self.delegate.view];
    }
}

- (BOOL)startVideoCapture
{
    return [self.imagePickerController startVideoCapture];
}

- (void)stopVideoCapture
{
    [self.imagePickerController stopVideoCapture];
}

- (void)takePicture
{
    [self.imagePickerController takePicture];
}

#pragma mark - Helpers

- (void)getLastMediaTaken
{
    ALAssetsLibrary *assetsLibrary = [[self class] defaultAssetsLibrary];
    
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        
        if (*stop == YES) {
            return;
        }
        
        ALAssetsFilter *assetsFilter = [ALAssetsFilter allPhotos];
        
        if ((self.mediaType & CRMediaPickerControllerMediaTypeImage) && (self.mediaType & CRMediaPickerControllerMediaTypeVideo)) {
            assetsFilter = [ALAssetsFilter allAssets];
        } else if (self.mediaType & CRMediaPickerControllerMediaTypeVideo) {
            assetsFilter = [ALAssetsFilter allVideos];
        }
        
        group.assetsFilter = assetsFilter;
        
        if (group.numberOfAssets == 0) {
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(CRMediaPickerController:didFinishPickingAsset:error:)]) {
                [self.delegate CRMediaPickerController:self didFinishPickingAsset:nil error:nil];
            }
            
        } else {
            [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *asset, NSUInteger index, BOOL *innerStop) {
                
                if (index == NSNotFound || asset == nil) {
                    return;
                }
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(CRMediaPickerController:didFinishPickingAsset:error:)]) {
                    [self.delegate CRMediaPickerController:self didFinishPickingAsset:asset error:nil];
                }
                
                *innerStop = YES;
                
            }];
        }
        
        *stop = YES;
        
    } failureBlock:^(NSError *error) {
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(CRMediaPickerController:didFinishPickingAsset:error:)]) {
            [self.delegate CRMediaPickerController:self didFinishPickingAsset:nil error:error];
        }
        
    }];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if ([buttonTitle hasPrefix:@"Last"]) {
        self.lastMediaFlag = YES;
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"Camera", nil)]) {
        sourceType = UIImagePickerControllerSourceTypeCamera;
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"Saved Photos", nil)]) {
        sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"Cancel", nil)]) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(CRMediaPickerControllerDidCancel:)]) {
            [self.delegate CRMediaPickerControllerDidCancel:self];
        }
        return;
    }
    
    CRMediaPickerControllerSourceType mediaSourceType = [self imagePickerControllerSourceTypeFromSourceType:sourceType];
    
    [self presentMediaPickerWithSourceType:mediaSourceType];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(CRMediaPickerControllerDidCancel:)]) {
            [self.delegate CRMediaPickerControllerDidCancel:self];
        }
    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
    if (CFStringCompare((__bridge CFStringRef) mediaType, kUTTypeMovie, (CFStringCompareFlags)0) == kCFCompareEqualTo) {
        
        NSURL *mediaURL = [info objectForKey:UIImagePickerControllerMediaURL];
        NSURL *referenceURL = [info objectForKey:UIImagePickerControllerReferenceURL];
        
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(mediaURL.path)) {
            
            ALAssetsLibrary *assetsLibrary = [[self class] defaultAssetsLibrary];
            
            if (picker.sourceType == UIImagePickerControllerSourceTypeCamera || picker.allowsEditing) {
                
                [assetsLibrary writeVideoAtPathToSavedPhotosAlbum:mediaURL completionBlock:^(NSURL *assetURL, NSError *error) {
                    
                    if (!error) {
                        
                        [assetsLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                            
                            if (self.delegate && [self.delegate respondsToSelector:@selector(CRMediaPickerController:didFinishPickingAsset:error:)]) {
                                [picker.presentingViewController dismissViewControllerAnimated:YES completion:^{
                                    [self.delegate CRMediaPickerController:self didFinishPickingAsset:asset error:nil];
                                }];
                            } else {
                                [picker.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
                            }
                            
                        } failureBlock:^(NSError *err) {
                            
                            if (self.delegate && [self.delegate respondsToSelector:@selector(CRMediaPickerController:didFinishPickingAsset:error:)]) {
                                [picker.presentingViewController dismissViewControllerAnimated:YES completion:^{
                                    [self.delegate CRMediaPickerController:self didFinishPickingAsset:nil error:err];
                                }];
                            } else {
                                [picker.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
                            }
                            
                        }];
                        
                    } else {
                        
                        if (self.delegate && [self.delegate respondsToSelector:@selector(CRMediaPickerController:didFinishPickingAsset:error:)]) {
                            [picker.presentingViewController dismissViewControllerAnimated:YES completion:^{
                                [self.delegate CRMediaPickerController:self didFinishPickingAsset:nil error:error];
                            }];
                        } else {
                            [picker.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
                        }
                        
                    }
                    
                }];
                
            } else {
                
                [assetsLibrary assetForURL:referenceURL resultBlock:^(ALAsset *asset) {
                    
                    if (self.delegate && [self.delegate respondsToSelector:@selector(CRMediaPickerController:didFinishPickingAsset:error:)]) {
                        [picker.presentingViewController dismissViewControllerAnimated:YES completion:^{
                            [self.delegate CRMediaPickerController:self didFinishPickingAsset:asset error:nil];
                        }];
                    } else {
                        [picker.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
                    }
                    
                } failureBlock:^(NSError *error) {
                    
                    if (self.delegate && [self.delegate respondsToSelector:@selector(CRMediaPickerController:didFinishPickingAsset:error:)]) {
                        [picker.presentingViewController dismissViewControllerAnimated:YES completion:^{
                            [self.delegate CRMediaPickerController:self didFinishPickingAsset:nil error:error];
                        }];
                    } else {
                        [picker.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
                    }
                    
                }];
                
            }
            
        }
        
    } else if (CFStringCompare((__bridge CFStringRef) mediaType, kUTTypeImage, (CFStringCompareFlags)0) == kCFCompareEqualTo) {
        
        UIImage *image;
        if (self.allowsEditing) {
            image = [info objectForKey:UIImagePickerControllerEditedImage];
        } else {
            image = [info objectForKey:UIImagePickerControllerOriginalImage];
        }
        
        ALAssetsLibrary *assetsLibrary = [[self class] defaultAssetsLibrary];
        
        if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
            
            [assetsLibrary writeImageToSavedPhotosAlbum:image.CGImage orientation:(ALAssetOrientation)image.imageOrientation completionBlock:^(NSURL *assetURL, NSError *error ) {
                
                if (!error) {
                    
                    [assetsLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                        
                        if (self.delegate && [self.delegate respondsToSelector:@selector(CRMediaPickerController:didFinishPickingAsset:error:)]) {
                            [picker.presentingViewController dismissViewControllerAnimated:YES completion:^{
                                [self.delegate CRMediaPickerController:self didFinishPickingAsset:asset error:nil];
                            }];
                        } else {
                            [picker.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
                        }
                        
                    } failureBlock:^(NSError *err) {
                        
                        if (self.delegate && [self.delegate respondsToSelector:@selector(CRMediaPickerController:didFinishPickingAsset:error:)]) {
                            [picker.presentingViewController dismissViewControllerAnimated:YES completion:^{
                                [self.delegate CRMediaPickerController:self didFinishPickingAsset:nil error:err];
                            }];
                        } else {
                            [picker.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
                        }
                        
                    }];
                    
                } else {
                    
                    if (self.delegate && [self.delegate respondsToSelector:@selector(CRMediaPickerController:didFinishPickingAsset:error:)]) {
                        [picker.presentingViewController dismissViewControllerAnimated:YES completion:^{
                            [self.delegate CRMediaPickerController:self didFinishPickingAsset:nil error:error];
                        }];
                    } else {
                        [picker.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
                    }
                    
                }
                
            }];
            
        } else {
            
            [assetsLibrary assetForURL:[info objectForKey:UIImagePickerControllerReferenceURL] resultBlock:^(ALAsset *asset) {
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(CRMediaPickerController:didFinishPickingAsset:error:)]) {
                    [picker.presentingViewController dismissViewControllerAnimated:YES completion:^{
                        [self.delegate CRMediaPickerController:self didFinishPickingAsset:asset error:nil];
                    }];
                } else {
                    [picker.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
                }
                
            } failureBlock:^(NSError *error) {
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(CRMediaPickerController:didFinishPickingAsset:error:)]) {
                    [picker.presentingViewController dismissViewControllerAnimated:YES completion:^{
                        [self.delegate CRMediaPickerController:self didFinishPickingAsset:nil error:error];
                    }];
                } else {
                    [picker.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
                }
                
            }];
            
        }
        
    }
    
}

#pragma mark - UIPopoverControllerDelegate

- (void)showFromTabBar:(UITabBar *)tabBar
{
    
}

- (void)showFromBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    
}

- (void)showFromRect:(CGRect)rect
{
    
}

- (UIPopoverController *)makePopoverController:(UIImagePickerController *)pickerController
{
    if (self.popoverControllerClass) {
        return [[self.popoverControllerClass alloc] initWithContentViewController:pickerController];
    } else {
        return [[UIPopoverController alloc] initWithContentViewController:pickerController];
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.popoverController = nil;
    if (self.delegate && [self.delegate respondsToSelector:@selector(CRMediaPickerControllerDidCancel:)]) {
        [self.delegate CRMediaPickerControllerDidCancel:self];
    }
}

@end
