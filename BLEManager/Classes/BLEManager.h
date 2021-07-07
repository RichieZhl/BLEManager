//
//  BLEManager.h
//  BTLE Transfer
//
//  Created by lylaut on 2021/6/25.
//  Copyright © 2021 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

@interface CBPeripheral (BLEManager_Extra)

/// reconnect timeout
@property (nonatomic, assign) NSTimeInterval reconnectTimeInterval;

/// devices need to be removed
@property (nonatomic, assign) BOOL willBeRemoved;

@property (nonatomic, strong, nullable) CBCharacteristic *defaultReadCharacteristic;

@property (nonatomic, strong, nullable) CBCharacteristic *defaultWriteCharacteristic;

@property (nonatomic, strong, nullable) CBCharacteristic *defaultWriteWithoutResponseCharacteristic;

@property (nonatomic, copy, nullable) void (^connectBlock)(CBPeripheral *peripheral, BOOL success);
@property (nonatomic, copy, nullable) void (^unConnectBlock)(CBPeripheral *peripheral, BOOL success);
@property (nonatomic, copy, nullable) void (^removeFromPariedDevicesBlock)(CBPeripheral *peripheral, BOOL success);
@property (nonatomic, copy, nullable) void (^readResponseBlock)(NSData *data);

- (void)readData;

- (void)sendDataWithResponse:(NSData *)data;

- (void)sendDataWithoutResponse:(NSData *)data;

@end

@protocol BLEManagerDelegate <NSObject>
/// device unsupported ble
- (void)bleManagerUnsupported;
/// device power off
- (void)bleManagerPowerOff;
/// device scan end
- (void)bleManagerDidScanEnd;

@end

@interface BLEManager : NSObject

@property (nonatomic, weak) id<BLEManagerDelegate> delegate;

/// all not filtered devices
@property (nonatomic, copy, readonly) NSArray<CBPeripheral *> *peripherals;

/// scan services filter
@property (nonatomic, copy) NSArray<CBUUID *> *filteredServices;

/// scan characteristic filter
@property (nonatomic, copy) NSArray<CBUUID *> *filteredCharacteristic;

/// all paried devices
@property (nonatomic, strong) NSMutableDictionary<NSString *, CBPeripheral *> *pariedPeripheralMaps;

+ (instancetype)sharedManager;

- (instancetype)init NS_UNAVAILABLE;

- (BOOL)savePariedPeripheral;

- (void)scanWithTimeout:(NSTimeInterval)timeout;

- (void)stopScan;

- (void)connectToPeripheral:(CBPeripheral *)peripheral;

- (void)unconnectToPeripheral:(CBPeripheral *)peripheral;

- (void)removeConnectedPeripheral:(CBPeripheral *)peripheral;

- (void)removeAllConnectedPeripheral;

@end

NS_ASSUME_NONNULL_END
