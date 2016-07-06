//
//  OrderManager.h
//  BleDemo
//
//  Created by FredChen on 16/6/24.
//  Copyright © 2016年 liuyanwei. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, OrderType) {
    APP_HandShake_A2            = 0,
    PICC_ChannelOrder_A3        = 1,
    ESAM_ChannelOrder_A4        = 2,
    ESAM_ResetOrder_A8          = 3,
    PICC_ResetOrder_A9          = 4,
    FIRM_Order_AE               = 5
};

typedef NS_ENUM(NSInteger, TestOrderType) {
    T_APP_HandShake_A2            = 0,
    T_PICC_ChannelOrder_A3        = 1,
    T_ESAM_ChannelOrder_A4        = 2,
    T_ESAM_ResetOrder_A8          = 3,
    T_PICC_ResetOrder_A9          = 4,
    T_FIRM_Order_AE               = 5
};

@interface OrderManager : NSObject

+ (instancetype)shareOrderManager;

// 通过命令类型获取数据帧
///------------------------------组包公共方法------------------------------
- (NSMutableArray *)getDataFramesWithOrderType:(OrderType)orderType packMaxBitsAmount:(NSInteger)count;

///------------------------------拆包公共方法------------------------------
- (NSMutableArray *)getOrderContentsWithOrderType:(OrderType)orderType responseDataArray:(NSMutableArray *)dataArray packMaxBitsAmount:(NSInteger)count;

@end
