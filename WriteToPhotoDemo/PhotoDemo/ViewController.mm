//
//  ViewController.m
//  PhotoDemo
//
//  Created by TP on 2017/4/27.
//  Copyright © 2017年 TP. All rights reserved.
//

#import "ViewController.h"
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
//#include "imageTest.h"
//#import "TDRPng.h"


//定义一个全局变量的相册名字
static NSString *kPhotoAssetCollectionName = @"天地融相册";
static NSString *kTDRTitle = @"天地融科技";

static NSString *kTDROriginalImagePath = @"TDROriginalImage.png";
static NSString *kTDRChangedImagePath = @"TDRChangedImage.png";
static NSString *kTDRGetImagePath = @"TDRGetImage.png";

#define IOS_VERSION_9 (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_8_x_Max)?(YES):(NO)
#define IOS_VERSION_8 (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1 && NSFoundationVersionNumber < NSFoundationVersionNumber_iOS_9_0)?(YES):(NO)

@interface ViewController () <AVCaptureMetadataOutputObjectsDelegate>
@property (strong, nonatomic) IBOutlet UIButton *saveButton;
@property (strong, nonatomic) IBOutlet UIButton *getImageButton;
@property (strong, nonatomic) IBOutlet UILabel *radomLabel;
@property (strong, nonatomic) IBOutlet UILabel *resultLabel;

//@property (nonatomic, strong) AVCaptureDevice *device;
//@property (nonatomic, strong) AVCaptureSession *session;

@end

@implementation ViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.radomLabel.text = [NSString stringWithFormat:@"%d", arc4random() % 100000000];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
    [self performSelector:@selector(requestAuthorization) withObject:nil afterDelay:0.5];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    self.radomLabel.text = [NSString stringWithFormat:@"%d", arc4random() % 100000000];
    self.resultLabel.text = @"";
}

- (void)requestAuthorization
{
    if (IOS_VERSION_9)
    {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusAuthorized)
            {
                NSLog(@"已获取权限");
                self.saveButton.enabled = YES;
                self.getImageButton.enabled = YES;
            }
            else
            {
                NSLog(@"未获取权限");
                self.saveButton.enabled = NO;
                self.getImageButton.enabled = NO;
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
                    return;
                }
                *stop = YES;
            } failureBlock:^(NSError *error) {
                
            }];
        }
        if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized)
        {
            NSLog(@"已获取权限");
            self.saveButton.enabled = YES;
            self.getImageButton.enabled = YES;
        }
        else
        {
            NSLog(@"未获取权限");
            self.saveButton.enabled = NO;
            self.getImageButton.enabled = NO;
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
            //说明已经有那对象了 删除相册中已有的照片
//            PHFetchResult *assetResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:[PHFetchOptions new]];
//            [assetResult enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
////                    //获取相册的最后一张照片
////                    if (idx == [assetResult count] - 1) {
////                        [PHAssetChangeRequest deleteAssets:@[obj]];
////                    }
//                    [PHAssetChangeRequest deleteAssets:@[obj]];
//                } completionHandler:^(BOOL success, NSError *error) {
//                    NSLog(@"Error: %@", error);
//                }];
//            }];
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

//写入相册（基本功能）
- (void)loadImageFinishedBased:(UIImage *)image
{
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        //写入图片到相册
        [PHAssetChangeRequest creationRequestForAssetFromImage:image];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        NSLog(@"success = %d, error = %@", success, error);
        
    }];
}

- (void)loadImageFinishedAdvanced:(UIImage *)image
{
    __block  NSString *assetLocalIdentifier;
    [[PHPhotoLibrary sharedPhotoLibrary]performChanges:^{
        //1.保存图片到相机胶卷中----创建图片的请求
        PHAssetChangeRequest *assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        assetLocalIdentifier = assetChangeRequest.placeholderForCreatedAsset.localIdentifier;
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if(!success){
            NSLog(@"保存图片失败----(创建图片的请求)");
            return ;
        }
        // 2.获得相簿
        PHAssetCollection *createdAssetCollection = [self createAssetCollection];
        if (createdAssetCollection == nil)
        {
            NSLog(@"保存图片失败----(创建相簿失败!)");
            return;
        }
        // 3.将刚刚添加到"相机胶卷"中的图片到"自己创建相簿"中
        [[PHPhotoLibrary sharedPhotoLibrary]performChanges:^{
            //获得图片
            PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetLocalIdentifier] options:nil].lastObject;
            //添加图片到相簿中的请求
            PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:createdAssetCollection];
            // 添加图片到相簿
            [request addAssets:@[asset]];
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            if(success){
                NSLog(@"保存图片到创建的相簿成功");
                dispatch_async(dispatch_get_main_queue(), ^{
                   self.resultLabel.text = @"成功保存图片到相册";
                });
            }else{
                NSLog(@"保存图片到创建的相簿失败");
            }
        }];
    }];
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

//获取缩略图
- (void)getThumbnailImages
{
    // 获得所有的自定义相簿
    PHFetchResult<PHAssetCollection *> *assetCollections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    // 遍历所有的自定义相簿
    for (PHAssetCollection *assetCollection in assetCollections) {
        [self enumerateAssetsInAssetCollection:assetCollection original:NO];
    }
    // 获得相机胶卷
    PHAssetCollection *cameraRoll = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil].lastObject;
    [self enumerateAssetsInAssetCollection:cameraRoll original:NO];
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
/*
        //遍历相册中所有图片
        for (PHAsset *asset in assets)
        {
            // 是否要原图
            CGSize size = original ? CGSizeMake(asset.pixelWidth, asset.pixelHeight) : CGSizeZero;
            
            // 从asset中获得图片
            __block NSString *resultQR = [NSString string];
            [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                NSLog(@"result: %@, info: %@", result, info);
                resultQR = [self scanQRCode:result];
//                resultQR = [self getInfoFromImage:result];
//                NSData *imageData = UIImagePNGRepresentation(result);//UIImageJPEGRepresentation(result, 1.0);//UIImagePNGRepresentation(result);//[NSData dataWithContentsOfFile:info[@"PHImageFileURLKey"]];
//                NSLog(@"output ImageData: %@", imageData);
//                NSData *textData = [imageData subdataWithRange:NSMakeRange(imageData.length - 3, 3)];
//                NSLog(@"textData:%@",textData);
//                NSLog(@"text: %@", [[NSString alloc] initWithData:textData encoding:NSUTF8StringEncoding]);
            }];
//            self.resultLabel.text = resultQR;
        }
*/
        //仅读取最后一张图片的二维码
        PHAsset *asset = assets.lastObject;
        // 是否要原图
        CGSize size = original ? CGSizeMake(asset.pixelWidth, asset.pixelHeight) : CGSizeZero;
        
        // 从asset中获得图片
        __block NSString *resultQR = [NSString string];
        [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            NSLog(@"result: %@, info: %@", result, info);
            resultQR = [self scanQRCode:result];
        }];
        
        self.resultLabel.text = [NSString stringWithFormat:@"天地融相册总共%lu张照片\n结果是: %@", (unsigned long)assets.count, resultQR];
    }
}

//删除照片
- (void)deleteImage
{
    PHFetchResult *collectonResuts = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAny options:[PHFetchOptions new]];
    [collectonResuts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        PHAssetCollection *assetCollection = obj;
        if ([assetCollection.localizedTitle isEqualToString:kPhotoAssetCollectionName])
        {
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
        }
    }];
}

- (IBAction)saveAction:(id)sender
{
/* 创建二维码图片
 */
    //写入相册
    UIImage *saveImage = [self createQRCode];
    [self loadImageFinishedAdvanced:saveImage];
  
    
//往图片中写入数据
//    UIImage *originalImage = [UIImage imageNamed:@"Default@2x.png"];
//    NSData *imageData = UIImagePNGRepresentation(originalImage);
//    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
//    NSString *imageOriginalPath = [documentPath stringByAppendingPathComponent:kTDROriginalImagePath];
//    [imageData writeToFile:imageOriginalPath atomically:NO];
//    NSString *imageChangedPath = [documentPath stringByAppendingPathComponent:kTDRChangedImagePath];
//    BOOL result = [TDRPng TDR_WriteData:imageOriginalPath dataString:self.radomLabel.text outPath:imageChangedPath];
//    if (!result)
//    {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"写入数据失败" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
//        [alert show];
//        return;
//    }
//    UIImage *changedImage = [UIImage imageWithContentsOfFile:imageChangedPath];
//    NSData *tempChangedData = UIImagePNGRepresentation(changedImage);
//    [self loadImageFinishedAdvanced:changedImage];

    
    
    
    
//    NSError *error = nil;
//    [[NSFileManager defaultManager] removeItemAtPath:imageOriginalPath error:&error];
//    [[NSFileManager defaultManager] removeItemAtPath:imageChangedPath error:&error];
    //获取数据
//    NSMutableData *getMutableData = [NSMutableData data];
//    result = [TDRPng TDR_ReadData:imageChangedPath data:getMutableData];
//    if (!result)
//    {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"获取数据失败" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
//        [alert show];
//        return;
//    }
    
    
    //NSData转换为UIImage
//    NSData *imageData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Default@2x" ofType:@"png"]];
//    UIImage *saveImage = [UIImage imageNamed:@"1.png"];//@"Default@2x.png"];
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"7" ofType:@"jpeg"];
//    UIImage *tempImage = [UIImage imageNamed:@"7.jpeg"];
//    NSData *tempData = UIImageJPEGRepresentation(tempImage, 1);
//    NSString *newPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"image.jpeg"];
//    add_text_jpeg([path UTF8String], [newPath UTF8String]);
    
//    NSData *imageData = UIImageJPEGRepresentation(saveImage, 1.0);//UIImagePNGRepresentation(saveImage);
//    NSMutableData *imageMutableData = [NSMutableData dataWithData:imageData];
//    NSData *randomData = [self.radomLabel.text dataUsingEncoding:NSUTF8StringEncoding];
//    [imageMutableData appendData:randomData];
//    NSLog(@"imageMutableData: %@", imageMutableData);
//    UIImage *image = [UIImage imageWithData:imageMutableData];
    //UIImage转换为NSData
//    NSData *newImageData = [NSData dataWithContentsOfFile:newPath];
//    UIImage *newImage = [UIImage imageWithData:newImageData];
//    NSData *tempData = UIImagePNGRepresentation(saveImage);
//    NSLog(@"input ImageData: %@", tempData);
//    [self loadImageFinishedAdvanced:changedImage];
//    [self loadImageFinishedBased:saveImage];
}
- (IBAction)getAction:(id)sender
{
    //获取相册
    [self getOriginalImages];
}

//- (NSString *)getInfoFromImage:(UIImage *)image
//{
//    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
//    NSString *getImagePath = [documentPath stringByAppendingPathComponent:kTDRGetImagePath];
//    NSData *imageData = UIImagePNGRepresentation(image);
//    [imageData writeToFile:getImagePath atomically:NO];
//    NSMutableData* getMutableData = [NSMutableData data];
//    BOOL result = [TDRPng TDR_ReadData:getImagePath data:getMutableData];
//    if (!result)
//    {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"获取数据失败" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
//        [alert show];
//        return nil;
//    }
//    return [[NSString alloc] initWithData:getMutableData encoding:NSUTF8StringEncoding];
//}

- (NSString *)scanQRCode:(UIImage *)image
{
/*
    // Device 获取摄像头设备
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // Input 创建输入流
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    
    // Output 创建输出流
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    //设置代理，在主线程刷新
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    //设置二维码扫描区域（每一个取值0~1，以屏幕右上角为坐标原点）(y, x, height, width)
//    CGRect interestRect = CGRectMake(((CGRectGetHeight(self.view.frame) - kScanWidth) / 2 - 80.0) / kScreenHeight, ((kScreenWidth - kScanWidth) / 2 ) / kScreenWidth, kScanWidth / kScreenHeight , kScanWidth / kScreenWidth);
//    [output setRectOfInterest:interestRect];
    //    PrintInfo(@"rect: %@", NSStringFromCGRect(interestRect));
    // Session 初始化链接对象（会话对象）
    self.session = [[AVCaptureSession alloc] init];
    //高质量采集率
    [self.session setSessionPreset:AVCaptureSessionPresetHigh];
    //连接会话输入与输出
    if ([self.session canAddInput:input])
    {
        [self.session addInput:input];
    }
    if ([self.session canAddOutput:output])
    {
        [self.session addOutput:output];
    }
    //设置输出数据类型，需要将元数据输出添加到会话后，才能指定元数据类型，否则会报错
    //设置扫码支持的编码格式（如下设置条形码和二维码兼容）
    //设置扫码支持的编码格式(如下设置条形码和二维码兼容)
    NSMutableArray *metadataObjectTypes = [[NSMutableArray alloc] init];
    if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeQRCode])
    {
        [metadataObjectTypes addObject:AVMetadataObjectTypeQRCode];
    }
    if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeEAN13Code])
    {
        [metadataObjectTypes addObject:AVMetadataObjectTypeEAN13Code];
    }
    if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeEAN8Code])
    {
        [metadataObjectTypes addObject:AVMetadataObjectTypeEAN8Code];
    }
    if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeCode128Code])
    {
        [metadataObjectTypes addObject:AVMetadataObjectTypeCode128Code];
    }
    output.metadataObjectTypes = metadataObjectTypes;
    //添加扫描画面，实例化预览图层，传递session 是为了告诉图层将来显示什么内容
    AVCaptureVideoPreviewLayer *previewLayer =[AVCaptureVideoPreviewLayer layerWithSession:self.session];
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    previewLayer.frame = self.view.layer.bounds;
    //将图层插入当前视图
    [self.view.layer insertSublayer:previewLayer atIndex:0];
*/
    
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

//- (UIImageView *)createQRCode
//{
//    //二维码滤镜
//    CIFilter *filter=[CIFilter filterWithName:@"CIQRCodeGenerator"];
//    //恢复滤镜的默认属性
//    [filter setDefaults];
//    //将字符串转换成NSData
//    NSData *data=[self.radomLabel.text dataUsingEncoding:NSUTF8StringEncoding];
//    //通过KVO设置滤镜inputmessage数据
//    [filter setValue:data forKey:@"inputMessage"];
//    //获得滤镜输出的图像
//    CIImage *outputImage=[filter outputImage];
//    //将CIImage转换成UIImage,并放大显示
//    UIImageView *imageView = [[UIImageView alloc] init];
//    imageView.image = [self createNonInterpolatedUIImageFormCIImage:outputImage withSize:100.0];
//    //如果还想加上阴影，就在ImageView的Layer上使用下面代码添加阴影
//    imageView.layer.shadowOffset = CGSizeMake(0, 0.5);//设置阴影的偏移量
//    imageView.layer.shadowRadius=1;//设置阴影的半径
//    imageView.layer.shadowColor=[UIColor blackColor].CGColor;//设置阴影的颜色为黑色
//    imageView.layer.shadowOpacity=0.3;
//    return imageView;
//}

- (UIImage *)createQRCode
{
    //二维码滤镜
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    //恢复滤镜的默认属性
    [filter setDefaults];
    //将字符串转换成NSData
    NSData *data = [self.radomLabel.text dataUsingEncoding:NSUTF8StringEncoding];
    //通过KVO设置滤镜inputmessage数据
    [filter setValue:data forKey:@"inputMessage"];
    //获得滤镜输出的图像
    CIImage *outputImage = [filter outputImage];
    //将CIImage转换成UIImage,并放大显示
//    UIImageView *imageView = [[UIImageView alloc] init];
    return [self createNonInterpolatedUIImageFormCIImage:outputImage withSize:CGRectGetWidth(self.view.frame) - 20.0];
//    imageView.image = [self createNonInterpolatedUIImageFormCIImage:outputImage withSize:100.0];
//    //如果还想加上阴影，就在ImageView的Layer上使用下面代码添加阴影
//    imageView.layer.shadowOffset = CGSizeMake(0, 0.5);//设置阴影的偏移量
//    imageView.layer.shadowRadius=1;//设置阴影的半径
//    imageView.layer.shadowColor=[UIColor blackColor].CGColor;//设置阴影的颜色为黑色
//    imageView.layer.shadowOpacity=0.3;
//    return imageView;
}

//改变二维码大小
- (UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image withSize:(CGFloat)size
{
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    // 创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    // 保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    UIImage *resultImage = [UIImage imageWithCGImage:scaledImage];
    return [self imageToAddText:resultImage withText:kTDRTitle];
}

//合成文字和二维码 UIImage
- (UIImage *)imageToAddText:(UIImage *)img withText:(NSString *)text
{
    //1.获取上下文
    CGFloat spaceY = 40.0;
    UIGraphicsBeginImageContext(CGSizeMake(img.size.width, img.size.height + spaceY * 2));
    //2.绘制图片
    [img drawInRect:CGRectMake(0, spaceY, img.size.width, img.size.height + spaceY)];
    //3.绘制文字
    CGRect rect = CGRectMake(0, 5, img.size.width, spaceY - 5.0);
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    style.alignment = NSTextAlignmentCenter;
    //文字的属性
    NSDictionary *dic = @{NSFontAttributeName:[UIFont boldSystemFontOfSize:30.0],NSParagraphStyleAttributeName:style,NSForegroundColorAttributeName:[UIColor blackColor]};
    //将文字绘制上去
    [text drawInRect:rect withAttributes:dic];
    //4.获取绘制到得图片
    UIImage *watermarkImg = UIGraphicsGetImageFromCurrentImageContext();
    //5.结束图片的绘制
    UIGraphicsEndImageContext();
    return watermarkImg;
}

//#pragma mark - AVCaptureMetadataOutputObjectsDelegate
//- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
//{
//    if ([metadataObjects count] > 0)
//    {
//        //停止扫描
//        [self.session stopRunning];
//        AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects objectAtIndex:0];
//        NSString *stringValue = metadataObject.stringValue;
//        NSLog(@"扫描结果: %@", stringValue);
//        self.resultLabel.text = stringValue;
//    }
//}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

@end
