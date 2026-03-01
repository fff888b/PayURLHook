#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static NSString *const kLogDirectory = @"/var/mobile/Documents/PayURLHook";
static NSString *const kLogFile = @"/var/mobile/Documents/PayURLHook/pay_urls.log";
static NSString *const kAllURLFile = @"/var/mobile/Documents/PayURLHook/all_urls.log";

static void ensureDirectory(void) {
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:kLogDirectory]) {
        NSDictionary *attrs = @{NSFilePosixPermissions: @0777};
        [fm createDirectoryAtPath:kLogDirectory
      withIntermediateDirectories:YES
                       attributes:attrs
                            error:nil];
    }
}

static void appendToFile(NSString *path, NSString *text) {
    ensureDirectory();
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:path]) {
        NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
        [fh seekToEndOfFile];
        [fh writeData:[text dataUsingEncoding:NSUTF8StringEncoding]];
        [fh closeFile];
    } else {
        [text writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}

static BOOL isPaymentURL(NSURL *url) {
    NSString *scheme = [url.scheme lowercaseString];
    if ([scheme isEqualToString:@"weixin"] || 
        [scheme isEqualToString:@"wechat"] ||
        [scheme hasPrefix:@"alipay"] ||
        [scheme isEqualToString:@"uppaysdk"] ||
        [scheme isEqualToString:@"uppaywallet"] ||
        [scheme isEqualToString:@"platformapi"]) {
        return YES;
    }
    return NO;
}

static void logURL(NSURL *url, NSString *source) {
    @try {
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        [fmt setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString *ts = [fmt stringFromDate:[NSDate date]];

        NSString *entry = [NSString stringWithFormat:@"[%@] [%@] %@\n", ts, source, url.absoluteString];
        appendToFile(kAllURLFile, entry);

        if (isPaymentURL(url)) {
            NSString *scheme = [url.scheme lowercaseString];
            NSString *payType = @"Unknown";
            if ([scheme isEqualToString:@"weixin"] || [scheme isEqualToString:@"wechat"]) {
                payType = @"WeChat";
            } else if ([scheme hasPrefix:@"alipay"]) {
                payType = @"Alipay";
            } else if ([scheme isEqualToString:@"uppaysdk"] || [scheme isEqualToString:@"uppaywallet"]) {
                payType = @"UnionPay";
            }

            NSString *payEntry = [NSString stringWithFormat:
                @"=====================================\n"
                @"[%@] %@ via %@\n"
                @"URL: %@\n"
                @"=====================================\n\n",
                ts, payType, source, url.absoluteString];
            appendToFile(kLogFile, payEntry);

            UIPasteboard *pb = [UIPasteboard generalPasteboard];
            pb.string = url.absoluteString;
        }

        NSLog(@"[PayURLHook] [%@] URL: %@", source, url.absoluteString);
    } @catch (NSException *e) {
        NSLog(@"[PayURLHook] Error: %@", e);
    }
}

// Hook UIApplication openURL (works in SpringBoard)
%hook UIApplication

- (BOOL)openURL:(NSURL *)url {
    if (url) logURL(url, @"openURL");
    return %orig;
}

- (void)openURL:(NSURL *)url options:(NSDictionary *)options completionHandler:(void (^)(BOOL success))completion {
    if (url) logURL(url, @"openURL:options");
    %orig;
}

%end

// Hook LSApplicationWorkspace (SpringBoard uses this to open URLs)
%hook LSApplicationWorkspace

- (BOOL)openURL:(NSURL *)url {
    if (url) logURL(url, @"LSWorkspace.openURL");
    return %orig;
}

- (BOOL)openSensitiveURL:(NSURL *)url withOptions:(id)options {
    if (url) logURL(url, @"LSWorkspace.openSensitiveURL");
    return %orig;
}

- (BOOL)openURL:(NSURL *)url withOptions:(id)options {
    if (url) logURL(url, @"LSWorkspace.openURL:options");
    return %orig;
}

- (BOOL)openSensitiveURL:(NSURL *)url withOptions:(id)options error:(NSError **)error {
    if (url) logURL(url, @"LSWorkspace.openSensitiveURL:error");
    return %orig;
}

%end

// Hook SBMainWorkspace (SpringBoard's main workspace)
%hook SBMainWorkspace

- (void)openURL:(NSURL *)url {
    if (url) logURL(url, @"SBMainWorkspace.openURL");
    %orig;
}

%end

// Hook FBSOpenApplicationService for app-to-app URL forwarding
%hook FBSOpenApplicationService

- (void)openApplication:(NSString *)bundleID withOptions:(id)options completion:(id)completion {
    NSLog(@"[PayURLHook] FBSOpen: %@ opts: %@", bundleID, options);
    appendToFile(kAllURLFile, [NSString stringWithFormat:@"[FBSOpen] app=%@ opts=%@\n", bundleID, options]);
    %orig;
}

%end

// Hook SBApplication openURL
%hook SBApplication

- (void)openURL:(NSURL *)url {
    if (url) logURL(url, @"SBApplication.openURL");
    %orig;
}

%end


%ctor {
    @autoreleasepool {
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier] ?: @"unknown";
        NSLog(@"[PayURLHook] Loaded in %@", bundleID);

        ensureDirectory();
        NSString *markerFile = @"/var/mobile/Documents/PayURLHook/loaded.txt";
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        [fmt setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString *ts = [fmt stringFromDate:[NSDate date]];
        NSString *entry = [NSString stringWithFormat:@"[%@] Loaded in %@\n", ts, bundleID];
        appendToFile(markerFile, entry);
    }
}
