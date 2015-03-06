//
//  ViewController.h
//  Donna
//
//  Created by Glavin Wiechert on 2015-03-05.
//  Copyright (c) 2015 Donna. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <Wit/Wit.h>

@interface ViewController : UIViewController <WitDelegate, UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet WITMicButton *witButton;
@property (strong, nonatomic) IBOutlet UILabel *intentLabel;
@property (strong, nonatomic) IBOutlet UILabel *queryLabel;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UILabel *listeningLabel;

@property (strong, nonatomic) NSMutableArray *torrents;

@end

