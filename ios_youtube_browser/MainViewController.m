//
//  MainViewController.m
//  ios_youtube_browser
//
//  Created by Maxim Bilan on 2/9/15.
//  Copyright (c) 2015 Maxim Bilan. All rights reserved.
//

#import "MainViewController.h"
#import "MainMenuTableCell.h"

#import "YouTubeViewController.h"

#import "AFNetworking.h"
#import "YTPlayerView.h"
#import "WaitSpinner.h"

#import <SDWebImage/UIImageView+WebCache.h>

static NSString * const MainMenuTableCellId = @"MainMenuTableCellId";
static NSString * const YouTubeSearchUrl = @"https://www.googleapis.com/youtube/v3/search?part=snippet&q=%@&type=video&videoCaption=closedCaption&key=%@&maxResults=%@";
static NSString * const YouTubeStatsUrl = @"https://www.googleapis.com/youtube/v3/videos?id=%@&part=statistics&key=%@";
static NSString * const YouTubeAppKey = @"AIzaSyCs0lcHGW2oW88FO8FeR8j_hXMc9oCG6p0";
static const NSInteger YouTubeMaxResults = 50;

@interface MainViewController () <UITableViewDelegate, UITableViewDataSource>
{
	NSMutableArray *data;
	
	WaitSpinner *waitSpinner;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *searchTextField;
@property (weak, nonatomic) IBOutlet UIButton *searchButton;

@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	data = [NSMutableArray array];
}

- (void)fetchYoutubeData:(NSString *)searchString
{
	NSString *str = [searchString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSString *url = [NSString stringWithFormat:YouTubeSearchUrl, str, YouTubeAppKey, @(YouTubeMaxResults)];
	AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
	[manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSLog(@"JSON: %@", responseObject);
		NSDictionary *d = (NSDictionary *)responseObject;
		if (d) {
			if ([d valueForKey:@"items"]) {
				NSArray *items = d[@"items"];
				if (items) {
					[data removeAllObjects];
					[data addObjectsFromArray:items];
					[self.tableView reloadData];
				}
			}
		}
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		NSLog(@"Error: %@", error);
	}];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	MainMenuTableCell *cell = (MainMenuTableCell *)[tableView dequeueReusableCellWithIdentifier:MainMenuTableCellId];
	
	NSString *ytVideoId = nil;
	NSString *ytDefaultThumbnail = nil;
	NSString *ytMediumThumbnail = nil;
	NSString *ytHighThumbnail = nil;
	
	NSString *ytTitle = nil;
	NSString *ytDescription = nil;
	NSString *ytChannel = nil;
	NSString *ytPublishedAt = nil;
	
	NSDictionary *object = data[indexPath.row];
	if (object) {
		if ([object valueForKey:@"id"]) {
			NSDictionary *idDict = [object valueForKey:@"id"];
			if (idDict) {
				if ([idDict valueForKey:@"videoId"]) {
					NSString *videoId = idDict[@"videoId"];
					if (videoId && videoId.length > 0) {
						ytVideoId = videoId;
					}
				}
			}
		}
		if ([object valueForKey:@"snippet"]) {
			NSDictionary *snippet = [object valueForKey:@"snippet"];
			if (snippet) {
				if ([snippet valueForKey:@"thumbnails"]) {
					NSDictionary *thumbnails = [snippet valueForKey:@"thumbnails"];
					if (thumbnails) {
						if ([thumbnails valueForKey:@"default"]) {
							NSDictionary *defaultThumbnail = [thumbnails valueForKey:@"default"];
							if (defaultThumbnail) {
								ytDefaultThumbnail = defaultThumbnail[@"url"];
							}
						}
						
						if ([thumbnails valueForKey:@"medium"]) {
							NSDictionary *mediumThumbnail = [thumbnails valueForKey:@"medium"];
							if (mediumThumbnail) {
								ytMediumThumbnail = mediumThumbnail[@"url"];
							}
						}
						
						if ([thumbnails valueForKey:@"high"]) {
							NSDictionary *highThumbnail = [thumbnails valueForKey:@"high"];
							if (highThumbnail) {
								ytHighThumbnail = highThumbnail[@"url"];
							}
						}
					}
				}
				
				if ([snippet valueForKey:@"title"]) {
					ytTitle = snippet[@"title"];
				}
				
				if ([snippet valueForKey:@"description"]) {
					ytDescription = snippet[@"description"];
				}
				
				if ([snippet valueForKey:@"channelTitle"]) {
					ytChannel = snippet[@"channelTitle"];
				}
				
				if ([snippet valueForKey:@"publishedAt"]) {
					ytPublishedAt = snippet[@"publishedAt"];
				}
			}
		}
		
		if (ytTitle) {
			cell.titleLabel.text = ytTitle;
		}
		if (ytDescription) {
			cell.descriptionTextView.text = ytDescription;
		}
		if (ytChannel) {
			cell.channelLabel.text = ytChannel;
		}
		if (ytPublishedAt) {
			cell.dateLabel.text = ytPublishedAt;
		}
		
		[cell.thumbnailImageView sd_setImageWithURL:[NSURL URLWithString:ytMediumThumbnail]];
	}
	
	return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	
}

#pragma mark - Search action

- (IBAction)searchAction:(UIButton *)sender
{
	if (self.searchTextField.text.length > 0) {
		NSString *str = [self.searchTextField.text stringByReplacingOccurrencesOfString:@" " withString:@"+"];
		[self fetchYoutubeData:str];
	}
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
	
	YouTubeViewController *controller = [segue destinationViewController];
	
	NSString *ytVideoId = nil;
	NSString *ytTitle = nil;
	NSDictionary *object = data[indexPath.row];
	if (object) {
		if ([object valueForKey:@"id"]) {
			NSDictionary *idDict = [object valueForKey:@"id"];
			if (idDict) {
				if ([idDict valueForKey:@"videoId"]) {
					NSString *videoId = idDict[@"videoId"];
					if (videoId && videoId.length > 0) {
						ytVideoId = videoId;
					}
				}
			}
		}
		
		if ([object valueForKey:@"snippet"]) {
			NSDictionary *snippet = [object valueForKey:@"snippet"];
			if (snippet) {
				if ([snippet valueForKey:@"title"]) {
					ytTitle = snippet[@"title"];
				}
			}
		}
	}
	
	controller.videoId = ytVideoId;
	controller.navigationItem.title = ytTitle;
}

@end
