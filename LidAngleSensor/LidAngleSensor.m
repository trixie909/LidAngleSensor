//
//  LidAngleSensor.m
//  LidAngleSensor
//
//  Created by Sam on 2025-09-06.
//

#import "LidAngleSensor.h"

@interface LidAngleSensor ()
@property (nonatomic, assign) IOHIDDeviceRef hidDevice;
@end

@implementation LidAngleSensor

- (instancetype)init {
    self = [super init];
    if (self) {
        _hidDevice = [self findLidAngleSensor];
        if (_hidDevice) {
            IOHIDDeviceOpen(_hidDevice, kIOHIDOptionsTypeNone);
            NSLog(@"[LidAngleSensor] Successfully initialized lid angle sensor");
        } else {
            NSLog(@"[LidAngleSensor] Failed to find lid angle sensor");
        }
    }
    return self;
}

- (void)dealloc {
    [self stopLidAngleUpdates];
}

- (BOOL)isAvailable {
    return _hidDevice != NULL;
}

- (IOHIDDeviceRef)findLidAngleSensor {
    IOHIDManagerRef manager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
    if (!manager) {
        NSLog(@"[LidAngleSensor] Failed to create IOHIDManager");
        return NULL;
    }
    
    if (IOHIDManagerOpen(manager, kIOHIDOptionsTypeNone) != kIOReturnSuccess) {
        NSLog(@"[LidAngleSensor] Failed to open IOHIDManager");
        CFRelease(manager);
        return NULL;
    }
    
    // Use Generic Desktop + Mouse criteria to find candidate devices
    // This broader search allows us to find the lid sensor among other HID devices
    NSDictionary *matchingDict = @{
        @"UsagePage": @(0x0001),    // Generic Desktop
        @"Usage": @(0x0003),        // Mouse
    };
    
    IOHIDManagerSetDeviceMatching(manager, (__bridge CFDictionaryRef)matchingDict);
    CFSetRef devices = IOHIDManagerCopyDevices(manager);
    IOHIDDeviceRef device = NULL;
    
    if (devices && CFSetGetCount(devices) > 0) {
        NSLog(@"[LidAngleSensor] Found %ld devices, looking for sensor...", CFSetGetCount(devices));
        
        const void **deviceArray = malloc(sizeof(void*) * CFSetGetCount(devices));
        CFSetGetValues(devices, deviceArray);
        
        // Search for the specific lid angle sensor device
        // Discovered through reverse engineering: Apple device with Sensor page
        for (CFIndex i = 0; i < CFSetGetCount(devices); i++) {
            IOHIDDeviceRef currentDevice = (IOHIDDeviceRef)deviceArray[i];
            
            CFNumberRef vendorID = IOHIDDeviceGetProperty(currentDevice, CFSTR("VendorID"));
            CFNumberRef productID = IOHIDDeviceGetProperty(currentDevice, CFSTR("ProductID"));
            CFNumberRef usagePage = IOHIDDeviceGetProperty(currentDevice, CFSTR("PrimaryUsagePage"));
            CFNumberRef usage = IOHIDDeviceGetProperty(currentDevice, CFSTR("PrimaryUsage"));
            
            int vid = 0, pid = 0, up = 0, u = 0;
            if (vendorID) CFNumberGetValue(vendorID, kCFNumberIntType, &vid);
            if (productID) CFNumberGetValue(productID, kCFNumberIntType, &pid);
            if (usagePage) CFNumberGetValue(usagePage, kCFNumberIntType, &up);
            if (usage) CFNumberGetValue(usage, kCFNumberIntType, &u);
            
            // Target the specific lid angle sensor device
            // VID=0x05AC (Apple), PID=0x8104, UsagePage=0x0020 (Sensor), Usage=0x008A (Orientation)
            if (vid == 0x05AC && pid == 0x8104 && up == 0x0020 && u == 0x008A) {
                device = (IOHIDDeviceRef)CFRetain(currentDevice);
                NSLog(@"[LidAngleSensor] Found lid angle sensor device: VID=0x%04X, PID=0x%04X", vid, pid);
                break;
            }
        }
        
        free(deviceArray);
    }
    
    if (devices) CFRelease(devices);
    
    IOHIDManagerClose(manager, kIOHIDOptionsTypeNone);
    CFRelease(manager);
    
    return device;
}

- (double)lidAngle {
    if (!_hidDevice) {
        return -2.0;  // Device not available
    }
    
    // Read lid angle using discovered parameters:
    // Feature Report Type 2, Report ID 1, returns 3 bytes with 16-bit angle in centidegrees
    uint8_t report[8] = {0};
    CFIndex reportLength = sizeof(report);
    
    IOReturn result = IOHIDDeviceGetReport(_hidDevice, 
                                          kIOHIDReportTypeFeature,  // Type 2
                                          1,                        // Report ID 1
                                          report, 
                                          &reportLength);
    
    if (result == kIOReturnSuccess && reportLength >= 3) {
        // Data format: [report_id, angle_low, angle_high]
        // Example: [01 72 00] = 0x7201 centidegrees = 291.85 degrees
        uint16_t rawValue = *(uint16_t*)(report);
        double angle = rawValue * 0.01;  // Convert centidegrees to degrees
        
        return angle;
    }
    
    return -2.0;
}

- (void)startLidAngleUpdates {
    if (!_hidDevice) {
        _hidDevice = [self findLidAngleSensor];
        if (_hidDevice) {
            NSLog(@"[LidAngleSensor] Starting lid angle updates");
            IOHIDDeviceOpen(_hidDevice, kIOHIDOptionsTypeNone);
        } else {
            NSLog(@"[LidAngleSensor] Lid angle sensor is not supported");
        }
    }
}

- (void)stopLidAngleUpdates {
    if (_hidDevice) {
        NSLog(@"[LidAngleSensor] Stopping lid angle updates");
        IOHIDDeviceClose(_hidDevice, kIOHIDOptionsTypeNone);
        CFRelease(_hidDevice);
        _hidDevice = NULL;
    }
}

@end
