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

@property (nonatomic, assign) NSTimeInterval reconnectTimeInterval;

/// devices need to be removed
@property (nonatomic, assign) BOOL willBeRemoved;

@property (nonatomic, strong, nullable) CBCharacteristic *defaultReadCharacteristic;

@property (nonatomic, strong, nullable) CBCharacteristic *defaultWriteCharacteristic;

@property (nonatomic, copy, nullable) void (^serviceAvaliableBlock)(CBPeripheral *peripheral, BOOL avaliable);
@property (nonatomic, copy, nullable) void (^unConnectBlock)(CBPeripheral *peripheral, BOOL success);
@property (nonatomic, copy, nullable) void (^readResponseBlock)(NSData *data);

- (void)readData;

- (void)sendDataWithResponse:(NSData *)data;

- (void)sendDataWithoutResponse:(NSData *)data;

@end

@protocol BLEManagerDelegate <NSObject>

- (void)bleManagerUnsupported;

- (void)bleManagerPowerOff;

- (void)bleManagerDidScanEnd;

@end

typedef NS_ENUM(NSInteger, BLEManagerChannel) {
    BLEManagerChannelWriteOnly = 0, // default
    BLEManagerChannelReadOnly = 1,
    BLEManagerChannelReadAndWrite = 2
};

@interface BLEManager : NSObject

@property (nonatomic, weak) id<BLEManagerDelegate> delegate;

/// devices must has the channel to be recognized as service avaliable
@property (nonatomic, assign) BLEManagerChannel needChannel;

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

- (void)scanWithTimeout:(NSTimeInterval)timeout;

- (void)stopScan;

- (void)connectToPeripheral:(CBPeripheral *)peripheral;

- (void)unconnectToPeripheral:(CBPeripheral *)peripheral;

- (void)removeConnectedPeripheral:(CBPeripheral *)peripheral;

- (void)unconnectAllConnectedPerpheral;

@end

NS_ASSUME_NONNULL_END
