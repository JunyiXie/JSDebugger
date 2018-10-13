//
//  NSObject+JDRuntimeIntrospection.h
//  JSDebugger
//
//  Created by JunyiXie on 2/10/2018.
//

#import <Foundation/Foundation.h>
#import <objc/message.h>
NS_ASSUME_NONNULL_BEGIN

@interface NSObject (JDRuntimeIntrospection)

- (NSArray<NSString *> *)jd_logAllProperties;
/// For Test
- (void)Test_JDRuntimeIntrospection;
@end



NS_ASSUME_NONNULL_END
