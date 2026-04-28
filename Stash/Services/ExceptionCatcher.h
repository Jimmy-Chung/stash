#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBJCExceptionCatcher : NSObject
+ (BOOL)tryBlock:(void (^)(void))block error:(__autoreleasing NSError *_Nullable *_Nullable)error;
@end

NS_ASSUME_NONNULL_END
