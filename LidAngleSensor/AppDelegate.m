//
//  AppDelegate.m
//  LidAngleSensor
//
//  Created by Sam on 2025-09-06.
//

#import "AppDelegate.h"
#import "LidAngleSensor.h"
#import "CreakAudioEngine.h"
#import "NSLabel.h"

@interface AppDelegate ()
@property (strong, nonatomic) LidAngleSensor *lidSensor;
@property (strong, nonatomic) CreakAudioEngine *audioEngine;
@property (strong, nonatomic) NSLabel *angleLabel;
@property (strong, nonatomic) NSLabel *statusLabel;
@property (strong, nonatomic) NSLabel *velocityLabel;
@property (strong, nonatomic) NSLabel *audioStatusLabel;
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
    
    [self.window setTitle:@"MacBook Lid Angle Sensor"];
    [self.window makeKeyAndOrderFront:nil];
    [self.window center];
    
    // Create the content view
    NSView *contentView = [[NSView alloc] initWithFrame:windowFrame];
    [self.window setContentView:contentView];
    
    // Create angle display label with tabular numbers (larger, light font)
    self.angleLabel = [[NSLabel alloc] init];
    [self.angleLabel setStringValue:@"Initializing..."];
    [self.angleLabel setFont:[NSFont monospacedDigitSystemFontOfSize:48 weight:NSFontWeightLight]];
    [self.angleLabel setAlignment:NSTextAlignmentCenter];
    [self.angleLabel setTextColor:[NSColor systemBlueColor]];
    [contentView addSubview:self.angleLabel];
    
    // Create velocity display label with tabular numbers
    self.velocityLabel = [[NSLabel alloc] init];
    [self.velocityLabel setStringValue:@"Velocity: 00 deg/s"];
    [self.velocityLabel setFont:[NSFont monospacedDigitSystemFontOfSize:14 weight:NSFontWeightRegular]];
    [self.velocityLabel setAlignment:NSTextAlignmentCenter];
    [contentView addSubview:self.velocityLabel];
    
    // Create status label
    self.statusLabel = [[NSLabel alloc] init];
    [self.statusLabel setStringValue:@"Detecting sensor..."];
    [self.statusLabel setFont:[NSFont systemFontOfSize:14]];
    [self.statusLabel setAlignment:NSTextAlignmentCenter];
    [self.statusLabel setTextColor:[NSColor secondaryLabelColor]];
    [contentView addSubview:self.statusLabel];
    
    // Create audio toggle button
    self.audioToggleButton = [[NSButton alloc] init];
    [self.audioToggleButton setTitle:@"Start Audio"];
    [self.audioToggleButton setBezelStyle:NSBezelStyleRounded];
    [self.audioToggleButton setTarget:self];
    [self.audioToggleButton setAction:@selector(toggleAudio:)];
    [self.audioToggleButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [contentView addSubview:self.audioToggleButton];
    
    // Create audio status label
    self.audioStatusLabel = [[NSLabel alloc] init];
    [self.audioStatusLabel setStringValue:@""];
    [self.audioStatusLabel setFont:[NSFont systemFontOfSize:14]];
    [self.audioStatusLabel setAlignment:NSTextAlignmentCenter];
    [self.audioStatusLabel setTextColor:[NSColor secondaryLabelColor]];
    [contentView addSubview:self.audioStatusLabel];
    
    // Set up auto layout constraints
    [NSLayoutConstraint activateConstraints:@[
        // Angle label (main display, now at top)
        [self.angleLabel.topAnchor constraintEqualToAnchor:contentView.topAnchor constant:40],
        [self.angleLabel.centerXAnchor constraintEqualToAnchor:contentView.centerXAnchor],
        [self.angleLabel.widthAnchor constraintLessThanOrEqualToAnchor:contentView.widthAnchor constant:-40],
        
        // Velocity label
        [self.velocityLabel.topAnchor constraintEqualToAnchor:self.angleLabel.bottomAnchor constant:15],
        [self.velocityLabel.centerXAnchor constraintEqualToAnchor:contentView.centerXAnchor],
        [self.velocityLabel.widthAnchor constraintLessThanOrEqualToAnchor:contentView.widthAnchor constant:-40],
        
        // Status label
        [self.statusLabel.topAnchor constraintEqualToAnchor:self.velocityLabel.bottomAnchor constant:15],
        [self.statusLabel.centerXAnchor constraintEqualToAnchor:contentView.centerXAnchor],
        [self.statusLabel.widthAnchor constraintLessThanOrEqualToAnchor:contentView.widthAnchor constant:-40],
        
        // Audio toggle button
        [self.audioToggleButton.topAnchor constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:25],
        [self.audioToggleButton.centerXAnchor constraintEqualToAnchor:contentView.centerXAnchor],
        [self.audioToggleButton.widthAnchor constraintEqualToConstant:120],
        [self.audioToggleButton.heightAnchor constraintEqualToConstant:32],
        
        // Audio status label
        [self.audioStatusLabel.topAnchor constraintEqualToAnchor:self.audioToggleButton.bottomAnchor constant:15],
        [self.audioStatusLabel.centerXAnchor constraintEqualToAnchor:contentView.centerXAnchor],
        [self.audioStatusLabel.widthAnchor constraintLessThanOrEqualToAnchor:contentView.widthAnchor constant:-40],
        [self.audioStatusLabel.bottomAnchor constraintLessThanOrEqualToAnchor:contentView.bottomAnchor constant:-20]
    ]];
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
        [self.audioStatusLabel setStringValue:@""];
    } else {
        [self.audioStatusLabel setStringValue:@"Audio initialization failed"];
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
        [self.audioStatusLabel setStringValue:@""];
    } else {
        [self.audioEngine startEngine];
        [self.audioToggleButton setTitle:@"Stop Audio"];
        [self.audioStatusLabel setStringValue:@""];
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
            
            // Update velocity display with leading zero and whole numbers
            double velocity = self.audioEngine.currentVelocity;
            int roundedVelocity = (int)round(velocity);
            if (roundedVelocity < 100) {
                [self.velocityLabel setStringValue:[NSString stringWithFormat:@"Velocity: %02d deg/s", roundedVelocity]];
            } else {
                [self.velocityLabel setStringValue:[NSString stringWithFormat:@"Velocity: %d deg/s", roundedVelocity]];
            }
            
            // Keep velocity label color consistent
            
            // Show audio parameters when running
            if (self.audioEngine.isEngineRunning) {
                double gain = self.audioEngine.currentGain;
                double rate = self.audioEngine.currentRate;
                [self.audioStatusLabel setStringValue:[NSString stringWithFormat:@"Gain: %.2f, Rate: %.2f", gain, rate]];
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
