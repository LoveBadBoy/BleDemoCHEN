//
//  BeCentraliewController.m
//  BleDemo
//
//  Created by ZTELiuyw on 15/9/7.
//  Copyright (c) 2015年 liuyanwei. All rights reserved.
//

#import "BeCentralVewController.h"
#import "NSDataTools.h"
#import "OrderManager.h"

#define MainScreenWidth [UIScreen mainScreen].bounds.size.width
#define MainScreenHeight [UIScreen mainScreen].bounds.size.height
#define TitleText @"蓝牙设备列表"
#define DefualsNum 0x88
@interface BeCentralVewController ()<UITextFieldDelegate>
{
    //系统蓝牙设备管理对象，可以把他理解为主设备，通过他，可以去扫描和链接外设
    CBCentralManager *manager;
    UILabel *info;
    //用于保存被发现设备
    NSMutableArray *discoverPeripherals;
    UITableView *myTableView;
    
    UITextField *textField1;
    UITextField *textField2;
}

@property (strong ,nonatomic) CBCharacteristic        *writeCharacteristic;
@property (nonatomic, strong) CBPeripheral            *peripheral;

@end

@implementation BeCentralVewController

#pragma mark - 载入页面 添加布局
- (void)viewDidLoad {
    [super viewDidLoad];

    /*
     设置主设备的委托,CBCentralManagerDelegate
     必须实现的：
     - (void)centralManagerDidUpdateState:(CBCentralManager *)central;//主设备状态改变的委托，在初始化CBCentralManager的适合会打开设备，只有当设备正确打开后才能使用
     其他选择实现的委托中比较重要的：
     - (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI; //找到外设的委托
     - (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral;//连接外设成功的委托
     - (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;//外设连接失败的委托
     - (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;//断开外设的委托
     */
#warning 开启管理者
    //初始化并设置委托和线程队列，最好一个线程的参数可以为nil，默认会就main线程
    manager = [[CBCentralManager alloc]initWithDelegate:self queue:dispatch_get_main_queue()];

  //持有发现的设备,如果不持有设备会导致CBPeripheralDelegate方法不能正确回调
    discoverPeripherals = [[NSMutableArray alloc]init];
    
    // 页面布局
    [self layoutMySubViews];

}

- (void)layoutMySubViews
{
    //    //页面样式
    //    [self.view setBackgroundColor:[UIColor whiteColor]];
    //    info = [[UILabel alloc]initWithFrame:self.view.frame];
    //    [info setText:@"正在执行程序，请观察NSLog信息"];
    //    [info setTextAlignment:NSTextAlignmentCenter];
    //    [self.view addSubview:info];
    
    self.title = TitleText;
    // 设置表视图
    myTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, MainScreenWidth, MainScreenHeight/2) style:UITableViewStylePlain];
    myTableView.delegate = self;
    myTableView.dataSource = self;
    [self.view addSubview:myTableView];
    
    // 设置功能区
    UIView *downBGView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(myTableView.frame), MainScreenWidth, MainScreenHeight/2)];
    downBGView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:downBGView];
    
    //    // 设施右侧按钮
    //    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"write" style:UIBarButtonItemStyleBordered target:self action:@selector(releaseInfo:)];
    //    self.navigationItem.rightBarButtonItem = rightButton;
    
    // 修改前两位数字
    textField1 = [[UITextField alloc] initWithFrame:CGRectMake(20, 0, (MainScreenWidth - 20 * 3) / 2, 30)];
    textField1.placeholder = @"前两位数字";
    textField1.delegate = self;
    [downBGView addSubview:textField1];
    
    // 修改后两位数字
    textField2 = [[UITextField alloc] initWithFrame:CGRectMake((MainScreenWidth - 20 * 3) / 2 + 20 * 2, 0, (MainScreenWidth - 20 * 3) / 2, 30)];
    textField2.placeholder = @"后两位数字";
    textField2.delegate = self;
    [downBGView addSubview:textField2];
    
    // 确认写入按钮
    UIButton *writeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    writeButton.frame = CGRectMake(20, 50, (MainScreenWidth - 20 * 3) / 2, 30);
    [writeButton setTitle:@"确认写入" forState:UIControlStateNormal];
    //    [writeButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [writeButton addTarget:self action:@selector(releaseInfo:) forControlEvents:UIControlEventTouchUpInside];
    [downBGView addSubview:writeButton];
    
    // 断开连接按钮
    UIButton *cancelConnectButton = [UIButton buttonWithType:UIButtonTypeSystem];
    cancelConnectButton.frame = CGRectMake((MainScreenWidth - 20 * 3) / 2 + 20 * 2, 50, (MainScreenWidth - 20 * 3) / 2, 30);
    [cancelConnectButton setTitle:@"断开连接" forState:UIControlStateNormal];
    //    [cancelConnectButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [cancelConnectButton addTarget:self action:@selector(cancelConnect:) forControlEvents:UIControlEventTouchUpInside];
    [downBGView addSubview:cancelConnectButton];
    
}

#pragma mark  - <CBCentralManagerDelegate> Methods 判断中心设备蓝牙状态/扫描外设
-(void)centralManagerDidUpdateState:(CBCentralManager *)central{
    
    switch (central.state) {
        case CBCentralManagerStateUnknown:
            NSLog(@">>>CBCentralManagerStateUnknown");
            break;
        case CBCentralManagerStateResetting:
            NSLog(@">>>CBCentralManagerStateResetting");
            break;
        case CBCentralManagerStateUnsupported:
            NSLog(@">>>CBCentralManagerStateUnsupported");
            break;
        case CBCentralManagerStateUnauthorized:
            NSLog(@">>>CBCentralManagerStateUnauthorized");
            break;
        case CBCentralManagerStatePoweredOff:
            NSLog(@">>>CBCentralManagerStatePoweredOff");
            break;
        case CBCentralManagerStatePoweredOn:
            NSLog(@">>>CBCentralManagerStatePoweredOn");
            //开始扫描周围的外设
            /*
             第一个参数nil就是扫描周围所有的外设，扫描到外设后会进入
             - (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI;
             */
            [central scanForPeripheralsWithServices:nil options:nil];
            
            break;
        default:
            break;
    }
    
}

//扫描到设备会进入方法
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    
    NSLog(@"当扫描到设备:%@",peripheral.name);
    //接下连接我们的测试设备，如果你没有设备，可以下载一个app叫lightbule的app去模拟一个设备
    //这里自己去设置下连接规则，我设置的是P开头的设备
//    if ([peripheral.name hasPrefix:@"P"]){
        /*
         一个主设备最多能连7个外设，每个外设最多只能给一个主设备连接,连接成功，失败，断开会进入各自的委托
         - (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral;//连接外设成功的委托
         - (void)centra`lManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;//外设连接失败的委托
         - (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;//断开外设的委托
         */
  
        ///找到的设备必须持有它，否则CBCentralManager中也不会保存peripheral，那么CBPeripheralDelegate中的方法也不会被调用！！
    // 添加外围设备
    if (![discoverPeripherals containsObject:peripheral] && peripheral.name.length != 0) {
        [discoverPeripherals addObject:peripheral];
        [myTableView reloadData];
    }
    
//#warning 连接设备
//        [central connectPeripheral:peripheral options:nil];
//    }
    
    
}

#pragma mark - Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [discoverPeripherals count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identified = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identified];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identified];
    }
    CBPeripheral *p = [discoverPeripherals objectAtIndex:indexPath.row];
    cell.textLabel.text = p.name;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
#warning 连接设备
    [manager connectPeripheral:[discoverPeripherals objectAtIndex:indexPath.row] options:nil];
    
    CBPeripheral *peripheral = discoverPeripherals[indexPath.row];
    NSLog(@"=-=-=-=-=-=-=连接设备=-=-=-=-=-=-=");
}

#pragma mark - <CBCentralManagerDelegate> Methods 连接成功/失败/断开的代理方法

//连接到Peripherals-失败
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@">>>连接到名称为（%@）的设备-失败,原因:%@",[peripheral name],[error localizedDescription]);
    self.peripheral = nil;
}

//Peripherals断开连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@">>>外设连接断开连接 %@: %@\n", [peripheral name], [error localizedDescription]);
    self.peripheral = nil;
    
}
//连接到Peripherals-成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@">>>连接到名称为（%@）的设备-成功",peripheral.name);
    //设置的peripheral委托CBPeripheralDelegate
    //@interface ViewController : UIViewController<CBCentralManagerDelegate,CBPeripheralDelegate>
    [peripheral setDelegate:self];
    //扫描外设Services，成功后会进入方法：-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
#warning 扫描服务
    [peripheral discoverServices:nil];
    
    self.peripheral = peripheral;
    
}


#pragma mark  - <CBPeripheralDelegate> Methods 扫描服务/特征/描述的代理方法 更新特征/描述后的代理方法
//扫描到Services
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    //  NSLog(@">>>扫描到服务：%@",peripheral.services);
    if (error)
    {
        NSLog(@">>>Discovered services for %@ with error: %@", peripheral.name, [error localizedDescription]);
        return;
    }
    
    for (CBService *service in peripheral.services) {
        NSLog(@"%@",service.UUID);
        //扫描每个service的Characteristics，扫描到后会进入方法： -(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
#warning 扫描特征
        [peripheral discoverCharacteristics:nil forService:service];
    }
    
}

//扫描到Characteristics
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    if (error)
    {
        NSLog(@"error Discovered characteristics for %@ with error: %@", service.UUID, [error localizedDescription]);
        return;
    }
    
//    for (CBCharacteristic *characteristic in service.characteristics)
//    {
//        NSLog(@"service:%@ 的 Characteristic: %@",service.UUID,characteristic.UUID);
//    }
    
    for (CBCharacteristic *c in service.characteristics) {
        NSLog(@"======================S:%@  C:%@ characteristic.properties: %lu",service.UUID, c.UUID, (unsigned long)c.properties);
        
        if ([c.UUID isEqual:[CBUUID UUIDWithString:@"FFE1"]]) {
            self.writeCharacteristic = c;
            [peripheral readValueForCharacteristic:c];
            [peripheral setNotifyValue:YES forCharacteristic:c];
            NSLog(@"-=-=-=-=-=-=-=-=-=-=%@", self.writeCharacteristic);
        }

//        if ([c.UUID isEqual:[CBUUID UUIDWithString:@"FFF1"]]) {//读
//            [peripheral readValueForCharacteristic:c];
//            [peripheral setNotifyValue:YES forCharacteristic:c];
//        }
//
//        if ([c.UUID isEqual:[CBUUID UUIDWithString:@"FFF2"]]) {//写
////            self.writeCharacteristic = c;
//            [peripheral setNotifyValue:YES forCharacteristic:c];
//        }
//        
//        if ([c.UUID isEqual:[CBUUID UUIDWithString:@"FFF3"]]) {//读写
//            [peripheral readValueForCharacteristic:c];
//            [peripheral setNotifyValue:YES forCharacteristic:c];
//           
//        }
//        
//        if ([c.UUID isEqual:[CBUUID UUIDWithString:@"FFF4"]]) {//默认读写字段
//            [peripheral readValueForCharacteristic:c];
//            self.writeCharacteristic = c;
//            [peripheral setNotifyValue:YES forCharacteristic:c];
//          
//        }
//        
//        if ([c.UUID isEqual:[CBUUID UUIDWithString:@"FFF5"]]) {//notify字段
//            [peripheral setNotifyValue:YES forCharacteristic:c];
//        }
//        [peripheral setNotifyValue:YES forCharacteristic:c];
        
    }

//    //获取Characteristic的值，读到数据会进入方法：-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
//    for (CBCharacteristic *characteristic in service.characteristics){
//        {
//#warning 使用特征读取数据
//            [peripheral readValueForCharacteristic:characteristic];
//        }
//    }
    
    //搜索Characteristic的Descriptors，读到数据会进入方法：-(void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
    for (CBCharacteristic *characteristic in service.characteristics){
#warning 扫描描述
        [peripheral discoverDescriptorsForCharacteristic:characteristic];
    }
    
    
}

/// 获取到刷新后的charateristic的值 (也是 readValueForCharacteristic:方法的回调位置)
/// 获取外设发来的数据，不论是read和notify,获取数据都是从这个方法中读取。
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    //打印出characteristic的UUID和值
    //!注意，value的类型是NSData，具体开发时，会根据外设协议制定的方式去解析数据
    NSLog(@"characteristic uuid:%@  value:%@",characteristic.UUID,characteristic.value);
//    NSLog(@"---------------------------%@", _writeCharacteristic.value);
//    NSLog(@"-=-=-=-=-=-=-=-=-=-=%@", [[NSString alloc] initWithData:_writeCharacteristic.value  encoding:NSUTF8StringEncoding]);
}

//搜索到Characteristic的Descriptors
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    
    //打印出Characteristic和他的Descriptors
    NSLog(@"characteristic uuid:%@",characteristic.UUID);
    for (CBDescriptor *d in characteristic.descriptors) {
        NSLog(@"Descriptor uuid:%@",d.UUID);
    }
    
}
/// 获取到刷新后的Descriptors的值
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error{
    //打印出DescriptorsUUID 和value
    //这个descriptor都是对于characteristic的描述，一般都是字符串，所以这里我们转换成字符串去解析
//    NSLog(@"characteristic uuid:%@  value:%@",[NSString stringWithFormat:@"%@",descriptor.UUID],descriptor.value);
}

#pragma mark  - 读/写操作, 开/关通知, 断开连接的实例方法,    判断读/写是否成功的代理方法
//写数据
-(void)writeCharacteristic:(CBPeripheral *)peripheral
            characteristic:(CBCharacteristic *)characteristic
                     value:(NSData *)value{
    
    //打印出 characteristic 的权限，可以看到有很多种，这是一个NS_OPTIONS，就是可以同时用于好几个值，常见的有read，write，notify，indicate，知知道这几个基本就够用了，前连个是读写权限，后两个都是通知，两种不同的通知方式。
    /*
     typedef NS_OPTIONS(NSUInteger, CBCharacteristicProperties) {
     CBCharacteristicPropertyBroadcast												= 0x01,
     CBCharacteristicPropertyRead													= 0x02,
     CBCharacteristicPropertyWriteWithoutResponse									= 0x04,
     CBCharacteristicPropertyWrite													= 0x08,
     CBCharacteristicPropertyNotify													= 0x10,
     CBCharacteristicPropertyIndicate												= 0x20,
     CBCharacteristicPropertyAuthenticatedSignedWrites								= 0x40,
     CBCharacteristicPropertyExtendedProperties										= 0x80,
     CBCharacteristicPropertyNotifyEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)		= 0x100,
     CBCharacteristicPropertyIndicateEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)	= 0x200
     };
     
     */
    NSLog(@"%lu", (unsigned long)characteristic.properties);
    
    
    //只有 characteristic.properties 有write的权限才可以写
    if(characteristic.properties & CBCharacteristicPropertyWrite){
        /*
         最好一个type参数可以为CBCharacteristicWriteWithResponse或type:CBCharacteristicWriteWithResponse,区别是是否会有反馈
         */
        [peripheral writeValue:value forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }else{
        NSLog(@"该字段不可写！");
    }
    
    
}

//中心读取外设实时数据是否成功
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
    }
    
     NSLog(@"-=-=-=-=-=-设备:%@ 特征:%@ 读数据成功", peripheral.name, characteristic.UUID);
//    // Notification has started
//    if (characteristic.isNotifying) {
//        [peripheral readValueForCharacteristic:characteristic];
//    } else { // Notification has stopped
//        // so disconnect from the peripheral
//        NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
//    }
}

//用于检测中心向外设写数据是否成功
-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"=======%@",error.userInfo);
        
    }else{
        NSLog(@"设备:%@ 特征:%@ 写数据成功", peripheral.name, characteristic.UUID);
        
    }
    
    /* When a write occurs, need to set off a re-read of the local CBCharacteristic to update its value */
//    [peripheral readValueForCharacteristic:characteristic];
    
    
}

//设置通知
-(void)notifyCharacteristic:(CBPeripheral *)peripheral
             characteristic:(CBCharacteristic *)characteristic{
    //设置通知，数据通知会进入：didUpdateValueForCharacteristic方法
    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
    
}

//取消通知
-(void)cancelNotifyCharacteristic:(CBPeripheral *)peripheral
                   characteristic:(CBCharacteristic *)characteristic{
    
    [peripheral setNotifyValue:NO forCharacteristic:characteristic];
}

//停止扫描并断开连接
-(void)disconnectPeripheral:(CBCentralManager *)centralManager
                 peripheral:(CBPeripheral *)peripheral{
    //停止扫描
    [centralManager stopScan];
    //断开连接
    [centralManager cancelPeripheralConnection:peripheral];
    self.peripheral = nil;
}

typedef  unsigned char  INT8U;

static INT8U BCC_CheckSum(INT8U *buf, INT8U len)
{
    INT8U i;
    INT8U checksum = 0;
    
    for(i = 0; i < len; i++) {
        checksum ^= *buf++;
    }
    
    return checksum;
}


#pragma mark  - ButtonActions / Other DelegateMethods

- (void)releaseInfo:(UIButton *)sender
{
//    发 33 03 80 01 A2 20
//    收 33 0X 80 03 B2 00 00 XX
//    发 33 03 80 01 A8 2A
//    收 33 0X 81 0F XX …. XX  33 0X 00 0X XX XX ..XX
    Byte dataArray[6];
//    dataArray[0] = 0x33;
//    dataArray[1] = 0x03;
//    dataArray[2] = 0x80;
//    
//    dataArray[3] = 0x01;
//    dataArray[4] = 0xa2;
//    dataArray[5] = 0x20;
    
    dataArray[0] = 0x33;
    dataArray[1] = 0x03;
    dataArray[2] = 0x80;
    
    dataArray[3] = 0x01;
    dataArray[4] = 0xa8;
    dataArray[5] = 0x2a;
    
    NSData *data = [NSData dataWithBytes:dataArray length:sizeof(dataArray)/sizeof(Byte)];
    [_peripheral writeValue:data forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithResponse];
    
}



- (void)cancelConnect:(UIButton *)sender
{
//    if (self.peripheral) {
//        [self disconnectPeripheral:manager peripheral:self.peripheral];
//    }
    [_peripheral readValueForCharacteristic:_writeCharacteristic];
}



-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    
    [textField resignFirstResponder];
    return YES;
    
}
@end