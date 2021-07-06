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
static void *CBPeripheralDefaultReadCharacteristicKey = &CBPeripheralDefaultReadCharacteristicKey;
static void *CBPeripheralDefaultWriteCharacteristicKey = &CBPeripheralDefaultWriteCharacteristicKey;
static void *CBPeripheralServiceAvaliableBlockKey = &CBPeripheralServiceAvaliableBlockKey;
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

- (void)setServiceAvaliableBlock:(void (^)(CBPeripheral * _Nonnull, BOOL))serviceAvaliableBlock {
    objc_setAssociatedObject(self, CBPeripheralServiceAvaliableBlockKey, serviceAvaliableBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void (^)(CBPeripheral *, BOOL))serviceAvaliableBlock {
    return objc_getAssociatedObject(self, CBPeripheralServiceAvaliableBlockKey);
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
        [[BLEManager sharedManager].connectedPeripheralMaps removeObjectForKey:self.identifier.UUIDString];
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
        [[BLEManager sharedManager].connectedPeripheralMaps removeObjectForKey:self.identifier.UUIDString];
        [self reconnect];
        return;
    }
    
    [self writeValue:data forCharacteristic:self.defaultWriteCharacteristic type:CBCharacteristicWriteWithResponse];
}

- (void)sendDataWithoutResponse:(NSData *)data {
    if (self.defaultWriteCharacteristic == nil) {
        NSLog(@"No avaliable write port to write");
        [[BLEManager sharedManager].connectedPeripheralMaps removeObjectForKey:self.identifier.UUIDString];
        [self reconnect];
        return;
    }
    
    
    if (!(self.state == CBPeripheralStateConnected)) {
        if (self.state == CBPeripheralStateConnecting) {
            NSLog(@"peripheral connecting");
            return;
        }
        NSLog(@"unavaliable peripheral");
        [[BLEManager sharedManager].connectedPeripheralMaps removeObjectForKey:self.identifier.UUIDString];
        [self reconnect];
        return;
    }
    
    [self writeValue:data forCharacteristic:self.defaultWriteCharacteristic type:CBCharacteristicWriteWithoutResponse];
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

- (NSMutableDictionary<NSString *,CBPeripheral *> *)connectedPeripheralMaps {
    if (_connectedPeripheralMaps == nil) {
        _connectedPeripheralMaps = [NSMutableDictionary dictionary];
    }
    
    return _connectedPeripheralMaps;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        supportBluetoothService = NO;
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        initalCompelte = NO;
        needsInitalScan = NO;
        scanTimeout = 0;
        _needChannel = BLEManagerChannelWriteOnly;
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
- (void)scanWithTimeout:(NSTimeInterval)timeout {
    @synchronized (self) {
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
            [_centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @NO}];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self->_centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @NO}];
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
        [_centralManager stopScan];
        if (self.delegate) {
            [self.delegate bleManagerDidScanEnd];
        }
    }
}

- (void)connectToPeripheral:(CBPeripheral *)peripheral {
    [self.centralManager connectPeripheral:peripheral options:nil];
}

- (void)unconnectToPeripheral:(CBPeripheral *)peripheral {
    [self cleanupWithPeripheral:peripheral];
}

- (void)unconnectAllConnectedPerpheral {
    @synchronized (self.centralManager) {
        __weak typeof(self) weakSelf = self;
        [self.connectedPeripheralMaps enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, CBPeripheral * _Nonnull periperal, BOOL * _Nonnull stop) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf cleanupWithPeripheral:periperal];
        }];
        [self.connectedPeripheralMaps removeAllObjects];
    }
}

#pragma mark - private methods
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
}

/** If the connection fails for whatever reason, we need to deal with it.
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
    if (peripheral.serviceAvaliableBlock) {
        peripheral.serviceAvaliableBlock(peripheral, NO);
    }
    [self cleanupWithPeripheral:peripheral];
}

/** We've connected to the peripheral, now we need to discover the services and characteristics to find the 'transfer' characteristic.
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"Peripheral Connected");

    // Make sure we get the discovery callbacks
    @synchronized (central) {
        self.connectedPeripheralMaps[peripheral.identifier.UUIDString] = peripheral;
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
        if (peripheral.serviceAvaliableBlock) {
            peripheral.serviceAvaliableBlock(peripheral, NO);
        }
        [self cleanupWithPeripheral:peripheral];
        return;
    }
    
    // Again, we loop through the array, just in case.
    BOOL notifyFlag = NO;
    BOOL hasWrite = NO;
    BOOL hasRead = NO;
    for (CBCharacteristic *characteristic in service.characteristics) {
        if (characteristic.properties == CBCharacteristicPropertyNotify) {
            if (notifyFlag) {
                continue;
            }
            notifyFlag = YES;
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        } else if (characteristic.properties == CBCharacteristicPropertyRead) {
            if (peripheral.defaultReadCharacteristic == nil) {
                peripheral.defaultReadCharacteristic = characteristic;
                hasRead = YES;
            }
        } else if (characteristic.properties == CBCharacteristicPropertyWrite ||
                   characteristic.properties == CBCharacteristicPropertyWriteWithoutResponse ||
                   characteristic.properties == 12) {
            if (peripheral.defaultWriteCharacteristic == nil) {
                peripheral.defaultWriteCharacteristic = characteristic;
                hasWrite = YES;
            }
        }
    }
    
    // Once this is complete, we just need to wait for the data to come in.
    if ((self.needChannel == BLEManagerChannelWriteOnly && hasWrite) ||
        (self.needChannel == BLEManagerChannelReadOnly && hasRead) ||
        (self.needChannel == BLEManagerChannelReadAndWrite && hasRead && hasWrite)) {
        if (peripheral.serviceAvaliableBlock) {
            peripheral.serviceAvaliableBlock(peripheral, YES);
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
    NSLog(@"Peripheral Disconnected");
    
    [self.peripheralMaps removeObjectForKey:peripheral.identifier.UUIDString];
}

@end
