//
//  NSDataTools.m
//  BleDemo
//
//  Created by FredChen on 16/6/23.
//  Copyright © 2016年 liuyanwei. All rights reserved.
//

#import "NSDataTools.h"

@implementation NSDataTools

+ (instancetype)shareDataTools{
    
    static NSDataTools *dataTools = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!dataTools) {
            dataTools = [NSDataTools new];
        }
    });
    return dataTools;
}

/// NSData－> NSString
- (NSString *)getStringFromData:(NSData *)data
{
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return string;
}

/// NSString－>NSData
- (NSData *)getDataFromString:(NSString *)string
{
    NSData *data = [string dataUsingEncoding: NSUTF8StringEncoding];
    return data;
}

/// NSData -> Byte数组
- (Byte *)getByteFromDate:(NSData *)data
{
    Byte *byte = (Byte *)[data bytes];
//    for(int i=0;i<[data length];i++)
//        
//        printf("data = %d\n",data[i]);
    return byte;
}

/// Byte数组－> NSData
- (NSData *)getDataFromByte:(Byte *)byte
{
    NSData *data = [[NSData alloc] initWithBytes:byte length:sizeof(byte)/sizeof(Byte)];
    return data;
}

/// 16进制字符串－> NSData
- (NSMutableData *)getDataFrom16TypeString:(NSString *)string
{
    NSString *hexString=[[string uppercaseString] stringByReplacingOccurrencesOfString:@" " withString:@""];
    if ([hexString length]%2!=0) {
        return nil;
    }
    Byte tempbyt[1]={0};
    NSMutableData* bytes=[NSMutableData data];
    for(int i=0;i<[hexString length];i++)
    {
        unichar hex_char1 = [hexString characterAtIndex:i]; ////两位16进制数中的第一位(高位*16)
        int int_ch1;
        if(hex_char1 >= '0' && hex_char1 <='9')
            int_ch1 = (hex_char1-48)*16;   //// 0 的Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch1 = (hex_char1-55)*16; //// A 的Ascll - 65
        else
            return nil;
        i++;
        
        unichar hex_char2 = [hexString characterAtIndex:i]; ///两位16进制数中的第二位(低位)
        int int_ch2;
        if(hex_char2 >= '0' && hex_char2 <='9')
            int_ch2 = (hex_char2-48); //// 0 的Ascll - 48
        else if(hex_char2 >= 'A' && hex_char2 <='F')
            int_ch2 = hex_char2-55; //// A 的Ascll - 65
        else
            return nil;
        
        tempbyt[0] = int_ch1+int_ch2;  ///将转化后的数放入Byte数组里
        [bytes appendBytes:tempbyt length:1];
    }
    
    NSLog(@"------NSMutableData------%@",bytes);
    return bytes;
}


// 十六进制转换为普通字符串的
- (NSString *)stringFromHexString:(NSString *)hexString { 
    char *myBuffer = (char *)malloc((int)[hexString length] / 2 + 1);
    bzero(myBuffer, [hexString length] / 2 + 1);
    for (int i = 0; i < [hexString length] - 1; i += 2) {
        unsigned int anInt;
        NSString * hexCharStr = [hexString substringWithRange:NSMakeRange(i, 2)];
        NSScanner * scanner = [[NSScanner alloc] initWithString:hexCharStr];
        [scanner scanHexInt:&anInt];
        myBuffer[i / 2] = (char)anInt;
    }
    NSString *unicodeString = [NSString stringWithCString:myBuffer encoding:4];
    NSLog(@"------普通字符串------%@",unicodeString);
    return unicodeString;
}


//普通字符串转换为十六进制的字符串(与Data类型中的一样)
- (NSString *)hexStringFromString:(NSString *)string{
    NSData *myD = [string dataUsingEncoding:NSUTF8StringEncoding];
    Byte *bytes = (Byte *)[myD bytes];
    //下面是Byte 转换为16进制。
    NSString *hexStr=@"";
    for(int i=0;i<[myD length];i++)
    {
        NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff];///16进制数
        NSLog(@"第%d个, newHexStr:%@", i, newHexStr);
        if([newHexStr length]==1)
            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
        else
            hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
        NSLog(@"第%d个, hexStr:%@", i, hexStr);
    }
    NSLog(@"------十六进制字符串------%@",hexStr);
    return hexStr;
}

//- (NSMutableData *)changeTo16HDataWithInteger:(NSInteger)integer
//{
//    NSMutableArray * array = [NSMutableArray array];
//    NSMutableArray * array1 = [NSMutableArray array];
//    int count = 0;
//    [array addObject:[NSNumber numberWithInteger:integer]];
//    while (integer / 256 > 0) {
//        count = count  + 1;
//        [array1 addObject:[NSNumber numberWithInteger:(integer / 256)]];
//        integer = integer % 256;
//        [array addObject:[NSNumber numberWithInteger:integer]];
//    }
//    
//    Byte value[count];
//    for (int i = 0; i < count - 1; i++) {
//        
//    }
//    length1[0] = 0x01 * integer1;
//}

// 整型 -> mutbledata
- (NSMutableData *)getMutbleDataNumFromInteger:(NSInteger)integer
{
    NSMutableArray * array1 = [NSMutableArray array];
    int count = 0;
    int remainder = integer % 256;
    while (integer > 256) {
        count = count  + 1;
        [array1 addObject:[NSNumber numberWithInteger:(integer / 256)]];
        remainder = integer % 256;
//        NSLog(@"------remainder-----%ld", (long)remainder);
        integer = integer / 256;
//        NSLog(@"------integer-----%ld", (long)integer);
    }
    
//    NSLog(@"------count + 1-----%d", count + 1);
//    NSLog(@"------array1-----%@", array1);
    Byte byte[count + 1];
    for (int i = 0; i < count + 1; i++) {
        if (i == count) {
            byte[i] = 0x01 * remainder;
        } else {
            byte[i] = 0x01 * [array1[i] floatValue];
        }
    }
    
    
    NSMutableData *mutdata = [NSMutableData data];
    [mutdata appendBytes:byte length:sizeof(byte)/sizeof(Byte)];
    
    NSLog(@"----------单元模块mutData----------%@", mutdata);
    return mutdata;
}

// 整型 -> SpecialMutbledata
- (NSMutableData *)getSpecialMutbleDataNumFromInteger:(NSInteger)integer
{
    NSMutableArray * array1 = [NSMutableArray array];
    NSInteger specialInteger = integer;
    int count = 0;
    int remainder = integer % 256;
    while (integer > 256) {
        count = count  + 1;
        [array1 addObject:[NSNumber numberWithInteger:(integer / 256)]];
        remainder = integer % 256;
        //        NSLog(@"------remainder-----%ld", (long)remainder);
        integer = integer / 256;
        //        NSLog(@"------integer-----%ld", (long)integer);
    }
    
    //    NSLog(@"------count + 1-----%d", count + 1);
    //    NSLog(@"------array1-----%@", array1);
    Byte byte[count + 1];
    for (int i = 0; i < count + 1; i++) {
        if (i == count) {
            byte[i] = 0x01 * remainder;
        } else {
            byte[i] = 0x01 * [array1[i] floatValue];
        }
    }
    
    
    NSMutableData *mutdata = [NSMutableData data];
    if (specialInteger > 128) {
        Byte byteSpecial[1];
        byteSpecial[0] = 0x80 + count;
        
        [mutdata appendBytes:byteSpecial length:sizeof(byteSpecial)/sizeof(Byte)];
        [mutdata appendBytes:byte length:sizeof(byte)/sizeof(Byte)];
    } else {
        [mutdata appendBytes:byte length:sizeof(byte)/sizeof(Byte)];
    }
    
    
    NSLog(@"----------单元模块mutData----------%@", mutdata);
    return mutdata;
}

// mutbledata -> 整型 (range 中的length代表的是字节; 在string中的字符数是字节数的2倍)
- (NSInteger)getIntegerFromMutbleDataNum:(NSMutableData *)mutbleDataNum withRange:(NSRange)range
{
    NSString *mutDataStr = [NSString stringWithFormat:@"%@", [mutbleDataNum subdataWithRange:range]];
    NSString *dataStr = [[mutDataStr substringWithRange:NSMakeRange(1, mutDataStr.length - 2)] stringByReplacingOccurrencesOfString:@" " withString:@""];
//    NSLog(@"======%@", dataStr);
//    NSLog(@"------%lu", (unsigned long)dataStr.length);
    NSMutableArray *subDataStrArray = [NSMutableArray array];
    for (int i = 0; i < dataStr.length / 2; i++) {
        [subDataStrArray addObject:[dataStr substringWithRange:NSMakeRange(i * 2, 2)]];
    }
//    NSLog(@"----%@", subDataStrArray);
    NSInteger integer = 0;
    for (int i = 0; i < subDataStrArray.count; i++) {
        integer = integer + (([self chengeToIntegerWithHexSingleStr:[subDataStrArray[i] substringWithRange:NSMakeRange(0, 1)]] * 16 + [self chengeToIntegerWithHexSingleStr:[subDataStrArray[i] substringWithRange:NSMakeRange(1, 1)]]) * pow(256, subDataStrArray.count - 1 -i));
    }
    NSLog(@"-------整型输出-------%ld", (long)integer);
    return integer;
}

- (NSInteger)chengeToIntegerWithHexSingleStr:(NSString *)hexSingleStr
{
    if ([hexSingleStr isEqualToString:@"0"]) {
        return 0;
    } else if ([hexSingleStr isEqualToString:@"1"])
    {
        return 1;
    } else if ([hexSingleStr isEqualToString:@"2"])
    {
        return 2;
    } else if ([hexSingleStr isEqualToString:@"3"])
    {
        return 3;
    } else if ([hexSingleStr isEqualToString:@"4"])
    {
        return 4;
    } else if ([hexSingleStr isEqualToString:@"5"])
    {
        return 5;
    } else if ([hexSingleStr isEqualToString:@"6"])
    {
        return 6;
    } else if ([hexSingleStr isEqualToString:@"7"])
    {
        return 7;
    } else if ([hexSingleStr isEqualToString:@"8"])
    {
        return 8;
    } else if ([hexSingleStr isEqualToString:@"9"])
    {
        return 9;
    } else if ([hexSingleStr isEqualToString:@"a"] || [hexSingleStr isEqualToString:@"A"])
    {
        return 10;
    } else if ([hexSingleStr isEqualToString:@"b"] || [hexSingleStr isEqualToString:@"B"])
    {
        return 11;
    } else if ([hexSingleStr isEqualToString:@"c"] || [hexSingleStr isEqualToString:@"C"])
    {
        return 12;
    } else if ([hexSingleStr isEqualToString:@"d"] || [hexSingleStr isEqualToString:@"D"])
    {
        return 13;
    } else if ([hexSingleStr isEqualToString:@"e"] || [hexSingleStr isEqualToString:@"E"])
    {
        return 14;
    } else if ([hexSingleStr isEqualToString:@"f"] || [hexSingleStr isEqualToString:@"F"])
    {
        return 15;
    }
    return 0;
}

/*
// NSData --> Byte
UIImage *image = [UIImage imageNamed:@"pic"];
NSData *imageData = UIImagePNGRepresentation(image);

NSLog(@"%@", imageData);
Byte *bytes = (Byte *)[imageData bytes];
NSLog(@"%x", bytes[1]);
NSString *string = [NSString stringWithFormat:@"%x", bytes[1]];
NSLog(@"%@", string);

NSLog(@"%@", [[NSDataTools shareDataTools] getMutbleDataNumFromInteger:80]);

NSMutableData *mutData = [[NSDataTools shareDataTools] getMutbleDataNumFromInteger:17];
NSString *string1 = [NSString stringWithFormat:@"%@", mutData];
NSLog(@"-----%@", string1);
 */


@end
