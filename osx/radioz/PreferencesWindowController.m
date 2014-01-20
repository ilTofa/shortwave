//
//  PreferencesWindowController.m
//  radiox
//
//  Created by Giacomo Tufano on 07/12/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "PreferencesWindowController.h"

@interface PreferencesWindowController ()

@end

@implementation PreferencesWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    self.sysMenuButton.state = [[NSUserDefaults standardUserDefaults] integerForKey:@"avoidSysMenu"];
}

- (IBAction)useSystemMenu:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setInteger:self.sysMenuButton.state forKey:@"avoidSysMenu"];
    [self.delegate preferencesWindowControllerDidSelect:self];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self.delegate preferencesWindowControllerDidSelect:self];
}

@end
