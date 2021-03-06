//
//  BLEManager.m
//  BTLE Transfer
//
//  Created by lylaut on 2021/6/25.
//  Copyright © 2021 Apple. All rights reserved.
//

#import "BLEManager.h"
#import <objc/runtime.h>

static void *CBPeripheralReconnectTimeIntervalKey = &CBPeripheralReconnectTimeIntervalKey;
static void *CBPeripheralWillBeRemovedKey = &CBPeripheralWillBeRemovedKey;
static void *CBPeripheralDefaultReadCharacteristicKey = &CBPeripheralDefaultReadCharacteristicKey;
static void *CBPeripheralDefaultWriteCharacteristicKey = &CBPeripheralDefaultWriteCharacteristicKey;
static void *CBPeripheralDefaultWriteWithoutResponseCharacteristicKey = &CBPeripheralDefaultWriteWithoutResponseCharacteristicKey;
static void *CBPeripheralConnectBlockBlockKey = &CBPeripheralConnectBlockBlockKey;
static void *CBPeripheralUnConnectBlockKey = &CBPeripheralUnConnectBlockKey;
static void *CBPeripheralRemoveFromPariedDevicesBlockKey = &CBPeripheralRemoveFromPariedDevicesBlockKey;
static void *CBPeripheralReadReponseBlockKey = &CBPeripheralReadReponseBlockKey;

@implementation CBPeripheral (BLEManager_Extra)

- (void)setReconnectTimeInterval:(NSTimeInterval)reconnectTimeInterval {
    objc_setAssociatedObject(self, CBPeripheralReconnectTimeIntervalKey, @(reconnectTimeInterval), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSTimeInterval)reconnectTimeInterval {
    NSNumber *number = objc_getAssociatedObject(self, CBPeripheralReconnectTimeIntervalKey);
    if ([number isKindOfClass:[NSNumber class]]) {
        return [number doubleValue];
    }
    return 0;
}

- (void)setWillBeRemoved:(BOOL)removed {
    objc_setAssociatedObject(self, CBPeripheralWillBeRemovedKey, @(removed), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)willBeRemoved {
    NSNumber *number = objc_getAssociatedObject(self, CBPeripheralWillBeRemovedKey);
    if ([number isKindOfClass:[NSNumber class]]) {
        return [number boolValue];
    }
    return NO;
}

- (void)setDefaultReadCharacteristic:(CBCharacteristic *)defaultReadCharacteristic {
    objc_setAssociatedObject(self, CBPeripheralDefaultReadCharacteristicKey, defaultReadCharacteristic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CBCharacteristic *)defaultReadCharacteristic {
    return objc_getAssociatedObject(self, CBPeripheralDefaultReadCharacteristicKey);
}

- (void)setDefaultWriteCharacteristic:(CBCharacteristic *)defaultWriteCharacteristic {
    objc_setAssociatedObject(self, CBPeripheralDefaultWriteCharacteristicKey, defaultWriteCharacteristic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CBCharacteristic *)defaultWriteCharacteristic {
    return objc_getAssociatedObject(self, CBPeripheralDefaultWriteCharacteristicKey);
}

- (void)setDefaultWriteWithoutResponseCharacteristic:(CBCharacteristic *)defaultWriteWithoutResponseCharacteristic {
    objc_setAssociatedObject(self, CBPeripheralDefaultWriteWithoutResponseCharacteristicKey, defaultWriteWithoutResponseCharacteristic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CBCharacteristic *)defaultWriteWithoutResponseCharacteristic {
    return objc_getAssociatedObject(self, CBPeripheralDefaultWriteWithoutResponseCharacteristicKey);
}

- (void)setConnectBlock:(void (^)(CBPeripheral * _Nonnull, BOOL))connectBlock {
    objc_setAssociatedObject(self, CBPeripheralConnectBlockBlockKey, connectBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void (^)(CBPeripheral * _Nonnull, BOOL))connectBlock {
    return objc_getAssociatedObject(self, CBPeripheralConnectBlockBlockKey);
}

- (void)setUnConnectBlock:(void (^)(CBPeripheral * _Nonnull, BOOL))unConnectBlock {
    objc_setAssociatedObject(self, CBPeripheralUnConnectBlockKey, unConnectBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void (^)(CBPeripheral * _Nonnull, BOOL))unConnectBlock {
    return objc_getAssociatedObject(self, CBPeripheralUnConnectBlockKey);
}

- (void)setRemoveFromPariedDevicesBlock:(void (^)(CBPeripheral * _Nonnull, BOOL))removeFromPariedDevicesBlock {
    objc_setAssociatedObject(self, CBPeripheralRemoveFromPariedDevicesBlockKey, removeFromPariedDevicesBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void (^)(CBPeripheral * _Nonnull, BOOL))removeFromPariedDevicesBlock {
    return objc_getAssociatedObject(self, CBPeripheralRemoveFromPariedDevicesBlockKey);
}

- (void)setReadResponseBlock:(void (^)(NSData * _Nonnull))readResponseBlock {
    objc_setAssociatedObject(self, CBPeripheralReadReponseBlockKey, readResponseBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void (^)(NSData * _Nonnull))readResponseBlock {
    return objc_getAssociatedObject(self, CBPeripheralReadReponseBlockKey);
}

- (void)readData {
    if (self.defaultReadCharacteristic == nil) {
        NSLog(@"No avaliable read port to read");
        return;
    }
    
    if (!(self.state == CBPeripheralStateConnected)) {
        if (self.state == CBPeripheralStateConnecting) {
            NSLog(@"peripheral connecting");
            return;
        }
        NSLog(@"unavaliable peripheral");
        [self reconnect];
        return;
    }
    
    [self readValueForCharacteristic:self.defaultReadCharacteristic];
}

- (void)sendDataWithResponse:(NSData *)data {
    if (self.defaultWriteCharacteristic == nil) {
        NSLog(@"No avaliable write port to write");
        return;
    }
    
    if (!(self.state == CBPeripheralStateConnected)) {
        if (self.state == CBPeripheralStateConnecting) {
            NSLog(@"peripheral connecting");
            return;
        }
        NSLog(@"unavaliable peripheral");
        [self reconnect];
        return;
    }
    
    [self writeValue:data forCharacteristic:self.defaultWriteCharacteristic type:CBCharacteristicWriteWithResponse];
}

- (void)sendDataWithoutResponse:(NSData *)data {
    if (self.defaultWriteWithoutResponseCharacteristic == nil) {
        NSLog(@"No avaliable write port to write");
        [self reconnect];
        return;
    }
    
    
    if (!(self.state == CBPeripheralStateConnected)) {
        if (self.state == CBPeripheralStateConnecting) {
            NSLog(@"peripheral connecting");
            return;
        }
        NSLog(@"unavaliable peripheral");
        [self reconnect];
        return;
    }
    
    [self writeValue:data forCharacteristic:self.defaultWriteWithoutResponseCharacteristic type:CBCharacteristicWriteWithoutResponse];
}

- (void)reconnect {
    NSTimeInterval timeinterval = self.reconnectTimeInterval;
    if (timeinterval == 0) {
        timeinterval = 1;
    } else {
        timeinterval *= 2;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeinterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[BLEManager sharedManager] connectToPeripheral:self];
    });
}

@end

@interface BLEManager () <CBCentralManagerDelegate, CBPeripheralDelegate> {
    BOOL initalCompelte;
    BOOL needsInitalScan;
    NSTimeInterval scanTimeout;
    
    BOOL isScaning;
    BOOL supportBluetoothService;
}

@property (nonatomic, strong) CBCentralManager *centralManager;

@property (nonatomic, strong) NSMutableDictionary<NSString *, CBPeripheral *> *peripheralMaps;

@property (nonatomic, copy) NSString *savedPariedDevicesFilePath;

@property (nonatomic, copy) NSArray<NSString *> *pStrings;

@end

@implementation BLEManager

static BLEManager *bleManager = nil;

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bleManager = [[BLEManager alloc] init];
    });
    return bleManager;
}

- (NSMutableDictionary<NSString *,CBPeripheral *> *)peripheralMaps {
    if (_peripheralMaps == nil) {
        _peripheralMaps = [NSMutableDictionary dictionary];
    }
    
    return _peripheralMaps;
}

- (NSArray<CBPeripheral *> *)peripherals {
    return self.peripheralMaps.allValues;
}

- (NSMutableDictionary<NSString *,CBPeripheral *> *)pariedPeripheralMaps {
    if (_pariedPeripheralMaps == nil) {
        _pariedPeripheralMaps = [NSMutableDictionary dictionary];
    }
    
    return _pariedPeripheralMaps;
}

- (CBCentralManager *)centralManager {
    if (_centralManager == nil) {
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    return _centralManager;
}

- (NSString *)savedPariedDevicesFilePath {
    if (_savedPariedDevicesFilePath == nil) {
        @synchronized (self) {
            if (_savedPariedDevicesFilePath == nil) {
                NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
                path = [path stringByAppendingPathComponent:@"blemanager"];
                BOOL dir = NO;
                if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&dir] || !dir) {
                    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:@{} error:nil];
                }
                _savedPariedDevicesFilePath = [path stringByAppendingPathComponent:@"blemanager_paried_devices.dat"];
            }
        }
    }
    
    return _savedPariedDevicesFilePath;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        supportBluetoothService = NO;
        initalCompelte = NO;
        needsInitalScan = NO;
        scanTimeout = 0;
        [self configPariedDevices];
    }
    return self;
}

- (id)mutableCopy {
    return bleManager;
}

- (id)copy {
    return bleManager;
}

#pragma mark - public methods
- (BOOL)savePariedPeripheral {
    NSMutableArray<NSString *> *pStrings = [NSMutableArray array];
    for (CBPeripheral *p in self.pariedPeripheralMaps.allValues) {
        [pStrings addObject:p.identifier.UUIDString];
    }
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:pStrings options:NSJSONWritingPrettyPrinted error:nil];
    if (data == nil) {
        return NO;
    }
    
    return [data writeToFile:self.savedPariedDevicesFilePath atomically:YES];
}

- (void)scanWithTimeout:(NSTimeInterval)timeout {
    @synchronized (self) {
        if (self.centralManager.state == CBManagerStateUnsupported) {
            if (self.delegate) {
                [self.delegate bleManagerUnsupported];
            }
            initalCompelte = YES;
            return;
        } else if (self.centralManager.state == CBManagerStatePoweredOff) {
            if (self.delegate) {
                [self.delegate bleManagerPowerOff];
            }
        }
        if (!initalCompelte) {
            needsInitalScan = YES;
            scanTimeout = timeout;
            return;
        }
        if (!supportBluetoothService) {
            return;
        }
        if (isScaning) {
            return;
        }
        isScaning = YES;
        [self.peripheralMaps removeAllObjects];
        
        if ([NSThread isMainThread]) {
            [self.centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @NO}];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @NO}];
            });
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self stopScan];
        });
    }
}

- (void)stopScan {
    @synchronized (self) {
        if (!isScaning) {
            return;
        }
        isScaning = NO;
        [self.centralManager stopScan];
        self.pStrings = nil;
        if (self.delegate) {
            [self.delegate bleManagerDidScanEnd];
        }
    }
}

- (void)connectToPeripheral:(CBPeripheral *)peripheral {
    if (peripheral.state == CBPeripheralStateConnected) {
        return;
    }
    [self.centralManager connectPeripheral:peripheral options:nil];
}

- (void)unconnectToPeripheral:(CBPeripheral *)peripheral {
    [self cleanupWithPeripheral:peripheral];
}

- (void)removeConnectedPeripheral:(CBPeripheral *)peripheral {
    peripheral.willBeRemoved = YES;
    [self cleanupWithPeripheral:peripheral];
}

- (void)removeAllConnectedPeripheral {
    @synchronized (self.centralManager) {
        __weak typeof(self) weakSelf = self;
        [self.pariedPeripheralMaps enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, CBPeripheral * _Nonnull periperal, BOOL * _Nonnull stop) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf removeConnectedPeripheral:periperal];
        }];
    }
}

#pragma mark - private methods
- (void)configPariedDevices {
    NSData *data = [NSData dataWithContentsOfFile:self.savedPariedDevicesFilePath];
    if (data == nil) {
        return;
    }
    NSArray<NSString *> *pStrings = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    if (![pStrings isKindOfClass:[NSArray class]] || pStrings.count == 0) {
        return;
    }
    
    self.pStrings = pStrings;
    
    [self scanWithTimeout:5];
}

- (void)cleanupWithPeripheral:(CBPeripheral *)peripheral {
    if (!(peripheral.state == CBPeripheralStateConnected)) {
        return;
    }
    
    // See if we are subscribed to a characteristic on the peripheral
    if (peripheral.services != nil) {
        for (CBService *service in peripheral.services) {
            if (service.characteristics != nil) {
                for (CBCharacteristic *characteristic in service.characteristics) {
                    if (characteristic.properties == CBCharacteristicPropertyNotify) {
                        if (characteristic.isNotifying) {
                            // It is notifying, so unsubscribe
                            [peripheral setNotifyValue:NO forCharacteristic:characteristic];
                            break;
                        }
                    }
                }
            }
        }
    }
    
    peripheral.defaultReadCharacteristic = nil;
    peripheral.defaultWriteCharacteristic = nil;
    
    // If we've got this far, we're connected, but we're not subscribed, so we just disconnect
    [self.centralManager cancelPeripheralConnection:peripheral];
}

#pragma mark - CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state != CBManagerStatePoweredOn) {
        if (central.state == CBManagerStateUnknown || central.state == CBManagerStateUnsupported) {
            if (self.delegate) {
                [self.delegate bleManagerUnsupported];
            }
            initalCompelte = YES;
            return;
        }
        if (central.state == CBManagerStatePoweredOff) {
            if (self.delegate) {
                [self.delegate bleManagerPowerOff];
            }
        }
        return;
    }
    
    supportBluetoothService = YES;
    initalCompelte = YES;
    if (needsInitalScan) {
        [self scanWithTimeout:scanTimeout];
        scanTimeout = 0;
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    // ignore empty name devices
    if (peripheral.name == nil || peripheral.name.length == 0) {
        return;
    }
    
    NSLog(@"Discovered %@ at %@", peripheral.name, RSSI);
    
    NSString *UUIDString = peripheral.identifier.UUIDString;
    if ([self.peripheralMaps objectForKey:peripheral.identifier.UUIDString]) {
        return;
    }
    
    self.peripheralMaps[UUIDString] = peripheral;
    
    if (self.pStrings != nil && [self.pStrings containsObject:UUIDString]) {
        [self connectToPeripheral:peripheral];
    }
}

/** If the connection fails for whatever reason, we need to deal with it.
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
    if (peripheral.connectBlock) {
        peripheral.connectBlock(peripheral, NO);
    }
    [self cleanupWithPeripheral:peripheral];
}

/** We've connected to the peripheral, now we need to discover the services and characteristics to find the 'transfer' characteristic.
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"Peripheral Connected");

    // Make sure we get the discovery callbacks
    @synchronized (central) {
        self.pariedPeripheralMaps[peripheral.identifier.UUIDString] = peripheral;
    }
    if (peripheral.connectBlock) {
        peripheral.connectBlock(peripheral, YES);
    }
    
    peripheral.reconnectTimeInterval = 0;
    
    peripheral.delegate = self;
        
    // Search only for services that match our UUID
    [peripheral discoverServices:self.filteredServices];
}

#pragma mark - CBPeripheralDelegate
/** The Transfer Service was discovered
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        NSLog(@"Error discovering services: %@", [error localizedDescription]);
        [self cleanupWithPeripheral:peripheral];
        return;
    }
    
    // Discover the characteristic we want...
    // Loop through the newly filled peripheral.services array, just in case there's more than one.
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:self.filteredCharacteristic forService:service];
    }
}

/** The Transfer characteristic was discovered.
 *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    // Deal with errors (if any)
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        if (peripheral.connectBlock) {
            peripheral.connectBlock(peripheral, NO);
        }
        [self removeConnectedPeripheral:peripheral];
        return;
    }
    
    // Again, we loop through the array, just in case.
    for (CBCharacteristic *characteristic in service.characteristics) {
        if (characteristic.properties == CBCharacteristicPropertyNotify) {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        } else if (characteristic.properties == CBCharacteristicPropertyRead) {
            if (peripheral.defaultReadCharacteristic == nil) {
                peripheral.defaultReadCharacteristic = characteristic;
            }
        } else if (characteristic.properties == CBCharacteristicPropertyWriteWithoutResponse) {
            if (peripheral.defaultWriteWithoutResponseCharacteristic == nil) {
                peripheral.defaultWriteWithoutResponseCharacteristic = characteristic;
            }
        } else if (characteristic.properties == CBCharacteristicPropertyWrite ||
                   characteristic.properties == 12) {
            if (peripheral.defaultWriteCharacteristic == nil) {
                peripheral.defaultWriteCharacteristic = characteristic;
            }
        }
    }
}

/** This callback lets us know more data has arrived via notification on the characteristic
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        return;
    }
    
    if (peripheral.readResponseBlock) {
        peripheral.readResponseBlock(characteristic.value);
    }
}

/** The peripheral letting us know whether our subscribe/unsubscribe happened or not
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
    }
    
    // Notification has started
    if (characteristic.isNotifying) {
        NSLog(@"Notification began on %@", characteristic);
    } else { // Notification has stopped
        // so disconnect from the peripheral
        NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
        [self.centralManager cancelPeripheralConnection:peripheral];
    }
}

/** Once the disconnection happens, we need to clean up our local copy of the peripheral
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    if (error) {
        NSLog(@"Peripheral Disconnected failed");
        
        if (peripheral.willBeRemoved) {
            if (peripheral.removeFromPariedDevicesBlock) {
                peripheral.removeFromPariedDevicesBlock(peripheral, NO);
            }
        } else if (peripheral.unConnectBlock) {
            peripheral.unConnectBlock(peripheral, NO);
        }
        return;
    }
    NSLog(@"Peripheral Disconnected");
    
    if (peripheral.willBeRemoved) {
        if (peripheral.removeFromPariedDevicesBlock) {
            peripheral.removeFromPariedDevicesBlock(peripheral, YES);
        }
        
        @synchronized (self.centralManager) {
            [self.pariedPeripheralMaps removeObjectForKey:peripheral.identifier.UUIDString];
        }
    } else if (peripheral.unConnectBlock) {
        peripheral.unConnectBlock(peripheral, YES);
    }
}

@end
