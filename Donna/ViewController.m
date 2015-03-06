//
//  ViewController.m
//  Donna
//
//  Created by Glavin Wiechert on 2015-03-05.
//  Copyright (c) 2015 Donna. All rights reserved.
//

#import "ViewController.h"

#import <AFNetworking/AFHTTPRequestOperationManager.h>

@interface ViewController ()

@end

@implementation ViewController {
}

@synthesize witButton;
@synthesize intentLabel;
@synthesize queryLabel;
@synthesize tableView;
@synthesize listeningLabel;
@synthesize serverUrlTextField;

@synthesize torrents;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // set the WitDelegate object
    [Wit sharedInstance].delegate = self;
    [Wit sharedInstance].vadSensitivity = 10.0;
    
    self.torrents = [NSMutableArray array];
    
    self.listeningLabel.text = @"Not Listening.";
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) witDidStartRecording {
    self.listeningLabel.text = @"Listening...";
}

- (void) witDidStopRecording {
    self.listeningLabel.text = @"Not Listening.";
}

- (void)witDidGraspIntent:(NSArray *)outcomes messageId:(NSString *)messageId customData:(id) customData error:(NSError*)e {
    
    self.listeningLabel.text = @"Not Listening.";
    
    if (e) {
        NSLog(@"[Wit] error: %@", [e localizedDescription]);
        return;
    }
    NSDictionary *firstOutcome = [outcomes objectAtIndex:0];
    NSString *intent = [firstOutcome objectForKey:@"intent"];
    NSString *body = [firstOutcome objectForKey:@"_text"];
    
    NSLog(@"Outcomes: %@", outcomes);
    
    intentLabel.text = [NSString stringWithFormat:@"Intent: %@", intent];
    queryLabel.text = [NSString stringWithFormat:@"Query: %@", body];
    
    NSDictionary *entities = (NSDictionary *)[firstOutcome objectForKey:@"entities"];

    if ([intent isEqualToString:@"search_for_torrent"]) {
        NSString *query = (NSString *)[(NSDictionary *)[(NSArray *)[entities objectForKey:@"search_query"] objectAtIndex:0] objectForKey:@"value"];
        [self searchForTorrents:query];
    }
    else if ([intent isEqualToString:@"search_for_season_episode"]) {
        NSString *tvShow = (NSString *)[(NSDictionary *)[(NSArray *)[entities objectForKey:@"tv_show"] objectAtIndex:0] objectForKey:@"value"];
        NSNumber *season = (NSNumber *)[(NSDictionary *)[(NSArray *)[entities objectForKey:@"season"] objectAtIndex:0] objectForKey:@"value"];
        NSNumber *episode = (NSNumber *)[(NSDictionary *)[(NSArray *)[entities objectForKey:@"episode"] objectAtIndex:0] objectForKey:@"value"];
        NSString *query = [NSString stringWithFormat:@"%@ S%02dE%02d", tvShow, season.intValue, episode.intValue];
        [self searchForTorrents:query];
    } else if ([intent isEqualToString:@"download_torrent_selection"]) {
        NSNumber *selection = (NSNumber *)[(NSDictionary *)[(NSArray *)[entities objectForKey:@"selection"] objectAtIndex:0] objectForKey:@"value"];
        NSDictionary *torrent = [torrents objectAtIndex:selection.intValue];
        [self downloadTorrent:torrent];

    }

    
}

- (void) speak:(NSString *)message {
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:message];
    AVSpeechSynthesizer *syn = [[AVSpeechSynthesizer alloc] init];
    [syn speakUtterance:utterance];
}

- (void) searchForTorrents:(NSString *) query {
    
    NSLog(@"Send request to Donna: %@", query);
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *donnaBaseUrl = serverUrlTextField.text;
    NSString *requestUrl = [NSString stringWithFormat:@"%@/api/%@", donnaBaseUrl, @"torrents"];
    NSDictionary *params = @{
                             @"query": query
                             };
    [manager GET:requestUrl parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        torrents = [NSMutableArray arrayWithArray:responseObject];
        [self.tableView reloadData];
        
        NSString *msg = [NSString stringWithFormat:@"I found %d results", [torrents count]];
        [self speak:msg];

//        NSLog(@"JSON: %@", responseObject);
    
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        NSLog(@"Error: %@", error);
        [self speak:@"An error occured trying to search"];
    
    }];
    
    [self speak:@"I'll take a look"];
    
}

- (void) downloadTorrent:(NSDictionary *)torrent {
    
    NSLog(@"Torrent: %@", torrent);
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *donnaBaseUrl = serverUrlTextField.text;
    NSString *requestUrl = [NSString stringWithFormat:@"%@/api/%@", donnaBaseUrl, @"transmission"];
    NSDictionary *params = @{
                             @"url": [torrent objectForKey:@"torrentUrl"]
                             };
    [manager POST:requestUrl parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSLog(@"JSON: %@", responseObject);
        [self speak:@"It's downloading"];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        NSLog(@"Error: %@", error);
        [self speak:@"An error occured trying to download"];
        
    }];
    
    [self speak:@"I'll download that now"];

}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [torrents count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Search Results";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *MyIdentifier = @"TorrentCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault  reuseIdentifier:MyIdentifier];
    }
    NSDictionary *torrent = [torrents objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%d. %@", indexPath.row+1, [torrent objectForKey:@"title"]];
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *torrent = [torrents objectAtIndex:indexPath.row];
    [self downloadTorrent:torrent];
    
}

@end
