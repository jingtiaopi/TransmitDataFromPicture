//
//  TDRPng.m
//  tdrpng
//
//  Created by TP on 2017/5/4.
//  Copyright © 2017年 TP. All rights reserved.
//

#import "TDRPng.h"
#include "png.h"

#define PNG_DEBUG

@implementation TDRPng

+(BOOL)TDR_WriteData:(NSString*)pngFilePath  dataString:(NSString*)dataString outPath:(NSString*)outPath
{
    static png_FILE_p fpin;
    static png_FILE_p fpout;
    //输入文件名
    char *inname = (char*)[pngFilePath UTF8String];//"/home/mingming/graph/1.png";
    char *outname = (char*)[outPath UTF8String];
    png_structp read_ptr;
    png_infop read_info_ptr, end_info_ptr;
    //写
    png_structp write_ptr;
    png_infop write_info_ptr,write_end_info_ptr;
    //
    png_bytep row_buf;
    png_uint_32 y;
    int num_pass, pass;
    png_uint_32 width, height;//宽度，高度
    int bit_depth, color_type;//位深，颜色类型
    int interlace_type, compression_type, filter_type;//扫描方式，压缩方式，滤波方式
    //读
    row_buf = NULL;
    //打开读文件
    if ((fpin = fopen(inname, "rb")) == NULL)
    {
        fprintf(stderr,"Could not find input file %s\n", inname);
        return (1);
    }
    //打开写文件
    if ((fpout = fopen(outname, "wb+")) == NULL)
    {
        printf("Could not open output file %s\n", outname);
        fclose(fpin);
        return (1);
    }
    //我们这里不处理未知的块unknown chunk
    //初始化1
    read_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    write_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    read_info_ptr = png_create_info_struct(read_ptr);
    end_info_ptr = png_create_info_struct(read_ptr);
    write_info_ptr = png_create_info_struct(write_ptr);
    write_end_info_ptr = png_create_info_struct(write_ptr);
    //初始化2
    png_init_io(read_ptr, fpin);
    png_init_io(write_ptr, fpout);
    //读文件有high level(高层）和low level两种，我们选择从底层具体信息中读取。
    //这里我们读取所有可选。
    png_read_info(read_ptr, read_info_ptr);
    //（1）IHDR
    //读取图像宽度(width)，高度(height)，位深(bit_depth)，颜色类型(color_type)，压缩方法(compression_type)
    //滤波器方法(filter_type),隔行扫描方式(interlace_type)
    if (png_get_IHDR(read_ptr, read_info_ptr, &width, &height, &bit_depth,
                     &color_type, &interlace_type, &compression_type, &filter_type))
    {
        //我们采用默认扫描方式
        png_set_IHDR(write_ptr, write_info_ptr, width, height, bit_depth,
                     color_type, PNG_INTERLACE_NONE, compression_type, filter_type);
    }
    //（2）cHRM
    //读取白色度信息  白/红/绿/蓝 点的x,y坐标，这里采用整形，不采用浮点数
    png_fixed_point white_x, white_y, red_x, red_y, green_x, green_y, blue_x,blue_y;
    
    if (png_get_cHRM_fixed(read_ptr, read_info_ptr, &white_x, &white_y,
                           &red_x, &red_y, &green_x, &green_y, &blue_x, &blue_y))
    {
        png_set_cHRM_fixed(write_ptr, write_info_ptr, white_x, white_y, red_x,
                           red_y, green_x, green_y, blue_x, blue_y);
    }
    //（3）gAMA
    png_fixed_point gamma;
    
    if (png_get_gAMA_fixed(read_ptr, read_info_ptr, &gamma))
        png_set_gAMA_fixed(write_ptr, write_info_ptr, gamma);
    //（4）iCCP
    png_charp name;
    png_bytep profile;
    png_uint_32 proflen;
    
    if (png_get_iCCP(read_ptr, read_info_ptr, &name, &compression_type,
                     &profile, &proflen))
    {
        png_set_iCCP(write_ptr, write_info_ptr, name, compression_type,
                     profile, proflen);
    }
    //(5)sRGB
    int intent;
    if (png_get_sRGB(read_ptr, read_info_ptr, &intent))
        png_set_sRGB(write_ptr, write_info_ptr, intent);
    //(7)PLTE
    png_colorp palette;
    int num_palette;
    
    if (png_get_PLTE(read_ptr, read_info_ptr, &palette, &num_palette))
        png_set_PLTE(write_ptr, write_info_ptr, palette, num_palette);
    //(8)bKGD
    png_color_16p background;
    
    if (png_get_bKGD(read_ptr, read_info_ptr, &background))
    {
        png_set_bKGD(write_ptr, write_info_ptr, background);
    }
    //(9)hist
    
    png_uint_16p hist;
    
    if (png_get_hIST(read_ptr, read_info_ptr, &hist))
        png_set_hIST(write_ptr, write_info_ptr, hist);
    //(10)oFFs
    png_int_32 offset_x, offset_y;
    int unit_type;
    
    if (png_get_oFFs(read_ptr, read_info_ptr, &offset_x, &offset_y,
                     &unit_type))
    {
        png_set_oFFs(write_ptr, write_info_ptr, offset_x, offset_y, unit_type);
    }
    //(11)pCAL
    png_charp purpose, units;
    png_charpp params;
    png_int_32 X0, X1;
    int type, nparams;
    
    if (png_get_pCAL(read_ptr, read_info_ptr, &purpose, &X0, &X1, &type,
                     &nparams, &units, &params))
    {
        png_set_pCAL(write_ptr, write_info_ptr, purpose, X0, X1, type,
                     nparams, units, params);
    }
    //(12)pHYs
    
    png_uint_32 res_x, res_y;
    
    if (png_get_pHYs(read_ptr, read_info_ptr, &res_x, &res_y, &unit_type))
        png_set_pHYs(write_ptr, write_info_ptr, res_x, res_y, unit_type);
    //(13)sBIT
    png_color_8p sig_bit;
    
    if (png_get_sBIT(read_ptr, read_info_ptr, &sig_bit))
        png_set_sBIT(write_ptr, write_info_ptr, sig_bit);
    //（14）sCAL
    int unit;
    png_charp scal_width, scal_height;
    
    if (png_get_sCAL_s(read_ptr, read_info_ptr, &unit, &scal_width,
                       &scal_height))
    {
        png_set_sCAL_s(write_ptr, write_info_ptr, unit, scal_width,
                       scal_height);
    }
    //(15)iTXt
    png_textp text_ptr;
    int num_text;
    
    //    if (png_get_text(read_ptr, read_info_ptr, &text_ptr, &num_text) > 0)
    //    {
    //        png_set_text(write_ptr, write_info_ptr, text_ptr, num_text);
    //    }
    {
        png_text text_ptr[1];
        
        text_ptr[0].key = "TDR";
        text_ptr[0].text = [dataString UTF8String];
        text_ptr[0].text_length = [dataString length];
        text_ptr[0].compression = PNG_TEXT_COMPRESSION_NONE;
//        text_ptr[1].key = "Author";
//        text_ptr[1].text = "Leonardo DaVinci";
//        text_ptr[1].compression = PNG_TEXT_COMPRESSION_NONE;
//        text_ptr[2].key = "Description";
//        text_ptr[2].text = "<long text>";
//        text_ptr[2].compression = PNG_TEXT_COMPRESSION_zTXt;
#ifdef PNG_iTXt_SUPPORTED
        text_ptr[0].lang = NULL;
//        text_ptr[1].lang = NULL;
//        text_ptr[2].lang = NULL;
#endif
        png_set_text(write_ptr, write_info_ptr, text_ptr,1);
    }
    //(16)tIME,这里我们不支持RFC1123
    png_timep mod_time;
    
    if (png_get_tIME(read_ptr, read_info_ptr, &mod_time))
    {
        png_set_tIME(write_ptr, write_info_ptr, mod_time);
    }
    //(17)tRNS
    png_bytep trans_alpha;
    int num_trans;
    png_color_16p trans_color;
    
    if (png_get_tRNS(read_ptr, read_info_ptr, &trans_alpha, &num_trans,
                     &trans_color))
    {
        int sample_max = (1 << bit_depth);
        /* libpng doesn't reject a tRNS chunk with out-of-range samples */
        if (!((color_type == PNG_COLOR_TYPE_GRAY &&
               (int)trans_color->gray > sample_max) ||
              (color_type == PNG_COLOR_TYPE_RGB &&
               ((int)trans_color->red > sample_max ||
                (int)trans_color->green > sample_max ||
                (int)trans_color->blue > sample_max))))
            png_set_tRNS(write_ptr, write_info_ptr, trans_alpha, num_trans,
                         trans_color);
    }
    
    //写进新的png文件中
    png_write_info(write_ptr, write_info_ptr);
    //读真正的图像数据
    num_pass = 1;
    for (pass = 0; pass < num_pass; pass++)
    {
        for (y = 0; y < height; y++)
        {
            //分配内存
            row_buf = (png_bytep)png_malloc(read_ptr,
                                            png_get_rowbytes(read_ptr, read_info_ptr));
            png_read_rows(read_ptr, (png_bytepp)&row_buf, NULL, 1);
            png_write_rows(write_ptr, (png_bytepp)&row_buf, 1);
            png_free(read_ptr, row_buf);
            row_buf = NULL;
        }
    }
    //结束
    png_read_end(read_ptr, end_info_ptr);
    //
    //tTXt
    if (png_get_text(read_ptr, end_info_ptr, &text_ptr, &num_text) > 0)
    {
        png_set_text(write_ptr, write_end_info_ptr, text_ptr, num_text);
    }
    //tIME
    if (png_get_tIME(read_ptr, end_info_ptr, &mod_time))
    {
        png_set_tIME(write_ptr, write_end_info_ptr, mod_time);
    }
    //
    png_write_end(write_ptr, write_end_info_ptr);
    //回收
    png_free(read_ptr, row_buf);
    row_buf = NULL;
    png_destroy_read_struct(&read_ptr, &read_info_ptr, &end_info_ptr);
    png_destroy_info_struct(write_ptr, &write_end_info_ptr);
    png_destroy_write_struct(&write_ptr, &write_info_ptr);
    //
    fclose(fpin);
    fclose(fpout);
    return YES;
}

+(BOOL)TDR_ReadData:(NSString*)pngFilePath data:(NSMutableData*)data
{
    png_structp png_ptr;
    png_infop info_ptr;
    unsigned int sig_read = 0;
    png_uint_32 width, height;
    int bit_depth, color_type, interlace_type;
    FILE *fp;
    
    if ((fp = fopen((char*)[pngFilePath UTF8String], "rb")) == NULL)
        return NO;
    
    /* Create and initialize the png_struct with the desired error handler
     * functions.  If you want to use the default stderr and longjump method,
     * you can supply NULL for the last three parameters.  We also supply the
     * the compiler header file version, so that we know if the application
     * was compiled with a compatible version of the library.  REQUIRED
     */
    png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING,
                                     NULL, NULL, NULL);
    
    if (png_ptr == NULL)
    {
        fclose(fp);
        return NO;
    }
    
    /* Allocate/initialize the memory for image information.  REQUIRED. */
    info_ptr = png_create_info_struct(png_ptr);
    if (info_ptr == NULL)
    {
        fclose(fp);
        png_destroy_read_struct(&png_ptr, NULL, NULL);
        return NO;
    }
    
    /* Set error handling if you are using the setjmp/longjmp method (this is
     * the normal method of doing things with libpng).  REQUIRED unless you
     * set up your own error handlers in the png_create_read_struct() earlier.
     */
    
    if (setjmp(png_jmpbuf(png_ptr)))
    {
        /* Free all of the memory associated with the png_ptr and info_ptr */
        png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
        fclose(fp);
        /* If we get here, we had a problem reading the file */
        return NO;
    }
    

    png_init_io(png_ptr, fp);
    
    
    /* If we have already read some of the signature */
    //png_set_sig_bytes(png_ptr, sig_read);

    /* OK, you're doing it the hard way, with the lower-level functions */
    
    /* The call to png_read_info() gives us all of the information from the
     * PNG file before the first IDAT (image data chunk).  REQUIRED
     */
    png_read_info(png_ptr, info_ptr);
    
    png_textp text_ptr;
    int num_text;
    
    if (png_get_text(png_ptr, info_ptr, &text_ptr, &num_text) > 0)
    {
        if(data && num_text) {
            [data setData:[NSData dataWithBytes:text_ptr[0].text length:text_ptr[0].text_length]];
        }
    }
    png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
    
    /* close the file */
    fclose(fp);
    return YES;
}

@end
