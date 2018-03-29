//
//  ViewController.m
//  PhotoDemo2
//
//  Created by TP on 2017/4/28.
//  Copyright © 2017年 TP. All rights reserved.
//

#import "ViewController.h"
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import "TDRPng.h"

//定义一个全局变量的相册名字
static NSString *kPhotoAssetCollectionName = @"天地融相册";
static NSString *kTDRTitle = @"天地融科技";

static NSString *kTDROriginalImagePath = @"TDROriginalImage.png";
static NSString *kTDRChangedImagePath = @"TDRChangedImage.png";
static NSString *kTDRGetImagePath = @"TDRGetImage.png";

#define IOS_VERSION_9 (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_8_x_Max)?(YES):(NO)

@interface ViewController () <AVCaptureMetadataOutputObjectsDelegate>
@property (strong, nonatomic) IBOutlet UILabel *resultLabel;
@property (strong, nonatomic) IBOutlet UIButton *getInfoButton;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self performSelector:@selector(requestAuthorization) withObject:nil afterDelay:0.5];
}

- (void)requestAuthorization
{
    if (IOS_VERSION_9)
    {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusAuthorized)
            {
                NSLog(@"已获取权限");
                self.getInfoButton.enabled = YES;
            }
            else
            {
                NSLog(@"未获取权限");
                self.getInfoButton.enabled = NO;
            }
        }];
    }
    else
    {
        if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusNotDetermined)
        {
            ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
            [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                if (*stop)
                {
                    NSLog(@"usingBlock.");
                    return;
                }
                NSLog(@"over.");
                *stop = YES;
            } failureBlock:^(NSError *error) {
                NSLog(@"failureBlock.");
            }];
        }
    }
}

//获取相簿
-(PHAssetCollection *)createAssetCollection
{
    //判断是否已存在
    PHFetchResult *assetCollections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection * assetCollection in assetCollections)
    {
        if ([assetCollection.localizedTitle isEqualToString:kPhotoAssetCollectionName])
        {
            //说明已经有哪对象了 删除相册中已有的照片
            PHFetchResult *assetResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:[PHFetchOptions new]];
            [assetResult enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    //                    //获取相册的最后一张照片
                    //                    if (idx == [assetResult count] - 1) {
                    //                        [PHAssetChangeRequest deleteAssets:@[obj]];
                    //                    }
                    [PHAssetChangeRequest deleteAssets:@[obj]];
                } completionHandler:^(BOOL success, NSError *error) {
                    NSLog(@"Error: %@", error);
                }];
            }];
            return assetCollection;
        }
    }
    
    //创建新的相簿
    __block NSString *assetCollectionLocalIdentifier = nil;
    NSError *error = nil;
    //同步方法
    [[PHPhotoLibrary sharedPhotoLibrary]performChangesAndWait:^{
        // 创建相簿的请求
        assetCollectionLocalIdentifier = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:kPhotoAssetCollectionName].placeholderForCreatedAssetCollection.localIdentifier;
    } error:&error];
    if (error)
    {
        return nil;
    }
    return [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[assetCollectionLocalIdentifier] options:nil].lastObject;
}

/**
 *  遍历相簿中的所有图片
 *  @param assetCollection 相簿
 *  @param original        是否要原图
 */
- (void)enumerateAssetsInAssetCollection:(PHAssetCollection *)assetCollection original:(BOOL)original
{
    NSLog(@"相簿名:%@", assetCollection.localizedTitle);
    if ([assetCollection.localizedTitle isEqualToString:kPhotoAssetCollectionName])
    {
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        // 同步获得图片, 只会返回1张图片
        options.synchronous = YES;
        // 获得某个相簿中的所有PHAsset对象
        PHFetchResult<PHAsset *> *assets = [PHAsset fetchAssetsInAssetCollection:assetCollection options:nil];
        for (PHAsset *asset in assets)
        {
            // 是否要原图
            CGSize size = original ? CGSizeMake(asset.pixelWidth, asset.pixelHeight) : CGSizeZero;
            
            // 从asset中获得图片
            __block NSString *resultQR = [NSString string];
            [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                NSLog(@"result: %@, info: %@", result, info);
//                resultQR = [self scanQRCode:result];
                resultQR = [self getInfoFromImage:result];
            }];
            self.resultLabel.text = resultQR;
        }
    }
}

- (NSString *)scanQRCode:(UIImage *)image
{
    //初始化CIDetector,选择类型为CIDetectorTypeQRCode，自动解析二维码类型的数据
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:nil];
    CIImage *ciImage = [CIImage imageWithCGImage:[image CGImage]];//UIImage转CIImage
    NSArray *arr = [detector featuresInImage:ciImage];
    if (arr.count>0)
    {
        CIQRCodeFeature *feature = arr[0];
        return feature.messageString;
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:nil message:@"未发现二维码" delegate:self cancelButtonTitle:@"确定" otherButtonTitles: nil] show];
    }
    return nil;
}

//获取原图
- (void)getOriginalImages
{
    // 获得所有的自定义相簿
    PHFetchResult<PHAssetCollection *> *assetCollections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    // 遍历所有的自定义相簿
    for (PHAssetCollection *assetCollection in assetCollections) {
        [self enumerateAssetsInAssetCollection:assetCollection original:YES];
    }
    
    // 获得相机胶卷
    PHAssetCollection *cameraRoll = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil].lastObject;
    // 遍历相机胶卷,获取大图
    [self enumerateAssetsInAssetCollection:cameraRoll original:YES];
}

- (NSString *)getInfoFromImage:(UIImage *)image
{
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *getImagePath = [documentPath stringByAppendingPathComponent:kTDRChangedImagePath];
    NSData *imageData = UIImagePNGRepresentation(image);
    [imageData writeToFile:getImagePath atomically:NO];
    NSMutableData* getMutableData = [NSMutableData data];
    BOOL result = [TDRPng TDR_ReadData:getImagePath data:getMutableData];
    if (!result)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"获取数据失败" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
        [alert show];
        return nil;
    }
    return [[NSString alloc] initWithData:getMutableData encoding:NSUTF8StringEncoding];
}

- (IBAction)getInfoAction:(UIButton *)sender
{
    //获取相册
    [self getOriginalImages];
}






















@end
