#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <CepheiPrefs/HBListController.h>
#import <CepheiPrefs/HBAppearanceSettings.h>
#import <Cephei/HBPreferences.h>
#import <spawn.h>

@interface SXIIconThemesListController : PSViewController <UITableViewDelegate,UITableViewDataSource> {
    UITableView *_tableView;
    NSMutableArray *_themes;
    NSString *selectedTheme;
}

@property (nonatomic, retain) NSMutableArray *themes;

@end

@interface SXITheme : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, retain) UIImage *image;
+ (UIImage*)mergeImage:(UIImage*)first withImage:(UIImage*)second;
+ (SXITheme *)themeWithPath:(NSString *)path;
- (id)initWithPath:(NSString *)path;

@end