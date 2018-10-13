//
//  JDTypeEncodings.h
//

#ifndef JDTypeEncodings_h
#define JDTypeEncodings_h

#import "JDMacros.h"

#define JD_STRING_NORMALIZE_VAR_TYPE(str)  JD_STRING_TRIM(JD_STRING_TRIM_ANY2ONE(str))


typedef NS_ENUM(NSInteger, JDEncodingType) {
    JDEncodingTypeVoid = 0,
    JDEncodingTypeBool,
    JDEncodingTypeChar,
    JDEncodingTypeUChar,
    JDEncodingTypeShort,
    JDEncodingTypeUShort,
    JDEncodingTypeInt,
    JDEncodingTypeUInt,
    JDEncodingTypeLong,
    JDEncodingTypeULong,
    JDEncodingTypeLongLong,
    JDEncodingTypeULongLong,
    JDEncodingTypeFloat,
    JDEncodingTypeDouble,
    JDEncodingTypePointer,         // void *, struct *
    JDEncodingTypeCharPointer,     // char *
    JDEncodingTypeStruct,          // struct
    JDEncodingTypeUnion,           // union, unsupported
    JDEncodingTypeCArray,          // array, unsupported
    JDEncodingTypeBit,             // bit ,  unsupported
    JDEncodingTypeSEL,             // SEL          (:)
    JDEncodingTypeClass,           // class        (#)
    JDEncodingTypeObject,          // object       (@)
    JDEncodingTypeUndefined,       // undefined    (?)
    
    JDEncodingTypeBlock,           // block        (@?)
    JDEncodingTypeObjectPointer,   // id *         (^@)
    JDEncodingTypeFunction,        // function
    JDEncodingTypeMaxCounts,
    
    JDEncodingTypeUnknown = JDEncodingTypeUndefined,
};

static char _ObjCTypeEncodings[] = {
    'v', // void
    'B', // bool
    'c', // char
    'C', // unsigned char
    's', // short
    'S', // unsigned short
    'i', // int
    'I', // unsigned int
    'l', // long
    'L', // unsigned long
    'q', // long long
    'Q', // unsigned long long
    'f', // float
    'd', // double
    '^', // void *
    '*', // char *
    '{', // struct
    '(', // union
    '[', // array
    'b', // bit
    ':', // SEL
    '#', // Class
    '@', // object
    '?', // unknown
    'F', // Function
    0
};

static int _ObjcTypeEncodingSizeTable[] = {
    [JDEncodingTypeVoid]           = sizeof(void), // void
    [JDEncodingTypeVoid]           = sizeof(bool),
    [JDEncodingTypeChar]           = sizeof(char),
    [JDEncodingTypeUChar]          = sizeof(unsigned char),
    [JDEncodingTypeShort]          = sizeof(short),
    [JDEncodingTypeUShort]         = sizeof(unsigned short),
    [JDEncodingTypeInt]            = sizeof(int),
    [JDEncodingTypeUInt]           = sizeof(unsigned int),
    [JDEncodingTypeLong]           = sizeof(long),
    [JDEncodingTypeULong]          = sizeof(unsigned long),
    [JDEncodingTypeLongLong]       = sizeof(long long),
    [JDEncodingTypeULongLong]      = sizeof(unsigned long long),
    [JDEncodingTypeFloat]          = sizeof(float),
    [JDEncodingTypeDouble]         = sizeof(double),
    [JDEncodingTypePointer]        = sizeof(void *),
    [JDEncodingTypeCharPointer]    = sizeof(char *),
    [JDEncodingTypeStruct]         = 0, // struct
    [JDEncodingTypeUnion]          = 0, // union
    [JDEncodingTypeCArray]         = 0, // array
    [JDEncodingTypeBit]            = 0, // Bit
    [JDEncodingTypeSEL]            = sizeof(SEL),
    [JDEncodingTypeClass]          = sizeof(Class),
    [JDEncodingTypeObject]         = sizeof(id),
    [JDEncodingTypeUndefined]      = 0, // undefined
    [JDEncodingTypeBlock]          = sizeof(void (^)(void)), // block
    [JDEncodingTypeObjectPointer]  = sizeof(void *), // object pointer
    [JDEncodingTypeFunction]       = sizeof(void *), // function
    0
};

static JDEncodingType JDGetEncodingType(const char *ch) JD_STATIC_UNUSED_WARN;
static JDEncodingType JDGetEncodingTypeOfVAR(NSString *str) JD_STATIC_UNUSED_WARN;
static size_t JDGetSizeOfEncodingType(JDEncodingType type) JD_STATIC_UNUSED_WARN;
static size_t JDGetSizeOfObjCTypeEncoding(const char *type) JD_STATIC_UNUSED_WARN;
static size_t JDGetSizeOfObjCVarType(NSString *varType) JD_STATIC_UNUSED_WARN;
static const char * JDGetCTypeEncoding(JDEncodingType type) JD_STATIC_UNUSED_WARN;
static NSString * JDGetTypeEncodingOfVAR(NSString *str) JD_STATIC_UNUSED_WARN;
static BOOL JDIsBlock(NSString *str) JD_STATIC_UNUSED_WARN;
static BOOL JDIsClass(NSString *str) JD_STATIC_UNUSED_WARN;
static BOOL JDIsSEL(NSString *str) JD_STATIC_UNUSED_WARN;
static BOOL JDIsObject(NSString *str) JD_STATIC_UNUSED_WARN;
static BOOL JDIsPrimitiveType(NSString *str) JD_STATIC_UNUSED_WARN; // char, int, short, long, long long, float, double
static BOOL JDIsPrimitivePointer(NSString *str) JD_STATIC_UNUSED_WARN;
static BOOL JDIsStruct(NSString *str) JD_STATIC_UNUSED_WARN;

typedef NS_ENUM(NSInteger, JDStructEncodingType) {
    JDStructEncodingTypeUnknown = -1,
    JDStructEncodingTypeNSRange,
    JDStructEncodingTypeCGRect,
    JDStructEncodingTypeCGSize,
    JDStructEncodingTypeCGPoint,
    JDStructEncodingTypeCGVector,
    JDStructEncodingTypeCGAffineTransform,
    JDStructEncodingTypeUIEdgeInsets,
    JDStructEncodingTypeUIOffset,
    JDStructEncodingTypeNSDirectionalEdgeInsets,
    JDStructEncodingTypeUnsupported,
};

static NSString * JDExtractStructName(NSString *typeEncodeString) JD_STATIC_UNUSED_WARN;
static JDStructEncodingType JDGetStructEncodingType(NSString *str) JD_STATIC_UNUSED_WARN;

#pragma mark - JDEncodingType

static JDEncodingType JDGetEncodingType(const char *ch)
{
    if (ch == NULL || strlen(ch) == 0) return JDEncodingTypeUnknown;
    if (strlen(ch) == 1 && ch[0] == 'r') return JDEncodingTypeUnknown;
    const char *encodePtr = (ch[0] == 'r' ? ch + 1 : ch);
    if (strlen(ch) > 1) {
        if (*encodePtr == '@' && *(encodePtr + 1) == '?') return JDEncodingTypeBlock;
        if (*encodePtr == '^' && *(encodePtr + 1) == '@') return JDEncodingTypeObjectPointer;
    }
    const char *chrEncodePtr = strchr(_ObjCTypeEncodings, (*encodePtr));
    if (chrEncodePtr) return (chrEncodePtr - _ObjCTypeEncodings);
    return JDEncodingTypeUnknown;
}

static size_t JDGetSizeOfEncodingType(JDEncodingType type)
{
    if (type < JDEncodingTypeMaxCounts) return _ObjcTypeEncodingSizeTable[type];
    return 0;
}

static size_t JDGetSizeOfObjCTypeEncoding(const char *type)
{
    JDEncodingType encodeType = JDGetEncodingType(type);
    if (encodeType < JDEncodingTypeMaxCounts) return _ObjcTypeEncodingSizeTable[encodeType];
    return 0;
}

static size_t JDGetSizeOfObjCVarType(NSString *varType)
{
    JDEncodingType encodeType = JDGetEncodingTypeOfVAR(varType);
    if (encodeType < JDEncodingTypeMaxCounts) return _ObjcTypeEncodingSizeTable[encodeType];
    return 0;
}

static const char * JDGetCTypeEncoding(JDEncodingType type)
{
    if (JDEncodingTypeBlock == type) return "@?";
    if (JDEncodingTypeObjectPointer == type) return "^@";
    if (type < strlen(_ObjCTypeEncodings)) {
        char targetChar = _ObjCTypeEncodings[type];
        char chars[] = {targetChar, 0};
        return [@(chars) UTF8String];
    }
    return "?";
}

static JDEncodingType JDGetEncodingTypeOfVAR(NSString *str)
{
    if (!str) return JDEncodingTypeUnknown;
    NSString *encodeString = JDGetTypeEncodingOfVAR(str);
    if (encodeString) return JDGetEncodingType([encodeString UTF8String]);
    return JDGetEncodingType([JD_STRING_TRIM_ALL(str) UTF8String]);
}

static NSString * JDGetTypeEncodingOfVAR(NSString *str)
{
    if (!str || str.length == 0) return nil;
    str = JD_STRING_NORMALIZE_VAR_TYPE(str);
    
    static NSMutableDictionary *_varTypeEncodingMapper;
    if (!_varTypeEncodingMapper) {
        _varTypeEncodingMapper = [NSMutableDictionary dictionary];
        
#define JD_BASIC_TYPE_ENCODING_CASE(_type) \
[_varTypeEncodingMapper setObject:@(@encode(_type)) forKey:@(#_type)];\

        JD_BASIC_TYPE_ENCODING_CASE(void);
        JD_BASIC_TYPE_ENCODING_CASE(BOOL);
        JD_BASIC_TYPE_ENCODING_CASE(bool);
        JD_BASIC_TYPE_ENCODING_CASE(char);
        JD_BASIC_TYPE_ENCODING_CASE(unsigned char);
        JD_BASIC_TYPE_ENCODING_CASE(short);
        JD_BASIC_TYPE_ENCODING_CASE(unsigned short);
        JD_BASIC_TYPE_ENCODING_CASE(int);
        JD_BASIC_TYPE_ENCODING_CASE(unsigned int);
        JD_BASIC_TYPE_ENCODING_CASE(NSInteger);
        JD_BASIC_TYPE_ENCODING_CASE(NSUInteger);
        JD_BASIC_TYPE_ENCODING_CASE(long);
        JD_BASIC_TYPE_ENCODING_CASE(unsigned long);
        JD_BASIC_TYPE_ENCODING_CASE(long long);
        JD_BASIC_TYPE_ENCODING_CASE(unsigned long long);
        JD_BASIC_TYPE_ENCODING_CASE(float);
        JD_BASIC_TYPE_ENCODING_CASE(double);
        JD_BASIC_TYPE_ENCODING_CASE(CGFloat);
        JD_BASIC_TYPE_ENCODING_CASE(id);
        JD_BASIC_TYPE_ENCODING_CASE(Class);
        JD_BASIC_TYPE_ENCODING_CASE(SEL);
        JD_BASIC_TYPE_ENCODING_CASE(void*);
        JD_BASIC_TYPE_ENCODING_CASE(void *);
        JD_BASIC_TYPE_ENCODING_CASE(char*);
        JD_BASIC_TYPE_ENCODING_CASE(char *);
        
        JD_BASIC_TYPE_ENCODING_CASE(CGSize);
        JD_BASIC_TYPE_ENCODING_CASE(CGRect);
        JD_BASIC_TYPE_ENCODING_CASE(CGPoint);
        JD_BASIC_TYPE_ENCODING_CASE(NSRange);
        JD_BASIC_TYPE_ENCODING_CASE(CGVector);
#if TARGET_OS_IPHONE
        JD_BASIC_TYPE_ENCODING_CASE(UIEdgeInsets);
#else
        JD_BASIC_TYPE_ENCODING_CASE(NSEdgeInsets);
#endif
        [_varTypeEncodingMapper setObject:@"@"  forKey:@"instancetype"];
        [_varTypeEncodingMapper setObject:@"^@" forKey:@"id*"];
        [_varTypeEncodingMapper setObject:@"^@" forKey:@"id *"];
        
        [_varTypeEncodingMapper setObject:@"@?" forKey:@"block"];
        [_varTypeEncodingMapper setObject:@"@?" forKey:@"NSBlock"];

        [_varTypeEncodingMapper setObject:@(@encode(Class)) forKey:@"class"];
        [_varTypeEncodingMapper setObject:@(@encode(SEL)) forKey:@"sel"];
    }
    NSString *encodeString = _varTypeEncodingMapper[str];
    if (encodeString) return encodeString;
    
    // NSObject object
    if (NSClassFromString(str)) return @"@";
    
    // block: *** (^)(***)
    NSString *trimAllStr = JD_STRING_TRIM_ALL(str);
    if ([trimAllStr rangeOfString:@"(^)"].location != NSNotFound) return @"@?";
    
    // remove stars (*)
    NSMutableString *mutStr = [str mutableCopy];
    NSInteger numberOfStars = [mutStr replaceOccurrencesOfString:@"*" withString:@"" options:0 range:NSMakeRange(0, mutStr.length)];
    NSString *trimStarStr   = JD_STRING_TRIM([mutStr copy]);
    if ([trimStarStr hasPrefix:@"{"]) { // struct
        // TODO
        trimStarStr = [trimStarStr stringByReplacingOccurrencesOfString:@"\\" withString:@""];
        trimStarStr = [trimStarStr stringByReplacingOccurrencesOfString:@"" withString:@""];
        trimStarStr = [trimStarStr stringByReplacingOccurrencesOfString:@"_" withString:@""];
    }
    
    NSString *trimTypeEncoding = (numberOfStars > 0 ? JDGetTypeEncodingOfVAR(trimStarStr) : nil);
  
    BOOL isObject = (NSClassFromString(trimStarStr) != nil); // NSObject object
    
    NSMutableString *mutEncoding = [@"" mutableCopy];
    NSInteger numberOfPointer = numberOfStars;
    if (isObject) numberOfPointer -= 1; // NSObject object
    else if ([trimTypeEncoding isEqualToString:@"c"]) {
        // special char [*]+
        trimTypeEncoding = @"*";
        numberOfPointer -= 1;
    }
    for (int i = 0; i < numberOfPointer; i++) {
        [mutEncoding appendString:@"^"];
    }
    [mutEncoding appendString:trimTypeEncoding ? : @""];
    if (trimTypeEncoding) return [mutEncoding copy];
    
    return JDGetEncodingType([str UTF8String]) != JDEncodingTypeUnknown ? [str copy] : nil;
    
    // other struct ...
    
    // union ...
    
    // bit ...
    
    return nil;
}

static BOOL JDIsBlock(NSString *str)
{
    return (JDEncodingTypeBlock == JDGetEncodingTypeOfVAR(str));
}

static BOOL JDIsSEL(NSString *str)
{
    return (JDEncodingTypeSEL == JDGetEncodingTypeOfVAR(str));
}

static BOOL JDIsClass(NSString *str)
{
    return (JDEncodingTypeClass == JDGetEncodingTypeOfVAR(str));
}

static BOOL JDIsObject(NSString *str)
{
    return (JDEncodingTypeObject == JDGetEncodingTypeOfVAR(str));
}

static BOOL JDIsPrimitiveType(NSString *str)
{
    if (!str) return NO;
    JDEncodingType entype = JDGetEncodingTypeOfVAR(str);
    if (entype >= JDEncodingTypeBool && entype <= JDEncodingTypeDouble) return YES;
    return NO;
}

static BOOL JDIsPrimitivePointer(NSString *str)
{
    if (!str) return NO;
    JDEncodingType entype = JDGetEncodingTypeOfVAR(str);
    if (JDEncodingTypePointer == entype || JDEncodingTypeCharPointer == entype) return YES;
    return NO;
}

static BOOL JDIsStruct(NSString *str)
{
    if (!str) return NO;
    JDEncodingType entype = JDGetEncodingTypeOfVAR(str);
    if (JDEncodingTypeStruct == entype) return YES;
    if ([str rangeOfString:@"struct"].location != NSNotFound) return YES;
    return NO;
}

//static NSArray<NSNumber *> * JDGetStructTypes(NSString *str)
//{
//    if (!str || str.length == 0) { return nil; }
//    if (!JDIsStruct(str)) { return nil; }
//
//    NSMutableArray<NSNumber *> *mutArray = [NSMutableArray new];
//    const char *equals = strchr([str UTF8String], '=');
//    const char *cursor = equals + 1;
//    while (*cursor != '}') {
//        JDEncodingType enumEncode = JDGetEncodingType(cursor);
//        NSCAssert(enumEncode >= JDEncodingTypeBool && enumEncode <= JDEncodingTypeDouble, @"type invalid");
//        [mutArray addObject:@(enumEncode)];
//        cursor = NSGetSizeAndAlignment(cursor, NULL, NULL);
//    }
//    return mutArray;
//}

#pragma mark - JDStructEncodingType

// get struct name from type encoding
static NSString *JDExtractStructName(NSString *typeEncodeString)
{
    NSArray *array = [typeEncodeString componentsSeparatedByString:@"="];
    NSString *structTypeStr = array.count > 0 ? array[0] : nil;
    int firstIdx = 0;
    for (int i = 0; i< structTypeStr.length; i++) {
        char c = [structTypeStr characterAtIndex:i];
        if (isspace(c)) continue;
        if (c == '{' || c=='_') firstIdx++;
        else break;
    }
    return (firstIdx < structTypeStr.length ? [structTypeStr substringFromIndex:firstIdx] : nil);
}

static JDStructEncodingType JDGetStructEncodingType(NSString *str)
{
    str = JD_STRING_NORMALIZE_VAR_TYPE(str);
    
    static NSArray *_structEncodingTypeArray;
    if (!_structEncodingTypeArray) {
        _structEncodingTypeArray = @[
                                     @"NSRange",                // NSRange
                                     @"CGRect",                 // CGRect
                                     @"CGSize",                 // CGSize
                                     @"CGPoint",                // CGPoint
                                     @"CGVector",               // CGVector
                                     @"CGAffineTransform",      // CGAffineTransform
                                     @"UIEdgeInsets",           // UIEdgeInsets,
                                     @"UIOffset",               // UIOffset
                                     @"NSDirectionalEdgeInsets", // NSDirectionalEdgeInsets
                                     ];
    }
    
    str = JDExtractStructName(str);
    if (!str) return JDStructEncodingTypeUnsupported;
    
    __block NSInteger foundIdx = [_structEncodingTypeArray indexOfObject:str];
    if (foundIdx != NSNotFound) return foundIdx;
    
    [_structEncodingTypeArray enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([str rangeOfString:obj].location != NSNotFound) { foundIdx = idx; *stop = YES; }
    }];
    return (foundIdx != NSNotFound ? foundIdx : JDStructEncodingTypeUnsupported);
}


#endif /* JDTypeEncodings_h */
