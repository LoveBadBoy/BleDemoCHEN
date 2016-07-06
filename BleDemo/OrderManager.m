//
//  OrderManager.m
//  BleDemo
//
//  Created by FredChen on 16/6/24.
//  Copyright © 2016年 liuyanwei. All rights reserved.
//

#import "OrderManager.h"
#import "NSDataTools.h"

@implementation OrderManager

+ (instancetype)shareOrderManager
{
    static OrderManager *orderManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!orderManager) {
            orderManager = [[OrderManager alloc] init];
        }
    });
    return orderManager;
}

// 通过命令类型获取数据帧
///------------------------------组包公共方法------------------------------
- (NSMutableArray *)getDataFramesWithOrderType:(OrderType)orderType packMaxBitsAmount:(NSInteger)count
{
    // content中后半段的内容
    NSMutableData *keyContentData = [self installTPDUBlockWithOrderType:orderType];
    // 获取COS指令长度
    NSMutableData *COSOrderLength = [[NSDataTools shareDataTools] getMutbleDataNumFromInteger:keyContentData.length];
    // 拼接 应用层协议 (Type + content 反向拼接)
    NSMutableData *appData = [NSMutableData data];
    
    switch (orderType) {
        case APP_HandShake_A2:{
            /// 真实数据
            // 设置Type
            Byte type[1];
            type[0] = 0xa2; // Type
            
            [appData appendBytes:type length:sizeof(type)/sizeof(Byte)];
            break;
        }
        case PICC_ChannelOrder_A3:{
            /// 真实数据
            // 设置Type, Data Type
            Byte type[2];
            type[0] = 0xa3; // Type
            type[1] = 0x00; // Type Data 0x00为明文 0x01为加密
            
//            // 设置总Type
//            Byte typeAll[1];
//            typeAll[0] = 0xa3; // Type
            
            // 拼接 应用层协议 (Type + content 反向拼接)
//            [appData appendBytes:typeAll length:sizeof(typeAll)/sizeof(Byte)];
            [appData appendBytes:type length:sizeof(type)/sizeof(Byte)];
            
            break;
        }
        case ESAM_ChannelOrder_A4:{
            /// 真实数据
            // 设置Type, Data Type
            Byte type[2];
            type[0] = 0xa4; // Type
            type[1] = 0x00; // Type Data 0x00为明文 0x01为加密
            
            // 拼接 应用层协议 (Type + content 反向拼接)
            [appData appendBytes:type length:sizeof(type)/sizeof(Byte)];
            
            break;
        }
        case ESAM_ResetOrder_A8:{
            // 设置Type
            Byte type[1];
            type[0] = 0xa8; // Type
            
            [appData appendBytes:type length:sizeof(type)/sizeof(Byte)];
            break;
        }
        case PICC_ResetOrder_A9:{
            // 设置Type
            Byte type[1];
            type[0] = 0xa9; // Type
            
            [appData appendBytes:type length:sizeof(type)/sizeof(Byte)];
            break;
        }
        case FIRM_Order_AE:{
            nil;
            break;
        }
        default:
            break;
    }
    
    
    [appData appendData:COSOrderLength];
    [appData appendData:keyContentData];
    

    return [self appendPackHeaderWithPackContentWithData:appData packMaxBitsAmount:count];
}

- (NSMutableArray *)appendPackHeaderWithPackContentWithData:(NSMutableData *)mutbleData packMaxBitsAmount:(NSInteger)amount
{
    NSMutableArray *allArray = [NSMutableArray array];
    NSInteger count = [self getByteArrayWithData:mutbleData packMaxBitsAmount:amount].count;
    
    for (int i = 0; i < count; i++) {
        NSMutableData *allData = [NSMutableData data];
        [allData appendData:[self getByteArrayWithData:mutbleData packMaxBitsAmount:amount][i]];
        [allData appendData:[self disassemblyPackContentWithData:mutbleData packMaxBitsAmount:amount][i]];
        [allArray addObject:allData];
    }

    return allArray;
}
- (NSMutableArray *)disassemblyPackContentWithData:(NSMutableData *)mutbleData packMaxBitsAmount:(NSInteger)amount
{
    NSMutableArray *byteArray = [NSMutableArray array];
    NSInteger packCount = (mutbleData.length / amount) + 1;
    
    if (packCount == 1) {
        [byteArray addObject:mutbleData];
    } else {
        for (int i = 0; i < packCount; i++) {
            
            if (i == packCount - 1) {
                [byteArray addObject:[mutbleData subdataWithRange:NSMakeRange(i * amount, (mutbleData.length % amount))]];
            } else {
                [byteArray addObject:[mutbleData subdataWithRange:NSMakeRange(i * amount, amount)]];
            }
        }
    }

    return byteArray;
}
- (NSMutableArray *)getByteArrayWithData:(NSMutableData *)mutbleData packMaxBitsAmount:(NSInteger)amount
{
    NSMutableArray *byteArray = [NSMutableArray array];
    NSInteger count = (mutbleData.length / amount) + 1;
    for (int i = 0; i < count; i++) {
        // 创建前4帧Byte数组
        Byte firstFame[4];
        firstFame[0] = 0x33;  // 固定为0x33
        firstFame[1] = (0x01 + (0x01 * i)); // 帧序号
        switch (i) {
            case 0:{
                firstFame[2] = (0x80 + (0x01 * count - 1));
                break;
            }
            default:{
                firstFame[2] = (0x01 * count - 1) - (0x01 * i);
                break;
            }
        }
#warning 包头LEN位  1byte貌似不够用
        firstFame[3] = 0x01 * mutbleData.length; /// DATA域长度 暂时未知(1byte貌似不够用)
        
        NSMutableData * getMaxData = [NSMutableData data];
        [getMaxData appendBytes:firstFame length:sizeof(firstFame)/sizeof(Byte)];
//        NSLog(@"getMaxData: %@", getMaxData);
        // 将Byte数组 装入数组
        [byteArray addObject:getMaxData];
        
    }
    return byteArray;
}


- (NSMutableData *)installTPDUBlockWithOrderType:(OrderType)orderType
{
    // 装拼接TPDU单元模块 (length + TPDU)的数组
    NSMutableArray *dataAreaTPDUArray = [NSMutableArray array];
    
    switch (orderType) {
        case APP_HandShake_A2:{
            
            break;
        }
        case PICC_ChannelOrder_A3:{
            [dataAreaTPDUArray addObject:[self installTPDUUnitBlockWithType: T_ESAM_ResetOrder_A8]];
            [dataAreaTPDUArray addObject:[self installTPDUUnitBlockWithType: T_APP_HandShake_A2]];
            [dataAreaTPDUArray addObject:[self installTPDUUnitBlockWithType: T_PICC_ChannelOrder_A3]];
            break;
        }
        case ESAM_ChannelOrder_A4:{
            nil;
            break;
        }
        case ESAM_ResetOrder_A8:{
            nil;
            break;
        }
        case PICC_ResetOrder_A9:{
            nil;
            break;
        }
        case FIRM_Order_AE:{
            nil;
            break;
        }
        default:
            break;
    }
    
    NSMutableData *dataAreaTPDUData = [self installTPDUCmdBlockWithArray:dataAreaTPDUArray];
    
    return dataAreaTPDUData;
}

- (NSMutableData *)installTPDUCmdBlockWithArray:(NSMutableArray *)array
{
    Byte bigTitle [1];
    bigTitle[0] = 0x80;
//    NSLog(@"----------bigTitle----------%hhu", bigTitle[0]);
    // 多个子模块拼接好的包内容
    NSMutableData *TPDUDatas = [NSMutableData data];
    for (int i = 0; i < array.count; i++) {
        Byte title [1];
        title[0] = 0x01 + i;
        
        [TPDUDatas appendBytes:title length:sizeof(title)/sizeof(Byte)];
        [TPDUDatas appendData:array[i]];
    }
    
    // 计算拼接好的包内容的长度
//    NSInteger integer = [TPDUDatas length];
//    Byte length[1];
//    length[0] = 0x01 * integer;
//    NSLog(@"----------TPDU总命令模块length----------%hhu", length[0]);
    
    NSMutableData *allTPDUDatas = [NSMutableData data];
    [allTPDUDatas appendBytes:bigTitle length:sizeof(bigTitle)/sizeof(Byte)];
    
//    [allTPDUDatas appendBytes:length length:sizeof(length)/sizeof(Byte)];
    [allTPDUDatas appendData:[[NSDataTools shareDataTools] getSpecialMutbleDataNumFromInteger:[TPDUDatas length]]];
    [allTPDUDatas appendData:TPDUDatas];
    NSLog(@"----------Cmd总命令模块Data----------%@", allTPDUDatas);
    
    return allTPDUDatas;
}

- (NSMutableData *)installTPDUUnitBlockWithType:(TestOrderType)testOrderType
{
    NSData *data1 = [self creatOrderWithType:testOrderType];
    NSMutableData *mutdata1 = [[NSDataTools shareDataTools] getMutbleDataNumFromInteger:[self creatOrderWithType:testOrderType].length];
    [mutdata1 appendData:data1];
    return mutdata1;
}
// 测试命令
- (NSData *)creatOrderWithType:(TestOrderType)testOrderType
{
    NSData *data = [[NSData alloc] init];
    switch (testOrderType) {
        case T_APP_HandShake_A2:{
            data = [@"00000000" dataUsingEncoding: NSUTF8StringEncoding];
            break;
        }
        case T_PICC_ChannelOrder_A3:{
            data = [@"1111111111" dataUsingEncoding: NSUTF8StringEncoding];
            break;
        }
        case T_ESAM_ChannelOrder_A4:{
            data = [@"222222222222" dataUsingEncoding: NSUTF8StringEncoding];
            break;
        }
        case T_ESAM_ResetOrder_A8:{
            data = [@"33333333333333" dataUsingEncoding: NSUTF8StringEncoding];
            break;
        }
        case T_PICC_ResetOrder_A9:{
            data = [@"4444444444444444" dataUsingEncoding: NSUTF8StringEncoding];
            break;
        }
        case T_FIRM_Order_AE:{
            data = [@"555555555555555555" dataUsingEncoding: NSUTF8StringEncoding];
            break;
        }
        default:
            break;
    }
    return data;
}


///------------------------------拆包公共方法------------------------------
- (NSMutableArray *)getOrderContentsWithOrderType:(OrderType)orderType responseDataArray:(NSMutableArray *)dataArray packMaxBitsAmount:(NSInteger)count
{
    // 拆包组合
    NSMutableData *TPDUData = [self installMutbleDataWithDataArray:dataArray packMaxBitsAmount:count];
    
    // 承接数据
    NSMutableData *mutData = nil;
    switch (orderType) {
        case APP_HandShake_A2:{
           
            break;
        }
        case PICC_ChannelOrder_A3:{
            NSData *data = [TPDUData subdataWithRange:NSMakeRange(5, TPDUData.length - 5)];
            mutData = [NSMutableData dataWithData:data];
            break;
        }
        case ESAM_ChannelOrder_A4:{
            nil;
            break;
        }
        case ESAM_ResetOrder_A8:{
            nil;
            break;
        }
        case PICC_ResetOrder_A9:{
            nil;
            break;
        }
        case FIRM_Order_AE:{
            nil;
            break;
        }
        default:
            break;
    }
    
    return [self installTPDUOrderArrayWithData:mutData];
}

- (NSMutableData *)installMutbleDataWithDataArray:(NSMutableArray *)dataArray packMaxBitsAmount:(NSInteger)amount
{
    NSMutableData *mutbleData = [NSMutableData data];
    NSInteger pakcHeader = 4;
    for (int i = 0; i < dataArray.count; i++) {
        if (i == dataArray.count - 1) {
            [mutbleData appendData:[dataArray[i] subdataWithRange:NSMakeRange(pakcHeader, [(NSMutableData *)dataArray[i] length] - pakcHeader)]];
        } else {
            [mutbleData appendData:[dataArray[i] subdataWithRange:NSMakeRange(pakcHeader, amount)]];
        }
    }
    return mutbleData;
}

- (NSMutableArray *)installTPDUOrderArrayWithData:(NSMutableData *)data
{
    NSMutableArray *array = [NSMutableArray array];
    // 承接data
    NSMutableData *mutData = [NSMutableData dataWithData:data];
    // 当前串中第一组命令长度
    NSInteger orderLength = [[NSDataTools shareDataTools] getIntegerFromMutbleDataNum:mutData withRange:NSMakeRange(1, 1)];
    while (mutData.length > orderLength) {
        // 命令Data
        [array addObject:[mutData subdataWithRange:NSMakeRange(2, orderLength)]];
        // 剩余的Data
       mutData = [NSMutableData dataWithData:[mutData subdataWithRange:NSMakeRange(orderLength + 2, mutData.length - orderLength - 2)]];
        // 重置orderLength
        if (mutData.length > 2) { // 判断剩余的Data的长度必须大于2
            orderLength = [[NSDataTools shareDataTools] getIntegerFromMutbleDataNum:mutData withRange:NSMakeRange(1, 1)];
        }
    }
    
    return array;
}
@end
