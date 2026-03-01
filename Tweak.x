#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static NSString *const kLogDirectory = @"/var/mobile/Documents/PayURLHook";
static NSString *const kLogFile = @"/var/mobile/Documents/PayURLHook/pay_urls.log";

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

static void savePaymentURL(NSURL *url) {
    @try {
        NSFileManager *fm = [NSFileManager defaultManager];
        if (![fm fileExistsAtPath:kLogDirectory]) {
            [fm createDirectoryAtPath:kLogDirectory
          withIntermediateDirectories:YES
                           attributes:nil
                                error:nil];
        }

        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        [fmt setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString *timestamp = [fmt stringFromDate:[NSDate date]];

        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier] ?: @"unknown";
        NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]
                            ?: [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]
                            ?: @"unknown";

        NSString *scheme = [url.scheme lowercaseString];
        NSString *payType = @"Unknown";
        if ([scheme isEqualToString:@"weixin"] || [scheme isEqualToString:@"wechat"]) {
            payType = @"WeChat";
        } else if ([scheme hasPrefix:@"alipay"]) {
            payType = @"Alipay";
        } else if ([scheme isEqualToString:@"uppaysdk"] || [scheme isEqualToString:@"uppaywallet"]) {
            payType = @"UnionPay";
        }

        NSString *entry = [NSString stringWithFormat:
            @"=====================================\n"
            @"[%@] %@\n"
            @"App: %@ (%@)\n"
            @"URL: %@\n"
            @"=====================================\n\n",
            timestamp, payType, appName, bundleID, url.absoluteString];

        if (![fm fileExistsAtPath:kLogFile]) {
            [entry writeToFile:kLogFile atomically:YES encoding:NSUTF8StringEncoding error:nil];
        } else {
            NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:kLogFile];
            [fh seekToEndOfFile];
            [fh writeData:[entry dataUsingEncoding:NSUTF8StringEncoding]];
            [fh closeFile];
        }

        // Copy URL to clipboard
        UIPasteboard *pb = [UIPasteboard generalPasteboard];
        pb.string = url.absoluteString;

        NSLog(@"[PayURLHook] Captured %@ payment URL from %@: %@", payType, bundleID, url.absoluteString);

    } @catch (NSException *e) {
        NSLog(@"[PayURLHook] Error saving URL: %@", e);
    }
}

// iOS 9 and below
%hook UIApplication

- (BOOL)openURL:(NSURL *)url {
    if (url && isPaymentURL(url)) {
        savePaymentURL(url);
    }
    return %orig;
}

// iOS 10+
- (void)openURL:(NSURL *)url options:(NSDictionary *)options completionHandler:(void (^)(BOOL success))completion {
    if (url && isPaymentURL(url)) {
        savePaymentURL(url);
    }
    %orig;
}

%end


%ctor {
    NSLog(@"[PayURLHook] Loaded in %@", [[NSBundle mainBundle] bundleIdentifier]);
}
