//
//  JDMacros.h
//  corp.bytedance.com
//
//  Created by zuopengliu on 21/1/2018.
//

#ifndef JDMacros_h
#define JDMacros_h

#import <Foundation/Foundation.h>
#import <objc/message.h>


#define JD_STATIC_UNUSED_WARN              __attribute__((unused))
#define JD_TYPE_STRINGIFY(_type)           @(#_type)
#define JD_TYPE_ENCODING_STRINGIFY(_type)  @(@encode(_type))


#pragma mark - string

// remove begin and end whitespace
#define JD_STRING_TRIM(str)            [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
// remove all whitespace
#define JD_STRING_TRIM_ALL(str)        [str stringByReplacingOccurrencesOfString:@"\\s+" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, str.length)]
// convert mutiple whitespace to one whitespace
#define JD_STRING_TRIM_ANY2ONE(str)    [str stringByReplacingOccurrencesOfString:@"\\s+" withString:@" " options:NSRegularExpressionSearch range:NSMakeRange(0, str.length)]

// type check
#define JDIsEmptyString(str)      (!str || ![str isKindOfClass:[NSString class]] || str.length == 0)
#define JDIsEmptyArray(arr)       (!arr || ![arr isKindOfClass:[NSArray class]] || arr.count == 0)
#define JDIsEmptyDictionary(dict) (!dict || ![dict isKindOfClass:[NSDictionary class]] || dict.count == 0)



#pragma mark - log

#define JDAssert(cond, format, ...) \
NSAssert((cond), @"Better [ASSERT]>> %@", [NSString stringWithFormat:(format), ##__VA_ARGS__]);

#define JDCAssert(cond, format, ...) \
NSCAssert((cond), @"Better [ASSERT]>> %@", [NSString stringWithFormat:(format), ##__VA_ARGS__]);

#define JDDebug(format, ...) \
NSLog(@"Better [DEBUG]>> <SEL: %s> <line: %d> %@", __FUNCTION__, __LINE__, [NSString stringWithFormat:(format), ##__VA_ARGS__]);

#define JDInfo(format, ...) \
NSLog(@"Better [INFO]>> <SEL: %s> <line: %d> %@", __FUNCTION__, __LINE__, [NSString stringWithFormat:(format), ##__VA_ARGS__]);

#define JDWarn(format, ...) \
NSLog(@"Better [WARN]>> <SEL: %s> <line: %d> %@", __FUNCTION__, __LINE__, [NSString stringWithFormat:(format), ##__VA_ARGS__]);

#define JDError(format, ...) \
NSLog(@"Better [ERROR]>> <SEL: %s> <line: %d> %@", __FUNCTION__, __LINE__, [NSString stringWithFormat:(format), ##__VA_ARGS__]);

#define JD_BR()    \
printf("\n")


#pragma mark - DEBUG DESCRIPTION

#ifdef DEBUG

#define JD_DEBUG_DESCRIPTION   \
- (NSString *)debugDescription  \
{   \
NSMutableDictionary *dictionary = [NSMutableDictionary dictionary]; \
NSArray *exceptNames = @[@"description"];   \
Class cls = [self class];   \
while (cls != [NSObject class]) {   \
uint count; \
objc_property_t *properties = class_copyPropertyList(cls, &count);  \
for (int i = 0; i < count; i++) {   \
objc_property_t property = properties[i];   \
NSString *name = @(property_getName(property)); \
if (name && [exceptNames containsObject:name]) continue;    \
id value = [self valueForKey:name] ? : @"nil";  \
[dictionary setObject:value forKey:name];   \
}   \
if (properties) free(properties);   \
cls = [cls superclass]; \
}   \
return [NSString stringWithFormat:@"<%@: %p> = \n%@", NSStringFromClass(self.class), self, dictionary]; \
}   \
\
- (NSString *)description   \
{   \
return [self debugDescription]; \
}   \

#else

#define JD_DEBUG_DESCRIPTION

#endif


#pragma mark - warnings

#define JD_IGNORE_STRICT_PROTOTYPE_BEGIN  \
#pragma clang diagnostic push   \
#pragma clang diagnostic ignored "-Wstrict-prototypes"

#define JD_IGNORE_STRICT_PROTOTYPE_END \
#pragma clang diagnostic pop


#endif /* JDMacros_h */
