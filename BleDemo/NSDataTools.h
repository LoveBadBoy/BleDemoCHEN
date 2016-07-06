//
//  NSDataTools.h
//  BleDemo
//
//  Created by FredChen on 16/6/23.
//  Copyright © 2016年 liuyanwei. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDataTools : NSObject

+ (instancetype)shareDataTools;

///// NSData－> NSString
//- (NSString *)getStringFromData:(NSData *)data;
//
///// NSString－>NSData
//- (NSData *)getDataFromString:(NSString *)string;
//
///// NSData -> Byte数组
//- (Byte *)getByteFromDate:(NSData *)data;
//
///// Byte数组－> NSData
//- (NSData *)getDataFromByte:(Byte *)byte;
//
/// 16进制字符串－> NSData
//- (NSMutableData *)getDataFrom16TypeString:(NSString *)string;
//
//// 十六进制转换为普通字符串的
//- (NSString *)stringFromHexString:(NSString *)hexString;
//
//// 普通字符串转换为十六进制的
//- (NSString *)hexStringFromString:(NSString *)string;

// 整型 -> mutbledata
- (NSMutableData *)getMutbleDataNumFromInteger:(NSInteger)integer;

// 整型 -> SpecialMutbledata
- (NSMutableData *)getSpecialMutbleDataNumFromInteger:(NSInteger)integer;

// mutbledata -> 整型
- (NSInteger)getIntegerFromMutbleDataNum:(NSMutableData *)mutbleDataNum withRange:(NSRange)range;

@end
