//
//  AppDelegate.m
//  LidAngleSensor
//
//  Created by Sam on 2025-09-06.
//

#import "AppDelegate.h"
#import "LidAngleSensor.h"

@interface AppDelegate ()
@property (strong, nonatomic) LidAngleSensor *lidSensor;
@property (strong, nonatomic) NSTextField *angleLabel;
@property (strong, nonatomic) NSTextField *statusLabel;
@property (strong, nonatomic) NSTimer *updateTimer;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self createWindow];
    [self initializeLidSensor];
    [self startUpdatingDisplay];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self.updateTimer invalidate];
    [self.lidSensor stopLidAngleUpdates];
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

- (void)createWindow {
    // Create the main window
    NSRect windowFrame = NSMakeRect(100, 100, 400, 300);
    self.window = [[NSWindow alloc] initWithContentRect:windowFrame
                                              styleMask:NSWindowStyleMaskTitled | 
                                                       NSWindowStyleMaskClosable | 
                                                       NSWindowStyleMaskMiniaturizable
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
    
    [self.window setTitle:@"MacBook Lid Angle Sensor"];
    [self.window makeKeyAndOrderFront:nil];
    [self.window center];
    
    // Create the content view
    NSView *contentView = [[NSView alloc] initWithFrame:windowFrame];
    [self.window setContentView:contentView];
    
    // Create title label
    NSTextField *titleLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(50, 220, 300, 40)];
    [titleLabel setStringValue:@"MacBook Lid Angle Sensor"];
    [titleLabel setFont:[NSFont boldSystemFontOfSize:18]];
    [titleLabel setBezeled:NO];
    [titleLabel setDrawsBackground:NO];
    [titleLabel setEditable:NO];
    [titleLabel setSelectable:NO];
    [titleLabel setAlignment:NSTextAlignmentCenter];
    [contentView addSubview:titleLabel];
    
    // Create angle display label
    self.angleLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(50, 150, 300, 50)];
    [self.angleLabel setStringValue:@"Initializing..."];
    [self.angleLabel setFont:[NSFont monospacedSystemFontOfSize:24 weight:NSFontWeightMedium]];
    [self.angleLabel setBezeled:NO];
    [self.angleLabel setDrawsBackground:NO];
    [self.angleLabel setEditable:NO];
    [self.angleLabel setSelectable:NO];
    [self.angleLabel setAlignment:NSTextAlignmentCenter];
    [self.angleLabel setTextColor:[NSColor systemBlueColor]];
    [contentView addSubview:self.angleLabel];
    
    // Create status label
    self.statusLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(50, 100, 300, 30)];
    [self.statusLabel setStringValue:@"Detecting sensor..."];
    [self.statusLabel setFont:[NSFont systemFontOfSize:14]];
    [self.statusLabel setBezeled:NO];
    [self.statusLabel setDrawsBackground:NO];
    [self.statusLabel setEditable:NO];
    [self.statusLabel setSelectable:NO];
    [self.statusLabel setAlignment:NSTextAlignmentCenter];
    [self.statusLabel setTextColor:[NSColor secondaryLabelColor]];
    [contentView addSubview:self.statusLabel];
    
    // Create info label
    NSTextField *infoLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(50, 30, 300, 60)];
    [infoLabel setStringValue:@"This app reads the MacBook's internal lid angle sensor.\n0° = Closed, ~180° = Fully Open"];
    [infoLabel setFont:[NSFont systemFontOfSize:12]];
    [infoLabel setBezeled:NO];
    [infoLabel setDrawsBackground:NO];
    [infoLabel setEditable:NO];
    [infoLabel setSelectable:NO];
    [infoLabel setAlignment:NSTextAlignmentCenter];
    [infoLabel setTextColor:[NSColor tertiaryLabelColor]];
    [contentView addSubview:infoLabel];
}

- (void)initializeLidSensor {
    self.lidSensor = [[LidAngleSensor alloc] init];
    
    if (self.lidSensor.isAvailable) {
        [self.statusLabel setStringValue:@"Sensor detected - Reading angle..."];
        [self.statusLabel setTextColor:[NSColor systemGreenColor]];
    } else {
        [self.statusLabel setStringValue:@"Lid angle sensor not available on this device"];
        [self.statusLabel setTextColor:[NSColor systemRedColor]];
        [self.angleLabel setStringValue:@"Not Available"];
        [self.angleLabel setTextColor:[NSColor systemRedColor]];
    }
}

- (void)startUpdatingDisplay {
    // Update the display every 100ms for smooth real-time updates
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                        target:self
                                                      selector:@selector(updateAngleDisplay)
                                                      userInfo:nil
                                                       repeats:YES];
}

- (void)updateAngleDisplay {
    if (!self.lidSensor.isAvailable) {
        return;
    }
    
    double angle = [self.lidSensor lidAngle];
    
    if (angle == -2.0) {
        [self.angleLabel setStringValue:@"Read Error"];
        [self.angleLabel setTextColor:[NSColor systemOrangeColor]];
        [self.statusLabel setStringValue:@"Failed to read sensor data"];
        [self.statusLabel setTextColor:[NSColor systemOrangeColor]];
    } else {
        [self.angleLabel setStringValue:[NSString stringWithFormat:@"%.1f°", angle]];
        [self.angleLabel setTextColor:[NSColor systemBlueColor]];
        
        // Provide contextual status based on angle
        NSString *status;
        if (angle < 5.0) {
            status = @"Lid is closed";
        } else if (angle < 45.0) {
            status = @"Lid slightly open";
        } else if (angle < 90.0) {
            status = @"Lid partially open";
        } else if (angle < 135.0) {
            status = @"Lid mostly open";
        } else {
            status = @"Lid fully open";
        }
        
        [self.statusLabel setStringValue:status];
        [self.statusLabel setTextColor:[NSColor secondaryLabelColor]];
    }
}

@end
