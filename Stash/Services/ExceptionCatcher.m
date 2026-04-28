#import "ExceptionCatcher.h"

@implementation OBJCExceptionCatcher

+ (BOOL)tryBlock:(void (^)(void))block error:(__autoreleasing NSError *_Nullable *_Nullable)error {
    @try {
        block();
        return YES;
    }
    @catch (NSException *exception) {
        if (error) {
            *error = [NSError errorWithDomain:@"OBJCExceptionCatcher"
                                         code:1
                                     userInfo:@{@"name": exception.name ?: @"",
                                                 @"reason": exception.reason ?: @""}];
        }
        return NO;
    }
}

@end
