#import "IconThemes.h"
#import "Preferences.h"

@interface SXIAlignedTableViewCell : UITableViewCell {
}
@end

#define MARGIN 5
#define kThemesDirectory @"/Library/StackXI/"

@implementation SXITheme

@synthesize name, image;

+ (UIImage*)mergeImage:(UIImage*)first withImage:(UIImage*)second
{
    CGImageRef firstImageRef = first.CGImage;
    CGFloat firstWidth = CGImageGetWidth(firstImageRef);
    CGFloat firstHeight = CGImageGetHeight(firstImageRef);
    
    CGImageRef secondImageRef = second.CGImage;
    CGFloat secondWidth = CGImageGetWidth(secondImageRef);
    CGFloat secondHeight = CGImageGetHeight(secondImageRef);
    
    CGSize mergedSize = CGSizeMake(firstWidth + secondWidth + 5, MAX(firstHeight, secondHeight));
    UIGraphicsBeginImageContext(mergedSize);
    
    [first drawInRect:CGRectMake(0, 0, firstWidth, firstHeight)];
    [second drawInRect:CGRectMake(firstWidth + 5, 0, secondWidth, secondHeight)]; 
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (SXITheme*)themeWithPath:(NSString*)path {
    return [[SXITheme alloc] initWithPath:path];
}

- (id)initWithPath:(NSString*)path {
    BOOL isDir = NO;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
    
    if (!exists || !isDir) {
        [self release];
        return nil;
    }
    
    if ((self = [super init])) {
        self.name = [[path lastPathComponent] stringByDeletingPathExtension];
        UIImage *clearAll = [UIImage imageWithContentsOfFile:[path stringByAppendingPathComponent:@"SXIClearAll.png"]];
        UIImage *collapse = [UIImage imageWithContentsOfFile:[path stringByAppendingPathComponent:@"SXICollapse.png"]];

        self.image = [SXITheme mergeImage:collapse withImage:clearAll];
        if (!self.image) {
            [self release];
            return nil;
        }
    }
    return self;
}

- (void)dealloc {
    self.name = nil;
    self.image = nil;
    [super dealloc];
}

@end

@implementation SXIAlignedTableViewCell
- (void) layoutSubviews {
    [super layoutSubviews];
    CGRect cvf = self.contentView.frame;
      CGFloat width = 80;
    self.imageView.frame = CGRectMake(MARGIN,
                                      0.0,
                                      width,
                                      cvf.size.height-1);
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;

    CGRect frame = CGRectMake(width + MARGIN*2,
                              self.textLabel.frame.origin.y,
                              cvf.size.width - width - 3*MARGIN,
                              self.textLabel.frame.size.height);
    self.textLabel.frame = frame;

    frame = CGRectMake(width + MARGIN*2,
                       self.detailTextLabel.frame.origin.y,
                       cvf.size.width - width - 3*MARGIN,
                       self.detailTextLabel.frame.size.height);   
    self.detailTextLabel.frame = frame;
}
@end

@implementation SXIIconThemesListController

@synthesize themes = _themes;

- (id)initForContentSize:(CGSize)size {
    self = [super init];

    if (self) {
        self.themes = [[NSMutableArray alloc] initWithCapacity:100];
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height) style:UITableViewStyleGrouped];
        [_tableView setDataSource:self];
        [_tableView setDelegate:self];
        [_tableView setEditing:NO];
        [_tableView setAllowsSelection:YES];
        [_tableView setAllowsMultipleSelection:NO];
        
        if ([self respondsToSelector:@selector(setView:)])
            [self performSelectorOnMainThread:@selector(setView:) withObject:_tableView waitUntilDone:YES];        
    }

    return self;
}

- (void)addThemesFromDirectory:(NSString *)directory {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *diskThemes = [manager contentsOfDirectoryAtPath:directory error:nil];
    
    for (NSString *dirName in diskThemes) {
        NSString *path = [kThemesDirectory stringByAppendingPathComponent:dirName];
        SXITheme *theme = [SXITheme themeWithPath:path];
        
        if (theme) {
            [self.themes addObject:theme];
        }
    }
}

- (void)refreshList {
    self.themes = [[NSMutableArray alloc] initWithCapacity:100];
    [self addThemesFromDirectory: kThemesDirectory];
            
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    [self.themes sortUsingDescriptors:[NSArray arrayWithObject:descriptor]];
    [descriptor release];
    
    HBPreferences *file = [[HBPreferences alloc] initWithIdentifier:@"io.ominousness.stackxi"];
    selectedTheme = [([file objectForKey:@"IconTheme"] ?: @"Default") stringValue];
}

- (id)view {
    return _tableView;
}

- (void)viewWillAppear:(BOOL)animated {
    [self refreshList];
}

- (NSArray *)currentThemes {
    return self.themes;
}

- (void)dealloc { 
    self.themes = nil;
    [super dealloc];
}

- (NSString*)navigationTitle {
    return @"Themes";
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.currentThemes.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ThemeCell"];
    if (!cell) {
        cell = [[SXIAlignedTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ThemeCell"];
    }
    
    SXITheme *theme = [self.currentThemes objectAtIndex:indexPath.row];
    cell.textLabel.text = theme.name;    
    cell.imageView.image = theme.image;
    cell.imageView.highlightedImage = theme.image;
    cell.selected = NO;

    if ([theme.name isEqualToString: selectedTheme] && !tableView.isEditing) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else if (!tableView.isEditing) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    UITableViewCell *old = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow: [[self.currentThemes valueForKey:@"name"] indexOfObject: selectedTheme] inSection: 0]];
    if (old) old.accessoryType = UITableViewCellAccessoryNone;

    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;

    SXITheme *theme = (SXITheme*)[self.currentThemes objectAtIndex:indexPath.row];
    selectedTheme = theme.name;

    HBPreferences *file = [[HBPreferences alloc] initWithIdentifier:@"io.ominousness.stackxi"];
    [file setObject:selectedTheme forKey:@"IconTheme"];

    SXIPrefsListController *parent = (SXIPrefsListController *)self.parentController;
    [parent setThemeName:selectedTheme];
}

@end
