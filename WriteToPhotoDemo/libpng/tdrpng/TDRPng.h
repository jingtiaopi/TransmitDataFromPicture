//
//  TDRPng.h
//  tdrpng
//
//  Created by TP on 2017/5/4.
//  Copyright © 2017年 TP. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDRPng : NSObject


/**
 写照片数据

 @param pngFilePath 照片路径
 @param dataString 写入的数据
 @param outPath 写完成后照片的输出路径（与输入的照片路径不能相同）
 @return 是否成功
 */
+ (BOOL)TDR_WriteData:(NSString *)pngFilePath  dataString:(NSString *)dataString outPath:(NSString *)outPath;


/**
 读取照片数据

 @param pngFilePath 照片路径
 @param data 数据
 @return 是否读取成功
 */
+ (BOOL)TDR_ReadData:(NSString *)pngFilePath data:(NSMutableData *)data;

@end
