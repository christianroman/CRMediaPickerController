CRMediaPickerController
=======================
A easy-to-use `UIImagePickerController` replacement for picking Images and Videos.

[![Platform](https://img.shields.io/cocoapods/p/CRMediaPickerController.svg?style=flat)](http://cocoadocs.org/docsets/CRMediaPickerController)
[![Version](https://img.shields.io/cocoapods/v/CRMediaPickerController.svg?style=flat)](http://cocoadocs.org/docsets/CRMediaPickerController)
[![CI](http://img.shields.io/travis/chroman/CRMediaPickerController.svg?style=flat)](https://travis-ci.org/chroman/CRMediaPickerController)
[![License](https://img.shields.io/cocoapods/l/CRMediaPickerController.svg?style=flat)](http://cocoadocs.org/docsets/CRMediaPickerController)

<br />
<img src="http://chroman.me/wp-content/uploads/2015/01/CRMediaPickerController.png" width="621">

Overview
-----
Picking, taking, or using the last photo or video made easy!

Features
-----
* Allows user to pick/capture 2 types of media (Photo and Video).
* Picking options: Camera, Camera Roll, Photo Library and Last photo/video taken.
* Delegate protocol available for more control.
* Fully customizable with `UIImagePickerController` properties (Camera Overlay, Camera Device, Camera View Transform, allowsEditing, etc).
* Uses Assets Library Framework, provides original `ALAsset`. (Easy to deal with).
* Supports Portrait & Landscape Modes.
* Native iOS UI (It uses `UIImagePickerController` under the hood).
* Easy to apply in your project.

Installation
-----

There are two options:

**CocoaPods**

* Add the dependency to your Podfile:
```ruby
platform :ios
pod 'CRMediaPickerController'
...
```

* Run `pod install` to install the dependencies.

**Source files**

* Just clone this repository or download it in zip-file.
* Then you will find source files under **CRMediaPickerController** directory.
* Copy them to your project.

Usage
-----

`CRMediaPickerController` is created and displayed in a very similar manner to the `UIImagePickerController`. To use `CRMediaPickerController` you need create an instance, configure it, display it and implement the delegate methods.

An example of creating and displaying a `CRMediaPickerController` instance:

```objc
self.mediaPickerController = [[CRMediaPickerController alloc] init];
self.mediaPickerController.delegate = self;
self.mediaPickerController.mediaType = CRMediaPickerControllerMediaTypeImage;
self.mediaPickerController.sourceType = CRMediaPickerControllerSourceTypePhotoLibrary;
[self.mediaPickerController show];
```

### Properties

* **Media Type**

`mediaType`

The media type for the picking or create process. Supports Photo, Video or both.

```objc
self.mediaPickerController.mediaType = (CRMediaPickerControllerMediaTypeImage | CRMediaPickerControllerMediaTypeVideo);
```

Available options:
```objc
typedef NS_OPTIONS(NSInteger, CRMediaPickerControllerMediaType) {
    CRMediaPickerControllerMediaTypeImage = 1 << 0,
    CRMediaPickerControllerMediaTypeVideo = 1 << 1
};
```

* **Source Type**

`sourceType`

The source for picking or create the media file. Multiple sources supported.

```objc
self.mediaPickerController.sourceType = (CRMediaPickerControllerSourceTypePhotoLibrary | CRMediaPickerControllerSourceTypeCamera | CRMediaPickerControllerSourceTypeLastPhotoTaken);
```

Available options:
```objc
typedef NS_OPTIONS(NSInteger, CRMediaPickerControllerSourceType) {
    CRMediaPickerControllerSourceTypePhotoLibrary       = 1 << 0,
    CRMediaPickerControllerSourceTypeCamera             = 1 << 1,
    CRMediaPickerControllerSourceTypeSavedPhotosAlbum   = 1 << 2,
    CRMediaPickerControllerSourceTypeLastPhotoTaken     = 1 << 3
};
```

If `sourceType` property has multiple sources, it presents a UIActionSheet with the multiple (and available) options to choose. Otherwise, the single `sourceType` type is shown.

<img src="http://chroman.me/wp-content/uploads/2015/01/CRMediaPickerController3.png" width="621">

**More properties:**
```objc
@property (nonatomic, assign) NSTimeInterval videoMaximumDuration;
@property (nonatomic, assign) UIImagePickerControllerQualityType videoQualityType;
@property (nonatomic) BOOL allowsEditing;
@property (nonatomic, assign) UIImagePickerControllerCameraCaptureMode cameraCaptureMode;
@property (nonatomic, assign) UIImagePickerControllerCameraDevice cameraDevice;
@property (nonatomic, assign) UIImagePickerControllerCameraFlashMode cameraFlashMode;
@property (nonatomic, retain) UIView *cameraOverlayView;
@property (nonatomic, assign) CGAffineTransform cameraViewTransform;
@property (nonatomic, assign) BOOL showsCameraControls;
```

### Instance Methods

```objc
- (void)show;
- (void)dismiss;
- (BOOL)startVideoCapture;
- (void)stopVideoCapture;
- (void)takePicture;
```

### Delegate Methods

A `CRMediaPickerController` instance will return the selected media file back to `mediaPickerControllerDelegate`. The delegate contains methods very similar to the `UIImagePickerControllerDelegate`. Instead of returning one dictionary representing a single image the controller sends back the original `ALAsset` object which are easy to deal with.

* **Finished Picking Asset**

`- mediaPickerController:didFinishPickingAsset:error:`

Tells the delegate that the picking process is done and the media file is ready to use.

```objc
- (void)mediaPickerController:(CRMediaPickerController *)mediaPickerController didFinishPickingAsset:(ALAsset *)asset error:(NSError *)error;
```

Parameters:

<table>
  <tbody>
    <tr>
      <td>mediaPickerController</td>
      <td>The CRMediaPickerController object providing this information.</td>
    </tr>
    <tr>
      <td>asset</td>
      <td>The media file picked as ALAsset object.</td>
    </tr>
    <tr>
      <td>error</td>
      <td>An error object that describes why the picking process has failed.</td>
    </tr>
  </tbody>
</table>

* **Cancelled**

`- mediaPickerControllerDidCancel:`

Tells the delegate that the user cancelled the picking process.

```objc
- (void)mediaPickerControllerDidCancel:(CRMediaPickerController *)mediaPickerController;
```

Parameters:

<table>
  <tbody>
    <tr>
      <td>mediaPickerController</td>
      <td>The CRMediaPickerController object providing this information.</td>
    </tr>
  </tbody>
</table>

### CPDMediaPickerControllerDelegate example

```objc
#pragma mark - CPDMediaPickerControllerDelegate

- (void)mediaPickerController:(CRMediaPickerController *)mediaPickerController didFinishPickingAsset:(ALAsset *)asset error:(NSError *)error
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

- (void)mediaPickerControllerDidCancel:(CRMediaPickerController *)mediaPickerController
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}
```

*Note: Using `AssetsLibrary.framework` will prompt users to grant access to their photos.*

## Examples

**Photo only**
```objc
self.mediaPickerController = [[CRMediaPickerController alloc] init];
self.mediaPickerController.delegate = self;
self.mediaPickerController.mediaType = CRMediaPickerControllerMediaTypeImage;
self.mediaPickerController.sourceType = CRMediaPickerControllerSourceTypePhotoLibrary | CRMediaPickerControllerSourceTypeCamera;
[self.mediaPickerController show];
```

**Video Only**
```objc
self.mediaPickerController = [[CRMediaPickerController alloc] init];
self.mediaPickerController.delegate = self;
self.mediaPickerController.mediaType = CRMediaPickerControllerMediaTypeVideo;
self.mediaPickerController.sourceType = CRMediaPickerControllerSourceTypeCamera;
self.mediaPickerController.allowsEditing = NO;
self.mediaPickerController.videoQualityType = UIImagePickerControllerQualityTypeMedium;
self.mediaPickerController.videoMaximumDuration = 60.0f;
[self.mediaPickerController show];
```

**Both Photo or Video**
```objc
self.mediaPickerController = [[CRMediaPickerController alloc] init];
self.mediaPickerController.delegate = self;
self.mediaPickerController.mediaType = CRMediaPickerControllerMediaTypeImage | CRMediaPickerControllerMediaTypeVideo;
self.mediaPickerController.sourceType = CRMediaPickerControllerSourceTypeSavedPhotosAlbum;
[self.mediaPickerController show];
```

**Camera Overlay**
```objc
self.mediaPickerController = [[CRMediaPickerController alloc] init];
self.mediaPickerController.delegate = self;
self.mediaPickerController.mediaType = CRMediaPickerControllerMediaTypeImage;
self.mediaPickerController.sourceType = CRMediaPickerControllerSourceTypeCamera;
self.mediaPickerController.allowsEditing = NO;
    
self.mediaPickerController.showsCameraControls = NO;
[[NSBundle mainBundle] loadNibNamed:@"OverlayView" owner:self options:nil];
self.mediaPickerController.cameraOverlayView = self.overlayView;
self.overlayView = nil;
    
[self.mediaPickerController show];
```

**Video with specific properties**
```objc
self.mediaPickerController = [[CRMediaPickerController alloc] init];
self.mediaPickerController.delegate = self;
self.mediaPickerController.mediaType = CRMediaPickerControllerMediaTypeVideo;
self.mediaPickerController.sourceType = CRMediaPickerControllerSourceTypePhotoLibrary | CRMediaPickerControllerSourceTypeCamera;
self.mediaPickerController.allowsEditing = NO;
self.mediaPickerController.videoQualityType = UIImagePickerControllerQualityTypeMedium;
self.mediaPickerController.videoMaximumDuration = 60.0f;
[self.mediaPickerController show];
```

## Demo
See **Example** Xcode project for example usage.

## Requirements
* iOS 7.0 or higher, ARC is must.
* AssetsLibrary.Framework
* AVFoundation.Framework

## TODO
* ~~Improve API~~
* iPad support
* Multiple selection?
* Image cropping?

## Contributing
Anyone who would like to contribute to the project is more than welcome.

* Fork this repo
* Make your changes
* Submit a pull request

## License
`CRMediaPickerController` is released under the MIT license. See
[LICENSE](https://github.com/chroman/CRMediaPickerController/blob/master/LICENSE).

Contact
----------

Christian Roman
  
[http://chroman.me][1]

[chroman16@gmail.com][2]

[@chroman][3] 

  [1]: http://chroman.me
  [2]: mailto:chroman16@gmail.com
  [3]: http://twitter.com/chroman