//
//  JDCustomStruct.m
//
//

#import "JDCustomStruct.h"
#import <objc/runtime.h>
#import "JDTypeEncodings.h"

#if CGFLOAT_IS_DOUBLE
#define CGFloatValue doubleValue
#else
#define CGFloatValue floatValue
#endif


NSString *JDStructErrorDomain = @"custom.struct.error";

static NSMutableDictionary *_registeredCustomStructs;

#define JD_STATIC_UNUSED_WARN              __attribute__((unused))

// 获取size使用alignment对齐，进行填充后的大小
static size_t getPadSize(size_t size, size_t alignment) JD_STATIC_UNUSED_WARN;
static size_t getPadSize(size_t size, size_t alignment)
{
    return (alignment * ((size + alignment - 1) / alignment));
}

static size_t getPadding(size_t size, size_t alignment) JD_STATIC_UNUSED_WARN;
static size_t getPadding(size_t size, size_t alignment)
{
    return (alignment - (size & (alignment - 1))) & (alignment - 1);
}

@interface JDStructDecl () {
    BOOL _hasCountAlignment; /** 是否计算过对齐操作 */
}
// 结构体中最宽基本类型大小
@property (nonatomic, assign) size_t widestPrimitiveSize;
@property (nonatomic, assign) BOOL alignPadding; // 结构体是否使用对齐填充，默认YES
+ (instancetype)structDeclWithDictionary:(NSDictionary *)declDict;
- (NSDictionary *)dictionaryFromStructPointer:(void *)structData;
- (void)constructStructPointer:(void *)structData
                fromDictionary:(NSDictionary *)value;
- (void)adjustAlignmentSize:(size_t)outAlignSize
                   currSize:(size_t)currSize;
@end

@interface JDStructVarDecl () {
    BOOL _hasCountAlignment; /** 是否计算过对齐操作 */
}
// 结构体中最宽基本类型大小
@property (nonatomic, assign) size_t widestPrimitiveSize;
+ (instancetype)structVarDeclWithDictionary:(NSDictionary *)declDict;
- (id)valueFromStructPointer:(void *)structData;
- (void)constructStructPointer:(void *)structData
                     fromValue:(id)value;
- (void)adjustAlignmentSize:(size_t)outAlignSize
                   currSize:(size_t)currSize;
@end

@implementation JDStructDecl

+ (instancetype)structDeclWithDictionary:(NSDictionary *)declDict
{
    return [[self alloc] initWithStructDecl:declDict];
}

- (instancetype)init
{
    if ((self = [super init])) {
        _alignPadding = YES;
        _size = 0;
        _widestPrimitiveSize = 0;
        _hasCountAlignment = NO;
    }
    return self;
}

- (instancetype)initWithStructDecl:(NSDictionary *)declDict
{
    NSString *structName = declDict[@"name"];
    NSArray  *structVars = declDict[@"variables"];
    if (!structName || !structVars) return nil;
    
    if ((self = [self init])) {
        NSMutableArray *varDeclArr = [NSMutableArray array];
        [structVars enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[NSDictionary class]]) {
                JDStructVarDecl *structVarDecl = [JDStructVarDecl structVarDeclWithDictionary:(NSDictionary *)obj];
                if (structVarDecl) [varDeclArr addObject:structVarDecl];
                else NSCAssert(NO, @"struct variable declaration format (%@) is wrong", (NSDictionary *)obj);
            } else {
                NSCAssert(NO, @"struct variable declaration (%@) is wrong, must be NSString or NSDictionary", obj);
            }
        }];
        _name = structName;
        _vars = [varDeclArr copy];
        
        [self __build__];
    }
    return self;
}

- (BOOL)isAlignPadding
{
    return _alignPadding;
}

- (NSInteger)numberOfElements
{
    return [self.varNames count];
}

- (NSArray<NSString *> *)typeEncodeOfElements
{
    NSMutableArray *elemEncodeArr = [NSMutableArray array];
    [self.vars enumerateObjectsUsingBlock:^(JDStructVarDecl * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [elemEncodeArr addObject:[obj encoding]];
    }];
    return elemEncodeArr.count > 0 ? [elemEncodeArr copy] : nil;
}

- (void)__build__
{
    size_t size = 0;
    size_t alignSize = 0;
    NSMutableString *mutEncoding = [NSMutableString string];
    //NSMutableString *mutSigEncoding = [NSMutableString string];
    NSMutableArray  *mutStructNames = [NSMutableArray array];
    for (JDStructVarDecl *var in self.vars) {
        size += [var size];
        alignSize += [var alignSize];
        [mutEncoding appendString:[var encoding]];
        //[mutSigEncoding appendFormat:[var sig_encoding]];
        [mutStructNames addObjectsFromArray:[var varNames]];
    }
    
    _size = size;
    _alignSize = alignSize;
    _encoding = [NSString stringWithFormat:@"{%@=%@}", _name, mutEncoding];
    //_sig_encoding = [NSString stringWithFormat:@"{%@=%@}%ld", _name, mutSigEncoding, _alignSize];
    _varNames = [mutStructNames copy];
    
    [self adjustAlignmentSize:0 currSize:0];
}

- (void)adjustAlignmentSize:(size_t)outAlignSize currSize:(size_t)currSize
{
    if (_hasCountAlignment) return;
    
    size_t actualTotalSize = 0;
    size_t getAlignSize = 0;
    const char *cTypeEncode = [self.encoding UTF8String];
    const char *cursor = cTypeEncode;
    while (*cursor && *cursor != '}') {
        size_t getSize;
        cursor = NSGetSizeAndAlignment(cursor, &getSize, &getAlignSize);
        actualTotalSize += getSize;
    }
    _alignSize = MAX(actualTotalSize, _alignSize);
    
    // 计算每个变量的`偏移量`、`填充字节数` 以及 `对齐的字节数`
    size_t offset = 0;
    size_t currTotalSize = 0;
    size_t widestVarSize = 0;
    for (JDStructVarDecl *var in self.vars) {
        // 调整当前变量(`基本类型`或`结构体`)的`偏移量`、`填充字节数`以及`对齐的字节数`
        [var adjustAlignmentSize:MAX(outAlignSize, getAlignSize) currSize:currTotalSize];
        
        // 编译器使用填充对齐
        if ([self isAlignPadding]) {
            NSInteger currIdx = [self.vars indexOfObject:var];
            if (currIdx != 0) {
                size_t lastOffset = offset;
                // 当前变量的offset
                offset = getPadSize(currTotalSize, [var widestPrimitiveSize]);
                // 通过 `当前变量的offset` 来调整 `至上一个变量的累计大小`
                currTotalSize = MAX(currTotalSize, offset);
                
                // 调整上一个变量对齐后的大小
                JDStructVarDecl *prevStructVar = self.vars[currIdx - 1];
                prevStructVar.alignSize = MAX(prevStructVar.alignSize, offset - lastOffset);
            }
        }
        
        currTotalSize += MAX([var size], [var alignSize]);
        widestVarSize = MAX(widestVarSize, [var widestPrimitiveSize]);
    }
    _widestPrimitiveSize = widestVarSize;
    
    // adjust last var `alignSize`
    JDStructVarDecl *lastStructVar = [self.vars lastObject];
    lastStructVar.alignSize = MAX(lastStructVar.alignSize, _alignSize - offset);
    
    _hasCountAlignment = YES;
}

- (void)constructStructPointer:(void *)structData fromDictionary:(NSDictionary *)value;
{
    if (structData == NULL) return;
    int position = 0;
    for (JDStructVarDecl *varDecl in self.vars) {
        BOOL rectCompatible = NO;
        if ([self.name isEqualToString:@"CGRect"]) {
            if ([varDecl.name isEqualToString:@"origin"] && !value[@"origin"]) {
                rectCompatible = YES;
                [varDecl constructStructPointer:(structData + position) fromValue:@{@"x": value[@"x"], @"y": value[@"y"]}];
            }
            if ([varDecl.name isEqualToString:@"size"] && !value[@"size"]) {
                rectCompatible = YES;
                [varDecl constructStructPointer:(structData + position) fromValue:@{@"width": value[@"width"], @"height": value[@"height"]}];
            }
        }
        if (!rectCompatible) {
            [varDecl constructStructPointer:(structData + position) fromValue:value[varDecl.name]];
        }
        position += varDecl.alignSize;
    }
}

- (NSDictionary *)dictionaryFromStructPointer:(void *)structData
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    int position = 0;
    for (JDStructVarDecl *varDecl in self.vars) {
        id value = [varDecl valueFromStructPointer:(structData + position)];
        [dict setValue:value forKey:varDecl.name];
        position += varDecl.alignSize;
    }
    return [dict copy];
}


@end

@implementation JDStructVarDecl

+ (instancetype)structVarDeclWithDictionary:(NSDictionary *)declDict
{
    return [[self alloc] initWithStructVarDecl:declDict];
}

- (instancetype)init
{
    if ((self = [super init])) {
        _size = 0;
        _widestPrimitiveSize = 0;
        _hasCountAlignment = NO;
    }
    return self;
}

- (instancetype)initWithStructVarDecl:(NSDictionary *)declDict
{
    id structVarType = declDict[@"type"];
    NSString *structVarName = declDict[@"name"];
    if (!structVarName || !structVarType) return nil;
    
    if ((self = [self init])) {
        if ([structVarType isKindOfClass:[NSString class]]) {
            _type = structVarType;
        } else if ([structVarType isKindOfClass:[NSDictionary class]]) {
            NSString *structName = [JDCustomStruct defineStruct:(NSDictionary *)structVarType];
            _type = [JDCustomStruct getStructNamed:structName];
            NSCAssert(_type, @"struct variable type (%@) is struct, but declaration is wrong", structVarType);
        } else {
            NSCAssert(NO, @"struct variable type (%@) is unsupported, must be NSString (primitive type) or NSDictionary(struct)", structVarType);
        }
        _name = structVarName;
        
        [self __build__];
    }
    return self;
}

- (void)__build__
{
    size_t size = 0;
    size_t alignSize = 0;
    size_t widestSize = 0;
    NSMutableString *mutEncoding = [NSMutableString string];
    NSMutableArray  *mutNames = [NSMutableArray array];
    
    if ([self isStruct]) {
        JDStructDecl *structDecl = (JDStructDecl *)self.type;
        size = [structDecl size];
        alignSize = [structDecl alignSize];
        widestSize = [structDecl widestPrimitiveSize];
        [mutEncoding appendString:[structDecl encoding]];
        [mutNames addObject:[(JDStructDecl *)self.type varNames]];
    } else { // primitive type
        JDEncodingType encodeType = JDGetEncodingTypeOfVAR(self.type);
        const char *typeEncoding = JDGetCTypeEncoding(encodeType);
        size_t getSize = 0, getAlignSize = 0;
        if (typeEncoding) NSGetSizeAndAlignment(typeEncoding, &getSize, &getAlignSize);
        
        NSInteger primitiveSize = JDGetSizeOfEncodingType(encodeType);
        size = MAX(getSize, primitiveSize);
        alignSize = MAX(getAlignSize, primitiveSize);
        widestSize = size;
        [mutEncoding appendString:@(typeEncoding)];
        [mutNames addObject:self.name];
    }
    
    _size = size;
    _alignSize = alignSize;
    _widestPrimitiveSize = widestSize;
    _encoding = [mutEncoding copy];
    //_sig_encoding = [mutSigEncoding copy];
    _varNames = [mutNames copy];
}

- (void)adjustAlignmentSize:(size_t)outAlignSize currSize:(size_t)currSize
{
    if (_hasCountAlignment) return;
    if ([self isStruct]) {
        JDStructDecl *structDecl = (JDStructDecl *)self.type;
        [structDecl adjustAlignmentSize:outAlignSize currSize:currSize];
        _widestPrimitiveSize = [structDecl widestPrimitiveSize];
        _alignSize = [structDecl alignSize];
        //_sig_encoding = [structDecl.sig_encoding copy];
    } else {
        _widestPrimitiveSize = _size;
        _alignSize = MAX(_size, _alignSize); // 基本类型
        //_sig_encoding = [NSString stringWithFormat:@"%@%ld", _encoding, _alignSize];
    }
    _hasCountAlignment = YES;
}

- (BOOL)isStruct
{
    return [_type isKindOfClass:[JDStructDecl class]];
}

// From NSString, NSDictionary or JDBox to pointer
- (void)constructStructPointer:(void *)structData fromValue:(id)value
{
    if (structData == NULL) return;
    
    const char *typeEncoding = [self.encoding UTF8String];
    switch(*typeEncoding) {
#define JD_STRUCT_PARAM_VAR_CASE(_typeEncode, _type, _method) \
case _typeEncode: { \
size_t size = self.size;    \
_type varVal = [(NSNumber *)value _method];   \
memcpy(structData, &varVal, size);  \
break;  \
}
            
            JD_STRUCT_PARAM_VAR_CASE('c', char, charValue) // [*] `unsigned char` instead `signed char `
            JD_STRUCT_PARAM_VAR_CASE('C', unsigned char, unsignedCharValue)
            JD_STRUCT_PARAM_VAR_CASE('s', short, shortValue)
            JD_STRUCT_PARAM_VAR_CASE('S', unsigned short, unsignedShortValue)
            JD_STRUCT_PARAM_VAR_CASE('i', int, intValue)
            JD_STRUCT_PARAM_VAR_CASE('I', unsigned int, unsignedIntValue)
            JD_STRUCT_PARAM_VAR_CASE('l', long, longValue)
            JD_STRUCT_PARAM_VAR_CASE('L', unsigned long, unsignedLongValue)
            JD_STRUCT_PARAM_VAR_CASE('q', long long, longLongValue)
            JD_STRUCT_PARAM_VAR_CASE('Q', unsigned long long, unsignedLongLongValue)
            JD_STRUCT_PARAM_VAR_CASE('f', float, floatValue)
            JD_STRUCT_PARAM_VAR_CASE('F', CGFloat, CGFloatValue)
            JD_STRUCT_PARAM_VAR_CASE('d', double, doubleValue)
            JD_STRUCT_PARAM_VAR_CASE('B', BOOL, boolValue)
            JD_STRUCT_PARAM_VAR_CASE('N', NSInteger, integerValue)
            JD_STRUCT_PARAM_VAR_CASE('U', NSUInteger, unsignedIntegerValue)
            
        case '*':
        case '^': {
  
            break;
        }
            
        case '#': { // Class

            break;
        }
            
        case ':': { // SEL
 
            break;
        }
            
        case '{': {
            if ([self isStruct] && [value isKindOfClass:[NSDictionary class]]) {
                [(JDStructDecl *)self.type constructStructPointer:structData fromDictionary:(NSDictionary *)value];
            } else {
                NSCAssert(NO, @"value %@ is inconsistent with type %@", value, self.type);
            }
            break;
        }
            
        default: {
            
        }
            break;
    }
}

// to NSString, NSDictionary or JDBox
- (id)valueFromStructPointer:(void *)structData
{
    const char *typeEncoding = [self.encoding UTF8String];
    id retVal;
    
    switch(*typeEncoding) {
#define JD_STRUCT_DICT_CASE(_typeEncode, _type)   \
case _typeEncode: { \
size_t size = self.size; \
_type *val = malloc(size);   \
memcpy(val, structData, size);   \
retVal = @(*val); \
if (val) free(val);  \
break;  \
}
            JD_STRUCT_DICT_CASE('c', char)
            JD_STRUCT_DICT_CASE('C', unsigned char)
            JD_STRUCT_DICT_CASE('s', short)
            JD_STRUCT_DICT_CASE('S', unsigned short)
            JD_STRUCT_DICT_CASE('i', int)
            JD_STRUCT_DICT_CASE('I', unsigned int)
            JD_STRUCT_DICT_CASE('l', long)
            JD_STRUCT_DICT_CASE('L', unsigned long)
            JD_STRUCT_DICT_CASE('q', long long)
            JD_STRUCT_DICT_CASE('Q', unsigned long long)
            JD_STRUCT_DICT_CASE('f', float)
            JD_STRUCT_DICT_CASE('F', CGFloat)
            JD_STRUCT_DICT_CASE('N', NSInteger)
            JD_STRUCT_DICT_CASE('U', NSUInteger)
            JD_STRUCT_DICT_CASE('d', double)
            JD_STRUCT_DICT_CASE('B', BOOL)
            
        case '*':
        case '^': {

            break;
        }
            
        case '#': { // Class
 
            break;
        }
            
        case ':': { // SEL

            break;
        }
            
        case '{': { // struct
            retVal = [(JDStructDecl *)self.type dictionaryFromStructPointer:structData];
            break;
        }
            
        default: {
            // v, b, [, ?
            break;
        }
    }
    return retVal;
}


@end



@implementation JDCustomStruct

+ (void)initializeDefaultStructsDefinition
{
    static BOOL bDeclStructOnce = NO;
    if (bDeclStructOnce) return;
    bDeclStructOnce = YES;
    
    // CGPoint
    NSDictionary *CGPointDict =
    @{
      @"name": @"CGPoint",
      @"variables": @[
              @{
                  @"name": @"x",
                  @"type": @"CGFloat"
                  },
              @{
                  @"name": @"y",
                  @"type": @"CGFloat"
                  }
              ]
      };
    [self defineStruct:CGPointDict];
    
    // CGSize
    NSDictionary *CGSizeDict =
    @{
      @"name": @"CGSize",
      @"variables": @[
              @{
                  @"name": @"width",
                  @"type": @"CGFloat"
                  },
              @{
                  @"name": @"height",
                  @"type": @"CGFloat"
                  },
              ]
      };
    [self defineStruct:CGSizeDict];
    
    // CGRect
    NSDictionary *CGRectDict =
    @{
      @"name": @"CGRect",
      @"variables": @[
              @{
                  @"name": @"origin",
                  @"type": CGPointDict
                  },
              @{
                  @"name": @"size",
                  @"type": CGSizeDict
                  },
              ]
      };
    [self defineStruct:CGRectDict];
    
    // NSRange
    NSDictionary *NSRangeDict =
    @{
      @"name": @"NSRange",
      @"variables": @[
              @{
                  @"name": @"location",
                  @"type": @"NSUInteger"
                  },
              @{
                  @"name": @"length",
                  @"type": @"NSUInteger"
                  },
              ]
      };
    [self defineStruct:NSRangeDict];
}

+ (NSDictionary *)registeredStructs
{
    return [_registeredCustomStructs copy];
}

+ (NSString *)defineStruct:(NSDictionary *)structDeclDict
{
    [self initializeDefaultStructsDefinition];
    
    if (![structDeclDict isKindOfClass:[NSDictionary class]]) return nil;
    NSString *structName = structDeclDict[@"name"];
    if (_registeredCustomStructs[structName]) return structName;
    if (!_registeredCustomStructs) _registeredCustomStructs = [NSMutableDictionary dictionary];
    
    JDStructDecl *sDecl = [JDStructDecl structDeclWithDictionary:structDeclDict];
    if (sDecl && sDecl.name) _registeredCustomStructs[sDecl.name] = sDecl;
    return sDecl.name;
}

+ (JDStructDecl *)getStructNamed:(NSString *)structName
{
    [self initializeDefaultStructsDefinition];
    return _registeredCustomStructs[structName];
}

+ (JDStructDecl *)getStructNamed:(NSString *)structName
                     withEncoding:(NSString *)structEncode
{
    if (!structName) structName = JDExtractStructName(structEncode);
    JDStructDecl *structDecl = [self getStructNamed:structName];
    if (structDecl) return structDecl;
    if ([structName isEqualToString:@"?"]) {
        static NSString *fuzzyPattern = @"\\{.*?=";
        NSString *questionEncode = [structEncode stringByReplacingOccurrencesOfString:fuzzyPattern
                                                                           withString:@"{?="
                                                                              options:NSRegularExpressionSearch
                                                                                range:NSMakeRange(0, structEncode.length)];
        for (NSString *name in [_registeredCustomStructs allKeys]) {
            JDStructDecl *sdecl = _registeredCustomStructs[name];
            NSString *typeEncode = sdecl.encoding;
            // NSArray *varNames = sdecl.varNames; // TODO: 比对变量名，返回正确的结构
            
            typeEncode = [typeEncode stringByReplacingOccurrencesOfString:fuzzyPattern
                                                               withString:@"{?="
                                                                  options:NSRegularExpressionSearch
                                                                    range:NSMakeRange(0, typeEncode.length)];
            if (questionEncode && typeEncode && [typeEncode isEqualToString:questionEncode]) {
                return sdecl;
            }
        }
    }
    return nil;
}

+ (JDStructDecl *)getStructWithFuzzyEncoding:(NSString *)structEncode
{
    return [self getStructNamed:nil withEncoding:structEncode];
}

+ (NSInteger)getSizeOfStructNamed:(NSString *)structName
{
    JDStructDecl *sdecl = [self getStructNamed:structName];
    if (!sdecl) return -1;
    return [sdecl alignSize];
}

+ (NSInteger)getSizeOfStructEncoding:(NSString *)structEncode
{
    JDStructDecl *sdecl = [self getStructWithFuzzyEncoding:structEncode];
    if (!sdecl) return -1;
    return [sdecl alignSize];
}

+ (NSString *)getEncodingOfStructNamed:(NSString *)structName
{
    if (!structName) return NULL;
    if ([structName isEqualToString:@"CGPoint"]) return @(@encode(CGPoint));
    if ([structName isEqualToString:@"CGSize"])  return @(@encode(CGSize));
    if ([structName isEqualToString:@"CGRect"])  return @(@encode(CGRect));
    if ([structName isEqualToString:@"NSRange"]) return @(@encode(NSRange));
    return [[self getStructNamed:structName] encoding];
}

+ (NSString *)getSignatureEncodingOfStructNamed:(NSString *)structName
{
    return [[self getStructNamed:structName] sig_encoding];
}

#pragma mark - struct data creation

+ (void *)getStructPointerWithName:(NSString *)structName
                          encoding:(NSString *)structEncode
                    fromDictionary:(NSDictionary *)dict
                             error:(NSError **)error
{
    if (![dict isKindOfClass:[NSDictionary class]]) {
        NSError *nserror = [NSError errorWithDomain:JDStructErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"结构体字典数据不是字典结构"}];
        if (*error) *error = nserror;
        return NULL;
    }
    
    JDStructDecl *decl = [JDCustomStruct getStructNamed:structName withEncoding:structEncode];
    if (!decl) {
        NSError *nserror = [NSError errorWithDomain:JDStructErrorDomain code:-2 userInfo:@{NSLocalizedDescriptionKey: @"结构体名为空或不存在该自定义的结构体类型"}];
        if (*error) *error = nserror;
        return NULL;
    }
    
    void *ptrData = (void *)malloc(decl.alignSize);
    [decl constructStructPointer:ptrData fromDictionary:dict];
    return ptrData;
}

+ (NSDictionary *)getStructDictWithName:(NSString *)structName
                               encoding:(NSString *)structEncode
                            fromPointer:(void *)ptrData
                                  error:(NSError **)error
{
    if (!ptrData) {
        NSError *nserror = [NSError errorWithDomain:JDStructErrorDomain code:-3 userInfo:@{NSLocalizedDescriptionKey: @"结构体内存数据为空"}];
        if (*error) *error = nserror;
        return nil;
    }
    
    JDStructDecl *decl = [JDCustomStruct getStructNamed:structName withEncoding:structEncode];
    if (!decl) {
        NSError *nserror = [NSError errorWithDomain:JDStructErrorDomain code:-2 userInfo:@{NSLocalizedDescriptionKey: @"结构体名为空或不存在该自定义的结构体类型"}];
        if (*error) *error = nserror;
        return nil;
    }
    
    NSDictionary *structDataDict = [decl dictionaryFromStructPointer:ptrData];
    return structDataDict;
}

#pragma mark - NSInvocation helper

+ (BOOL)setArgumentStruct:(NSString *)structName
                 encoding:(NSString *)structEncode
                    value:(NSDictionary *)dict
               invocation:(NSInvocation *)invocation
                  atIndex:(NSInteger)argIdx
{
    if (!structName || !invocation) return NO;
    if (![dict isKindOfClass:[NSDictionary class]]) return NO;
    BOOL canHandled = NO;
    JDStructDecl *decl = [JDCustomStruct getStructNamed:structName withEncoding:structEncode];
    if (decl) {
        void *structPtrData = malloc(decl.alignSize);
        [decl constructStructPointer:structPtrData fromDictionary:dict];
        [invocation setArgument:structPtrData atIndex:argIdx];
        if (structPtrData) free(structPtrData);
        canHandled = YES;
    }
    return canHandled;
}

+ (NSDictionary *)getArgumentStruct:(NSString *)structName
                           encoding:(NSString *)structEncode
                         invocation:(NSInvocation *)invocation
                            atIndex:(NSInteger)argIdx
{
    if (!structName || !invocation) return nil;
    NSDictionary *structArgDict;
    JDStructDecl *decl = [JDCustomStruct getStructNamed:structName withEncoding:structEncode];
    if (decl) {
        void *structPtrData = malloc(decl.alignSize);
        [invocation getArgument:structPtrData atIndex:argIdx];
        structArgDict = [decl dictionaryFromStructPointer:structPtrData];
        if (structPtrData) free(structPtrData);
    }
    return structArgDict;
}

+ (NSDictionary *)getReturnStruct:(NSString *)structName
                         encoding:(NSString *)structEncode
                       invocation:(NSInvocation *)invocation
{
    if (!structName || !invocation) return nil;
    NSDictionary *structRetDict;
    JDStructDecl *decl = [JDCustomStruct getStructNamed:structName withEncoding:structEncode];
    if (decl) {
        void *structPtrData = malloc(decl.alignSize);
        [invocation getReturnValue:structPtrData];
        structRetDict = [decl dictionaryFromStructPointer:structPtrData];
        if (structPtrData) free(structPtrData);
    }
    return structRetDict;
}

+ (BOOL)setReturnStruct:(NSString *)structName
               encoding:(NSString *)structEncode
                  value:(NSDictionary *)dict
             invocation:(NSInvocation *)invocation
{
    if (!structName || !invocation) return NO;
    BOOL canHandled = NO;
    JDStructDecl *decl = [JDCustomStruct getStructNamed:structName withEncoding:structEncode];
    if (decl) {
        void *structPtrData = malloc(decl.alignSize);
        [decl constructStructPointer:structPtrData fromDictionary:dict];
        [invocation setReturnValue:structPtrData];
        if (structPtrData) free(structPtrData);
        canHandled = YES;
    }
    return canHandled;
}

@end
