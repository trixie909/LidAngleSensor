//
//  AppDelegate.m
//  LidAngleSensor
//
//  Created by Sam on 2025-09-06.
//

#import "AppDelegate.h"
#import "LidAngleSensor.h"
#import "CreakAudioEngine.h"

@interface AppDelegate ()
@property (strong, nonatomic) LidAngleSensor *lidSensor;
@property (strong, nonatomic) CreakAudioEngine *audioEngine;
@property (strong, nonatomic) NSTextField *angleLabel;
@property (strong, nonatomic) NSTextField *statusLabel;
@property (strong, nonatomic) NSTextField *velocityLabel;
@property (strong, nonatomic) NSTextField *audioStatusLabel;
@property (strong, nonatomic) NSButton *audioToggleButton;
@property (strong, nonatomic) NSTimer *updateTimer;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self createWindow];
    [self initializeLidSensor];
    [self initializeAudioEngine];
    [self startUpdatingDisplay];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self.updateTimer invalidate];
    [self.lidSensor stopLidAngleUpdates];
    [self.audioEngine stopEngine];
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

- (void)createWindow {
    // Create the main window (taller to accommodate audio controls)
    NSRect windowFrame = NSMakeRect(100, 100, 450, 420);
    self.window = [[NSWindow alloc] initWithContentRect:windowFrame
                                              styleMask:NSWindowStyleMaskTitled | 
                                                       NSWindowStyleMaskClosable | 
                                                       NSWindowStyleMaskMiniaturizable
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
    
    [self.window setTitle:@"MacBook Lid Creak Sensor"];
    [self.window makeKeyAndOrderFront:nil];
    [self.window center];
    
    // Create the content view
    NSView *contentView = [[NSView alloc] initWithFrame:windowFrame];
    [self.window setContentView:contentView];
    
    // Create title label
    NSTextField *titleLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(50, 360, 350, 40)];
    [titleLabel setStringValue:@"MacBook Lid Creak Sensor"];
    [titleLabel setFont:[NSFont boldSystemFontOfSize:18]];
    [titleLabel setBezeled:NO];
    [titleLabel setDrawsBackground:NO];
    [titleLabel setEditable:NO];
    [titleLabel setSelectable:NO];
    [titleLabel setAlignment:NSTextAlignmentCenter];
    [contentView addSubview:titleLabel];
    
    // Create angle display label
    self.angleLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(50, 280, 350, 40)];
    [self.angleLabel setStringValue:@"Initializing..."];
    [self.angleLabel setFont:[NSFont monospacedSystemFontOfSize:20 weight:NSFontWeightMedium]];
    [self.angleLabel setBezeled:NO];
    [self.angleLabel setDrawsBackground:NO];
    [self.angleLabel setEditable:NO];
    [self.angleLabel setSelectable:NO];
    [self.angleLabel setAlignment:NSTextAlignmentCenter];
    [self.angleLabel setTextColor:[NSColor systemBlueColor]];
    [contentView addSubview:self.angleLabel];
    
    // Create velocity display label
    self.velocityLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(50, 240, 350, 30)];
    [self.velocityLabel setStringValue:@"Velocity: 0.0 deg/s"];
    [self.velocityLabel setFont:[NSFont monospacedSystemFontOfSize:14 weight:NSFontWeightRegular]];
    [self.velocityLabel setBezeled:NO];
    [self.velocityLabel setDrawsBackground:NO];
    [self.velocityLabel setEditable:NO];
    [self.velocityLabel setSelectable:NO];
    [self.velocityLabel setAlignment:NSTextAlignmentCenter];
    [self.velocityLabel setTextColor:[NSColor systemGreenColor]];
    [contentView addSubview:self.velocityLabel];
    
    // Create status label
    self.statusLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(50, 200, 350, 30)];
    [self.statusLabel setStringValue:@"Detecting sensor..."];
    [self.statusLabel setFont:[NSFont systemFontOfSize:14]];
    [self.statusLabel setBezeled:NO];
    [self.statusLabel setDrawsBackground:NO];
    [self.statusLabel setEditable:NO];
    [self.statusLabel setSelectable:NO];
    [self.statusLabel setAlignment:NSTextAlignmentCenter];
    [self.statusLabel setTextColor:[NSColor secondaryLabelColor]];
    [contentView addSubview:self.statusLabel];
    
    // Create audio toggle button
    self.audioToggleButton = [[NSButton alloc] initWithFrame:NSMakeRect(175, 150, 100, 30)];
    [self.audioToggleButton setTitle:@"Start Audio"];
    [self.audioToggleButton setBezelStyle:NSBezelStyleRounded];
    [self.audioToggleButton setTarget:self];
    [self.audioToggleButton setAction:@selector(toggleAudio:)];
    [contentView addSubview:self.audioToggleButton];
    
    // Create audio status label
    self.audioStatusLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(50, 110, 350, 30)];
    [self.audioStatusLabel setStringValue:@"Audio: Stopped"];
    [self.audioStatusLabel setFont:[NSFont systemFontOfSize:14]];
    [self.audioStatusLabel setBezeled:NO];
    [self.audioStatusLabel setDrawsBackground:NO];
    [self.audioStatusLabel setEditable:NO];
    [self.audioStatusLabel setSelectable:NO];
    [self.audioStatusLabel setAlignment:NSTextAlignmentCenter];
    [self.audioStatusLabel setTextColor:[NSColor secondaryLabelColor]];
    [contentView addSubview:self.audioStatusLabel];
    
    // Create info label
    NSTextField *infoLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(50, 30, 350, 60)];
    [infoLabel setStringValue:@"Real-time door creak audio responds to lid movement.\nSlow movement = louder creak, fast movement = silent."];
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

- (void)initializeAudioEngine {
    self.audioEngine = [[CreakAudioEngine alloc] init];
    
    if (self.audioEngine) {
        [self.audioStatusLabel setStringValue:@"Audio: Ready (stopped)"];
        [self.audioStatusLabel setTextColor:[NSColor systemOrangeColor]];
    } else {
        [self.audioStatusLabel setStringValue:@"Audio: Failed to initialize"];
        [self.audioStatusLabel setTextColor:[NSColor systemRedColor]];
        [self.audioToggleButton setEnabled:NO];
    }
}

- (IBAction)toggleAudio:(id)sender {
    if (!self.audioEngine) {
        return;
    }
    
    if (self.audioEngine.isEngineRunning) {
        [self.audioEngine stopEngine];
        [self.audioToggleButton setTitle:@"Start Audio"];
        [self.audioStatusLabel setStringValue:@"Audio: Stopped"];
        [self.audioStatusLabel setTextColor:[NSColor systemOrangeColor]];
    } else {
        [self.audioEngine startEngine];
        [self.audioToggleButton setTitle:@"Stop Audio"];
        [self.audioStatusLabel setStringValue:@"Audio: Running"];
        [self.audioStatusLabel setTextColor:[NSColor systemGreenColor]];
    }
}

- (void)startUpdatingDisplay {
    // Update every 16ms (60Hz) for smooth real-time audio and display updates
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.016
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
        
        // Update audio engine with new angle
        if (self.audioEngine) {
            [self.audioEngine updateWithLidAngle:angle];
            
            // Update velocity display
            double velocity = self.audioEngine.currentVelocity;
            [self.velocityLabel setStringValue:[NSString stringWithFormat:@"Velocity: %.1f deg/s", velocity]];
            
            // Color velocity based on magnitude
            double absVelocity = fabs(velocity);
            if (absVelocity < 0.3) {
                [self.velocityLabel setTextColor:[NSColor systemGrayColor]];
            } else if (absVelocity < 2.0) {
                [self.velocityLabel setTextColor:[NSColor systemGreenColor]];
            } else if (absVelocity < 10.0) {
                [self.velocityLabel setTextColor:[NSColor systemYellowColor]];
            } else {
                [self.velocityLabel setTextColor:[NSColor systemRedColor]];
            }
            
            // Update audio status with gain/rate info if running
            if (self.audioEngine.isEngineRunning) {
                double gain = self.audioEngine.currentGain;
                double rate = self.audioEngine.currentRate;
                [self.audioStatusLabel setStringValue:[NSString stringWithFormat:@"Audio: Running (Gain: %.2f, Rate: %.2f)", gain, rate]];
            }
        }
        
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
