//
//  JDCustomStruct.h
//

#import <Foundation/Foundation.h>



NS_ASSUME_NONNULL_BEGIN

@class JDStructDecl;
@class JDStructVarDecl;

@interface JDStructDecl : NSObject

@property (nonatomic,   copy) NSString *name;   // 结构体名
@property (nonatomic, strong) NSArray<JDStructVarDecl *> *vars; // 结构体包含的变量结构

@property (nonatomic, assign) size_t    size;         // 变量对齐前实际的字节数
@property (nonatomic, assign) size_t    alignSize;    // 对齐后的字节数
@property (nonatomic,   copy) NSString *encoding;     // 变量类型编码
@property (nonatomic,   copy) NSString *sig_encoding; // 变量签名编码（包含内存字节大小）如：d8
@property (nonatomic, strong) NSArray  *varNames;     // 结构体所有的变量名

- (BOOL)isAlignPadding; // 结构体是否使用对齐填充，默认YES
- (NSInteger)numberOfElements; // 结构体中元素的数目
- (NSArray<NSString *> *)typeEncodeOfElements; // 所有元素的类型编码
- (void)__build__;
@end

@interface JDStructVarDecl : NSObject
@property (nonatomic,   copy) NSString *name; // 变量名（key)）
@property (nonatomic, strong) id type;        // 变量类型：NSString(primitive type) or JDStructDecl (struct type)

@property (nonatomic, assign) size_t    size;         // 变量对齐前的字节数
@property (nonatomic, assign) size_t    alignSize;    // 对齐后的字节数
@property (nonatomic,   copy) NSString *encoding;     // 变量类型编码
@property (nonatomic,   copy) NSString *sig_encoding; // 老的变量或方法签名编码方式（包含内存字节大小）如：d8
@property (nonatomic, strong) NSArray  *varNames;     // 结构体所有的变量名

- (BOOL)isStruct;
- (void)__build__;
@end



FOUNDATION_EXTERN NSString *JDStructErrorDomain;

//
//  custom struct
//
@interface JDCustomStruct : NSObject

/**
 结构体声明
 
 格式如下:
 {
 "name": ***    // struct name
 "variables": [ // 结构体变量描述，变量可能是一个结构体
 {
 "name": *** // var name
 "type": *** // var type
 "offset": *** // 变量在结构体中的偏移量
 },
 ...
 ]
 ......
 }
 
 type definitions:
 
 1. type: primitive type (int, char, long, float, double, ....)
 NSString描述
 
 2. type: struct
 NSDictionary描述
 
 3. type: C array 不支持
 NSArray描述 [type, array_numm, kind]
 
 4. type: bit 不支持
 NSArray描述 [type, bit_num, kind]
 
 Eg,
 {
 name: CGRect
 vars: [{name: x, type: double}, {name: y, type: double}, {name: width, type: double}, {name: height, type: double}]
 }
 
 @param structDeclDict 结构体声明字典
 
 */
+ (NSString *)defineStruct:(NSDictionary *)structDeclDict;

+ (NSDictionary *)registeredStructs;

+ (JDStructDecl *)getStructNamed:(NSString *)structName;

// 通过模糊的类型编码获取结构体声明结构
+ (JDStructDecl *)getStructWithFuzzyEncoding:(NSString *)structEncode;

+ (NSInteger)getSizeOfStructNamed:(NSString *)structName;

+ (NSInteger)getSizeOfStructEncoding:(NSString *)structEncode;

// 获取指定结构名称的编码类型
+ (NSString *)getEncodingOfStructNamed:(NSString *)structName;

//
// getSignatureEncodingOfStructNamed与getEncodingOfStructNamed的差异在于：
// 1. getEncodingOfStructNamed仅仅返回结构体的类型编码
// 2. getSignatureEncodingOfStructNamed返回结构体的类型编码加offset布局
//
+ (NSString *)getSignatureEncodingOfStructNamed:(NSString *)structName;


#pragma mark - struct data creation

/**
 用dict信息构造自定义结构体内存数据
 
 * 使用完成后必须释放，否则将导致内存泄露
 
 @param structName      结构体名称
 @param structEncode    结构体的编码类型
 @param dict            结构体对应的字典结构的数据
 @param error           构造自定义结构体数据时产生的错误
 @return                结构体内存数据
 */
+ (void *)getStructPointerWithName:(NSString *)structName
                          encoding:(NSString *)structEncode
                    fromDictionary:(NSDictionary *)dict
                             error:(NSError **)error;


/**
 将结构体内存数组转化为对应字典结构
 
 @param structName      结构体名称
 @param structEncode    结构体的编码类型
 @param ptrData         结构体内存数据
 @param error           构造自定义结构体对应的字典数据时产生的错误信息
 @return                结构体字典结构的数据
 */
+ (NSDictionary *)getStructDictWithName:(NSString *)structName
                               encoding:(NSString *)structEncode
                            fromPointer:(void *)ptrData
                                  error:(NSError **)error;


#pragma mark - invocation helper

// 从NSInvocation(getArgument:atIndex:)读取指定索引的参数值，并转化为对应的字典结构数据
+ (NSDictionary *)getArgumentStruct:(NSString *)structName
                           encoding:(NSString *)structEncode
                         invocation:(NSInvocation *)invocation
                            atIndex:(NSInteger)argIdx;

// 将字典结构数据转化为结构体内存数据，并写入到NSInvocation(setArgument:atIndex:)中
+ (BOOL)setArgumentStruct:(NSString *)structName
                 encoding:(NSString *)structEncode
                    value:(NSDictionary *)dict
               invocation:(NSInvocation *)invocation
                  atIndex:(NSInteger)argIdx;

// 从NSInvocation(getReturnValue)读取返回值，并转化为对应的字典结构数据
+ (NSDictionary *)getReturnStruct:(NSString *)structName
                         encoding:(NSString *)structEncode
                       invocation:(NSInvocation *)invocation;

// 将字典数据转化为结构体内存数据，并写入到NSInvocation(setReturnValue)中
+ (BOOL)setReturnStruct:(NSString *)structName
               encoding:(NSString *)structEncode
                  value:(NSDictionary *)dict
             invocation:(NSInvocation *)invocation;

@end


NS_ASSUME_NONNULL_END
