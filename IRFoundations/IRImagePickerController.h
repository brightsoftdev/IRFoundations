//
//  IRCameraViewController.h
//  IRFoundations
//
//  Created by Evadne Wu on 6/8/11.
//  Copyright 2011 Iridia Productions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <objc/runtime.h>

@interface IRImagePickerController : UIImagePickerController

typedef void (^IRImagePickerCallback) (NSURL *selectedAssetURI, ALAsset *representedAsset);

@property (nonatomic, readonly, copy) IRImagePickerCallback callbackBlock;

//	Conveniences
+ (IRImagePickerController *) savedImagePickerWithCompletionBlock:(void(^)(NSURL *selectedAssetURI, ALAsset *representedAsset))aCallbackBlockOrNil;
+ (IRImagePickerController *) photoLibraryPickerWithCompletionBlock:(void(^)(NSURL *selectedAssetURI, ALAsset *representedAsset))aCallbackBlockOrNil;
+ (IRImagePickerController *) cameraCapturePickerWithCompletionBlock:(void(^)(NSURL *selectedAssetURI, ALAsset *representedAsset))aCallbackBlockOrNil;
+ (IRImagePickerController *) cameraImageCapturePickerWithCompletionBlock:(void(^)(NSURL *selectedAssetURI, ALAsset *representedAsset))aCallbackBlockOrNil;
+ (IRImagePickerController *) cameraVideoCapturePickerWithCompletionBlock:(void(^)(NSURL *selectedAssetURI, ALAsset *representedAsset))aCallbackBlockOrNil;

+ (IRImagePickerController *) pickerWithSourceType:(UIImagePickerControllerSourceType)sourceType mediaTypes:(NSArray *)mediaTypes completionBlock:(void(^)(NSURL *selectedAssetURI, ALAsset *representedAsset))aCallbackBlockOrNil;

@property (nonatomic, readwrite, assign) BOOL takesPictureOnVolumeUpKeypress;

@end