//
//  ViewController.m
//  WZMediaDemo
//
//  Created by Worthy on 16/8/17.
//  Copyright © 2016年 Worthy. All rights reserved.
//

#import "ViewController.h"
#import "WZTableViewCell.h"


@interface ViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, assign) NSInteger demoCount;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.demoCount = 2;
}

- (NSString *)classNameOfViewControllerAtIndex:(NSInteger)index {
    return [NSString stringWithFormat:@"WZDemo%dViewController", (int)index];
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.demoCount;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WZTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"WZTableViewCell"];
    cell.textLabel.text = [self classNameOfViewControllerAtIndex:indexPath.row];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *className = [self classNameOfViewControllerAtIndex:indexPath.row];
    
    Class class = NSClassFromString(className);
    UIViewController *vc = (UIViewController *)[[class alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
