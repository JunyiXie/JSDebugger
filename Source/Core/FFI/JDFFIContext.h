//
//  JDFFIContext.h
//  JSDebugger
//
//  Created by z on 2018/9/21.
//  Copyright © 2018年 SatanWoo. All rights reserved.
//

#import <JavaScriptCore/JavaScriptCore.h>

@class JDMethodBridge;

FOUNDATION_EXTERN JSValueRef JDCallFunction(JSContextRef ctx, JDMethodBridge *methodBridge,
                                            size_t argumentCount, const JSValueRef arguments[]);
FOUNDATION_EXTERN NSDictionary *JDBuildDictFromStruct(NSString *structName, void *src);
