//
//  NSObject+JDRuntimeIntrospection.m
//  JSDebugger
//
//  Created by JunyiXie on 2/10/2018.
//

#import "NSObject+JDRuntimeIntrospection.h"
#import <Foundation/Foundation.h>
#import "JDEncoding.h"
#import <objc/runtime.h>
#import "JDFFIContext.h"
#import "JDGenericValue.h"

#import "JDCustomStruct.h"


#include <string>
#include <iostream>

#pragma mark Test



struct Test_jd_logAllProperties_struct2 {
    int a;
    double c;
};
struct Test_jd_logAllProperties_struct1 {
    int a;
//    struct Test_jd_logAllProperties_struct2 b;
    double c;
    int d;
};

@interface Test_jd_logAllProperties : NSObject

//@property (nonatomic, assign) Test_jd_logAllProperties_struct1 struct1;
@property (nonatomic, assign) CGRect struct2;

@end

@implementation Test_jd_logAllProperties

- (instancetype)init {
    if (self = [super init]) {
//        _struct1 = {1,5.2,1};
        _struct2 = {1,2,3,4};
    }
    return self;
}

@end



NSString *typeEncodingToTypeStr(const char *type) {
    if (strncmp(type, @encode(char), 1) == 0) {
        return @"char";
    }
    else if (strncmp(type, @encode(int), 1) == 0) {
        return @"int";
    }
    else if (strncmp(type, @encode(short), 1) == 0) {
        return @"short";
    }
    else if (strncmp(type, @encode(long), 1) == 0) {
        return @"long";
    }
    else if (strncmp(type, @encode(long long), 1) == 0) {
        return @"long long";
    }
    else if (strncmp(type, @encode(unsigned char), 1) == 0) {
        return @"unsigned char";
    }
    else if (strncmp(type, @encode(unsigned int), 1) == 0) {
        return @"unsigned int";
    }
    else if (strncmp(type, @encode(unsigned short), 1) == 0) {
        return @"unsigned short";
    }
    else if (strncmp(type, @encode(unsigned long), 1) == 0) {
        return @"unsigned long";
    }
    else if (strncmp(type, @encode(unsigned long long), 1) == 0) {
        return @"unsigned long long";
    }
    else if (strncmp(type, @encode(float), 1) == 0) {
        return @"float";
    }
    else if (strncmp(type, @encode(double), 1) == 0) {
        return @"double";
    }
    else if (strncmp(type, @encode(bool), 1) == 0) {
        return @"bool";
    }
    else if (strncmp(type, @encode(char *), 1) == 0) {
        return @"char *";
    }
    /// 就不处理 offset了
    else if (strncmp(type, @encode(id), 1) == 0) {
        
    }
    else if (strncmp(type, @encode(Class), 1) == 0) {
        
    }
    // 还有一些类型需要处理..
    
    return @"";
}
using namespace std;
//@import ObjectiveC.runtime;
@interface JDStructVal : NSObject

@property (nonatomic, strong) NSDictionary *dic;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) id type;
@property (nonatomic, strong) NSArray *vars;
@property (nonatomic, assign) BOOL isBasic;
@property (nonatomic, strong) NSMutableArray<JDStructVal *> *struct_ary;
@property (nonatomic, strong) NSString *basic;
- (void)__build_struct:(NSMutableArray*)args;
@end
@implementation JDStructVal

- (NSString *)build {
    NSMutableArray *args = @[].mutableCopy;
    [self __build_struct:args];
    self.name = [NSString stringWithFormat:@"%f", [NSDate timeIntervalSinceReferenceDate]];
    self.vars = args;
    self.dic = @{@"name": self.name, @"variables": self.vars};
    NSString *decl_name = [JDCustomStruct defineStruct:self.dic];
    return decl_name;
}

- (void)__build_struct:(NSMutableArray *)args {
    [_struct_ary enumerateObjectsUsingBlock:^(JDStructVal * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.isBasic) {
            obj.name = [NSString stringWithFormat:@"%f", [NSDate timeIntervalSinceReferenceDate]];
            obj.type = typeEncodingToTypeStr(obj.basic.UTF8String);
            obj.dic = @{@"name":obj.name, @"type":obj.type};
            [args addObject: obj.dic];
        } else {
            NSMutableArray *_args = @[].mutableCopy;
            [obj __build_struct:_args];
            obj.name = [NSString stringWithFormat:@"%f", [NSDate timeIntervalSinceReferenceDate]];
            obj.vars = _args;
            obj.dic = @{@"name": obj.name, @"variables": _args};
            [JDCustomStruct defineStruct:obj.dic];

            [args addObject:@{@"name":obj.name, @"type":obj.dic}];
        }
    }];
}


@end
@implementation NSObject (JDRuntimeIntrospection)

- (NSArray<NSString *> *)jd_logAllProperties
{
    unsigned int count;
    Ivar *ivars = class_copyIvarList([self class], &count);
    for (unsigned int i = 0; i < count; i++) {
        Ivar ivar = ivars[i];
        const char *name = ivar_getName(ivar);
        const char *type = ivar_getTypeEncoding(ivar);
        NSLog(@"type: %s", type);
        ptrdiff_t offset = ivar_getOffset(ivar);
        NSString *typeStr = [NSString stringWithUTF8String:type];
        NSString * searchStr = typeStr;
        NSString * regExpStr = @"\"[0-9a-zA-z_]+\"";
        NSString * replacement = @"";
        NSRegularExpression *regExp = [[NSRegularExpression alloc] initWithPattern:regExpStr
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
        NSString *resultStr = searchStr;
        resultStr = [regExp stringByReplacingMatchesInString:searchStr
                                                     options:NSMatchingReportProgress
                                                       range:NSMakeRange(0, searchStr.length)
                                                withTemplate:replacement];
        handleIvarType(ivar, name, resultStr.UTF8String, &offset, self);
    }
    free(ivars);
    return [result copy];
}


NSMutableArray<NSString *> *result = @[].mutableCopy;

void handleIvarType(Ivar ivar,const char *name,const char *type,ptrdiff_t *offset,id obj) {
    cout<<*offset<< endl;
    if (strncmp(type, @encode(char), 1) == 0) {
        char value = *(char *)((uintptr_t)obj + *offset);
        *offset = *offset + sizeof(char);
        [result addObject: [NSString stringWithFormat:@"%s = %c", name, value]];
    }
    else if (strncmp(type, @encode(int), 1) == 0) {
        int value = *(int *)((uintptr_t)obj + *offset);
        *offset = *offset + sizeof(int);
        [result addObject: [NSString stringWithFormat:@"%s = %d", name, value]];
    }
    else if (strncmp(type, @encode(short), 1) == 0) {
        short value = *(short *)((uintptr_t)obj + *offset);
        *offset = *offset + sizeof(short);
        [result addObject: [NSString stringWithFormat:@"%s = %hd", name, value]];
    }
    else if (strncmp(type, @encode(long), 1) == 0) {
        long value = *(long *)((uintptr_t)obj + *offset);
        *offset = *offset + sizeof(long);
        [result addObject: [NSString stringWithFormat:@"%s = %ld", name, value]];
    }
    else if (strncmp(type, @encode(long long), 1) == 0) {
        long long value = *(long long *)((uintptr_t)obj + *offset);
        *offset = *offset + sizeof(long long);
        [result addObject: [NSString stringWithFormat:@"%s = %lld", name, value]];
    }
    else if (strncmp(type, @encode(unsigned char), 1) == 0) {
        unsigned char value = *(unsigned char *)((uintptr_t)obj + offset);
        *offset = *offset + sizeof(unsigned char);
        [result addObject: [NSString stringWithFormat:@"%s = %c", name, value]];
    }
    else if (strncmp(type, @encode(unsigned int), 1) == 0) {
        unsigned int value = *(unsigned int *)((uintptr_t)obj + offset);
        *offset = *offset + sizeof(unsigned int);
        [result addObject: [NSString stringWithFormat:@"%s = %u", name, value]];
    }
    else if (strncmp(type, @encode(unsigned short), 1) == 0) {
        unsigned short value = *(unsigned short *)((uintptr_t)obj + offset);
        *offset = *offset + sizeof(unsigned short);
        [result addObject: [NSString stringWithFormat:@"%s = %hu", name, value]];
    }
    else if (strncmp(type, @encode(unsigned long), 1) == 0) {
        unsigned long value = *(unsigned long *)((uintptr_t)obj + offset);
        *offset = *offset + sizeof(unsigned long);
        [result addObject: [NSString stringWithFormat:@"%s = %lu", name, value]];
    }
    else if (strncmp(type, @encode(unsigned long long), 1) == 0) {
        unsigned long long value = *(unsigned long long *)((uintptr_t)obj + offset);
        *offset = *offset + sizeof(unsigned long long);
        [result addObject: [NSString stringWithFormat:@"%s = %llu", name, value]];
    }
    else if (strncmp(type, @encode(float), 1) == 0) {
        float value = *(float *)((uintptr_t)obj + offset);
        *offset = *offset + sizeof(float);
        [result addObject: [NSString stringWithFormat:@"%s = %f", name, value]];
    }
    else if (strncmp(type, @encode(double), 1) == 0) {
        double value = *(double *)((uintptr_t)obj + offset);
        *offset = *offset + sizeof(double);
        [result addObject: [NSString stringWithFormat:@"%s = %e", name, value]];
    }
    else if (strncmp(type, @encode(bool), 1) == 0) {
        bool value = *(bool *)((uintptr_t)obj + offset);
        *offset = *offset + sizeof(bool);
        [result addObject: [NSString stringWithFormat:@"%s = %d", name, value]];
    }
    else if (strncmp(type, @encode(char *), 1) == 0) {
        char * value = *(char * *)((uintptr_t)obj + offset);
        *offset = *offset + sizeof(char*);
        [result addObject: [NSString stringWithFormat:@"%s = %s", name, value]];
    }
    /// 就不处理 offset了
    else if (strncmp(type, @encode(id), 1) == 0) {
        id value = object_getIvar(obj, ivar);
        [result addObject: [NSString stringWithFormat:@"%s = %@", name, value]];
    }
    else if (strncmp(type, @encode(Class), 1) == 0) {
        id value = object_getIvar(obj, ivar);
        [result addObject: [NSString stringWithFormat:@"%s = %@", name, value]];
    }
    // todo
    // SEL
    // struct
    else if (strncmp(type, "{", 1) == 0) {
        void *src = (void *)((uintptr_t)obj + *offset);
        parseEncoding(type, src);
    }
    // array
    // union
    // bit
    // field of num bits
    // pointer to type
}



void parseEncoding(const char * encoding, void* pointer) {
    JDStructVal *structVal = constrcutStruct(std::string(encoding));
    NSString *decl_name = [structVal build];

    NSDictionary *dic = [JDCustomStruct getStructDictWithName:decl_name encoding:[NSString stringWithUTF8String:encoding] fromPointer:pointer error:nil];
    NSLog(@"%@", dic);
}

JDStructVal *constrcutBasic(char encoding) {
    JDStructVal *s = [JDStructVal new];
    s.isBasic = true;
    s.basic = [NSString stringWithFormat:@"%c", encoding];
    NSLog(@"%c", encoding);
    return s;
    
}
size_t position = 0;

JDStructVal *constrcutStruct(string encoding) {
    JDStructVal *s = [JDStructVal new];
    s.struct_ary= @[].mutableCopy;
    s.isBasic = false;
    while (position < encoding.size()) {
        if (encoding[position] == '{') {
            size_t posL = encoding.find_first_of('=', position);
            if (posL !=  string::npos) {
                // pos + 1 -> remove =
                position = posL+1;
                [s.struct_ary addObject:constrcutStruct(encoding)];
            } else {
                NSCAssert(NO, @"encoding %s is wrong, struct encoding err", encoding.c_str());
            }
        }
        if (encoding[position] == '}') {
            position = position + 1;
            if (s.struct_ary.count == 1 && s.struct_ary[0].isBasic == false) {
                s = s.struct_ary[0];
            }
            
            return s;
        }
        if (encoding[position] != '{' && encoding[position] != '}' && encoding[position] != '\0') {
 
                [s.struct_ary addObject:constrcutBasic(encoding[position])];
                position = position + 1;

        }
    }
    if (s.struct_ary.count == 1 && s.struct_ary[0].isBasic == false) {
        s = s.struct_ary[0];
    }
    return s;
}
#pragma mark Test
- (void)Test_JDRuntimeIntrospection {
    [self Test_EncodingToDic];
    [self Test_jd_logAllProperties];
}
// struct type encoding to dic
- (void)Test_EncodingToDic {
    struct Test_struct2 {
        int c;
        double d;
    };
    struct Test_struct1 {
        struct Test_struct2 struct2;
        
        int a;
        int b;
    };
    const char *struct1_encoding = @encode(struct Test_struct1);
    printf("struct1_encoding: %s \n", struct1_encoding);
    Test_struct1 struct1 = {1,52.1,3,4};
    parseEncoding(struct1_encoding, &struct1);
}
- (void)Test_jd_logAllProperties {
    Test_jd_logAllProperties *test_1 = [Test_jd_logAllProperties new];
    [test_1 jd_logAllProperties];
}


@end
