//
//  MhLobbyViewController.m
//  MHLive
//
//  Created by Mars on 18/11/2016.
//  Copyright © 2016 Mars. All rights reserved.
//

#import "MhLobbyViewController.h"
#import "MhBroadcastRoomViewController.h"

@interface MhLobbyViewController ()

@end

@implementation MhLobbyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.titleView = ({
        UILabel *titleView = [[UILabel alloc] init];
        titleView.text = @"大厅";
        [titleView sizeToFit];
        titleView;
    });
    
    self.navigationItem.rightBarButtonItem = ({
        UIBarButtonItem *button = [[UIBarButtonItem alloc] init];
        button.title = @"直播";
        button.target = self;
        button.action = @selector(_onPressedBeginBroadcastButton:);
        button;
    });
    
}

-(void) _onPressedBeginBroadcastButton:(id)sender
{
    MhBroadcastRoomViewController *viewController = [[MhBroadcastRoomViewController alloc] init];
    [self.navigationController pushViewController:viewController animated:YES];
}

@end
