#define DEBUG_msgSend

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import <LuaSkin/LuaSkin.h>
#import "../hammerspoon.h"
#import "objc.h"
#import <stdlib.h>

#pragma mark - ===== SAMPLE CLASS ====================================================

@interface OBJCTest : NSObject
@property BOOL    lastBool ;
@property NSArray *wordList ;
@end

@implementation OBJCTest
- (id)init {
    self = [super init] ;
    if (self) {
        NSString *string = [NSString stringWithContentsOfFile:@"/usr/share/dict/words"
                                                     encoding:NSASCIIStringEncoding
                                                        error:NULL] ;
        _wordList = [string componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] ;
    }
    return self ;
}

- (BOOL)returnBool           { _lastBool = !_lastBool ; return _lastBool ; }
- (int) returnInt            { return arc4random() ; }
- (char *)returnCString      { return [[_wordList objectAtIndex:arc4random()%[_wordList count]] UTF8String]; }
- (NSString *)returnNSString { return  [_wordList objectAtIndex:arc4random()%[_wordList count]]; }
- (SEL)returnSelector        { return @selector(returnInt) ; }

@end

#pragma mark - ===== CLASS ===========================================================

static int        classRefTable ;
static NSMapTable *classUD ;

static int push_class(lua_State *L, Class cls) {
    if (cls) {
        if (![classUD objectForKey:cls]) {
            void** thePtr = lua_newuserdata(L, sizeof(Class)) ;
    // Don't alter retain count for Class objects
            *thePtr = (__bridge void *)cls ;
            luaL_getmetatable(L, CLASS_USERDATA_TAG) ;
            lua_setmetatable(L, -2) ;
            [classUD setObject:[NSNumber numberWithInt:[[LuaSkin shared] luaRef:classRefTable]]
                        forKey:cls] ;
        }
        [[LuaSkin shared] pushLuaRef:classRefTable ref:[[classUD objectForKey:cls] intValue]] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

#pragma mark - Module Functions

static int objc_classFromString(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TSTRING, LS_TBREAK] ;
    Class cls = (Class)objc_lookUpClass(luaL_checkstring(L, 1)) ;

    push_class(L, cls) ;
    return 1 ;
}

static int objc_classList(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TBREAK] ;

    lua_newtable(L) ;
      UInt  count ;
      Class *classList = objc_copyClassList(&count) ;
      for(UInt i = 0 ; i < count ; i++) {
          push_class(L, classList[i]) ;
          lua_setfield(L, -2, class_getName(classList[i])) ;
      }
      if (classList) free(classList) ;
    return 1 ;
}

#pragma mark - Module Methods

static int objc_class_getMetaClass(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, CLASS_USERDATA_TAG, LS_TBREAK] ;
    Class cls = get_objectFromUserdata(__bridge Class, L, 1, CLASS_USERDATA_TAG) ;

    Class meta = (Class)objc_getMetaClass(class_getName(cls)) ;
    push_class(L, meta) ;
    return 1 ;
}

static int objc_class_getMethodList(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, CLASS_USERDATA_TAG, LS_TBREAK] ;
    Class cls = get_objectFromUserdata(__bridge Class, L, 1, CLASS_USERDATA_TAG) ;

    lua_newtable(L) ;
      UInt   count ;
      Method *methodList = class_copyMethodList(cls, &count) ;
      for(UInt i = 0 ; i < count ; i++) {
          push_method(L, methodList[i]) ;
          lua_setfield(L, -2, sel_getName(method_getName(methodList[i]))) ;
      }
      if (methodList) free(methodList) ;
    return 1 ;
}

static int objc_class_respondsToSelector(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, CLASS_USERDATA_TAG,
                                LS_TUSERDATA, SEL_USERDATA_TAG,
                                LS_TBREAK] ;
    Class cls = get_objectFromUserdata(__bridge Class, L, 1, CLASS_USERDATA_TAG) ;
    SEL sel = get_objectFromUserdata(SEL, L, 2, SEL_USERDATA_TAG) ;

    lua_pushboolean(L, class_respondsToSelector(cls, sel)) ;
    return 1 ;
}

static int objc_class_getInstanceMethod(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, CLASS_USERDATA_TAG,
                                LS_TUSERDATA, SEL_USERDATA_TAG,
                                LS_TBREAK] ;
    Class cls = get_objectFromUserdata(__bridge Class, L, 1, CLASS_USERDATA_TAG) ;
    SEL sel = get_objectFromUserdata(SEL, L, 2, SEL_USERDATA_TAG) ;

    push_method(L, class_getInstanceMethod(cls, sel)) ;
    return 1 ;
}

static int objc_class_getClassMethod(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, CLASS_USERDATA_TAG,
                                LS_TUSERDATA, SEL_USERDATA_TAG,
                                LS_TBREAK] ;
    Class cls = get_objectFromUserdata(__bridge Class, L, 1, CLASS_USERDATA_TAG) ;
    SEL sel = get_objectFromUserdata(SEL, L, 2, SEL_USERDATA_TAG) ;

    push_method(L, class_getClassMethod(cls, sel)) ;
    return 1 ;
}

static int objc_class_getInstanceSize(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, CLASS_USERDATA_TAG, LS_TBREAK] ;
    Class cls = get_objectFromUserdata(__bridge Class, L, 1, CLASS_USERDATA_TAG) ;
    lua_pushinteger(L, (lua_Integer)class_getInstanceSize(cls)) ;
    return 1 ;
}

static int objc_class_getName(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, CLASS_USERDATA_TAG, LS_TBREAK] ;
    Class cls = get_objectFromUserdata(__bridge Class, L, 1, CLASS_USERDATA_TAG) ;
    lua_pushstring(L, class_getName(cls)) ;
    return 1 ;
}

static int objc_class_getIvarLayout(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, CLASS_USERDATA_TAG, LS_TBREAK] ;
    Class cls = get_objectFromUserdata(__bridge Class, L, 1, CLASS_USERDATA_TAG) ;
    lua_pushstring(L, (const char *)class_getIvarLayout(cls)) ;
    return 1 ;
}

static int objc_class_getWeakIvarLayout(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, CLASS_USERDATA_TAG, LS_TBREAK] ;
    Class cls = get_objectFromUserdata(__bridge Class, L, 1, CLASS_USERDATA_TAG) ;
    lua_pushstring(L, (const char *)class_getWeakIvarLayout(cls)) ;
    return 1 ;
}

static int objc_class_getImageName(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, CLASS_USERDATA_TAG, LS_TBREAK] ;
    Class cls = get_objectFromUserdata(__bridge Class, L, 1, CLASS_USERDATA_TAG) ;
    lua_pushstring(L, class_getImageName(cls)) ;
    return 1 ;
}

static int objc_class_isMetaClass(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, CLASS_USERDATA_TAG, LS_TBREAK] ;
    Class cls = get_objectFromUserdata(__bridge Class, L, 1, CLASS_USERDATA_TAG) ;
    lua_pushboolean(L, class_isMetaClass(cls)) ;
    return 1 ;
}

static int objc_class_getSuperClass(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, CLASS_USERDATA_TAG, LS_TBREAK] ;
    Class cls = get_objectFromUserdata(__bridge Class, L, 1, CLASS_USERDATA_TAG) ;
    push_class(L, class_getSuperclass(cls)) ;
    return 1 ;
}

static int objc_class_getVersion(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, CLASS_USERDATA_TAG, LS_TBREAK] ;
    Class cls = get_objectFromUserdata(__bridge Class, L, 1, CLASS_USERDATA_TAG) ;
    lua_pushinteger(L, (lua_Integer)class_getVersion(cls)) ;
    return 1 ;
}

static int objc_class_getPropertyList(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, CLASS_USERDATA_TAG, LS_TBREAK] ;
    Class cls = get_objectFromUserdata(__bridge Class, L, 1, CLASS_USERDATA_TAG) ;

    lua_newtable(L) ;
      UInt            count ;
      objc_property_t *propertyList = class_copyPropertyList(cls, &count) ;
      for(UInt i = 0 ; i < count ; i++) {
          push_property(L, propertyList[i]) ;
          lua_setfield(L, -2, property_getName(propertyList[i])) ;
      }
      if (propertyList) free(propertyList) ;
    return 1 ;
}

static int objc_class_getProperty(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, CLASS_USERDATA_TAG, LS_TSTRING, LS_TBREAK] ;
    Class cls = get_objectFromUserdata(__bridge Class, L, 1, CLASS_USERDATA_TAG) ;
    push_property(L, class_getProperty(cls, luaL_checkstring(L, 2))) ;
    return 1 ;
}

static int objc_class_getIvarList(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, CLASS_USERDATA_TAG, LS_TBREAK] ;
    Class cls = get_objectFromUserdata(__bridge Class, L, 1, CLASS_USERDATA_TAG) ;

    lua_newtable(L) ;
      UInt count ;
      Ivar *ivarList = class_copyIvarList(cls, &count) ;
      for(UInt i = 0 ; i < count ; i++) {
          push_ivar(L, ivarList[i]) ;
          lua_setfield(L, -2, ivar_getName(ivarList[i])) ;
      }
      if (ivarList) free(ivarList) ;
    return 1 ;
}

static int objc_class_getInstanceVariable(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, CLASS_USERDATA_TAG, LS_TSTRING, LS_TBREAK] ;
    Class cls = get_objectFromUserdata(__bridge Class, L, 1, CLASS_USERDATA_TAG) ;
    push_ivar(L, class_getInstanceVariable(cls, luaL_checkstring(L, 2))) ;
    return 1 ;
}

static int objc_class_getClassVariable(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, CLASS_USERDATA_TAG, LS_TSTRING, LS_TBREAK] ;
    Class cls = get_objectFromUserdata(__bridge Class, L, 1, CLASS_USERDATA_TAG) ;
    push_ivar(L, class_getClassVariable(cls, luaL_checkstring(L, 2))) ;
    return 1 ;
}

static int objc_class_getAdoptedProtocols(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, CLASS_USERDATA_TAG, LS_TBREAK] ;
    Class cls = get_objectFromUserdata(__bridge Class, L, 1, CLASS_USERDATA_TAG) ;

    lua_newtable(L) ;
      UInt  count ;
      Protocol * __unsafe_unretained *protocolList = class_copyProtocolList(cls, &count) ;
      for(UInt i = 0 ; i < count ; i++) {
          push_protocol(L, protocolList[i]) ;
          lua_setfield(L, -2, protocol_getName(protocolList[i])) ;
      }
      if (protocolList) free(protocolList) ;
    return 1 ;
}

static int objc_class_conformsToProtocol(lua_State* L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, CLASS_USERDATA_TAG,
                                LS_TUSERDATA, PROTOCOL_USERDATA_TAG, LS_TBREAK] ;
    Class    cls = get_objectFromUserdata(__bridge Class, L, 1, CLASS_USERDATA_TAG) ;
    Protocol *prot = get_objectFromUserdata(__bridge Protocol *, L, 2, PROTOCOL_USERDATA_TAG) ;

    lua_pushboolean(L, class_conformsToProtocol(cls, prot)) ;
    return 1 ;
}

#pragma mark - Lua Framework

static int class_userdata_tostring(lua_State* L) {
    Class cls = get_objectFromUserdata(__bridge Class, L, 1, CLASS_USERDATA_TAG) ;
    lua_pushfstring(L, "%s: %s (%p)", CLASS_USERDATA_TAG, class_getName(cls), cls) ;
    return 1 ;
}

static int class_userdata_eq(lua_State* L) {
    Class cls1 = get_objectFromUserdata(__bridge Class, L, 1, CLASS_USERDATA_TAG) ;
    Class cls2 = get_objectFromUserdata(__bridge Class, L, 2, CLASS_USERDATA_TAG) ;
    lua_pushboolean(L, (cls1 == cls2)) ;
    return 1 ;
}

static int class_userdata_gc(lua_State* L) {
// since we don't retain, we don't need to transfer, but this does check to make sure we're
// not called with the wrong type for some reason...
    Class cls = get_objectFromUserdata(__bridge Class, L, 1, CLASS_USERDATA_TAG) ;
    if ([classUD objectForKey:cls]) {
        [[LuaSkin shared] luaUnref:classRefTable ref:[[classUD objectForKey:cls] intValue]] ;
        [classUD removeObjectForKey:cls] ;
    }

// Clear the pointer so it's no longer dangling
    void** thePtr = lua_touserdata(L, 1);
    *thePtr = nil ;

// Remove the Metatable so future use of the variable in Lua won't think its valid
    lua_pushnil(L) ;
    lua_setmetatable(L, 1) ;

    return 0 ;
}

static int class_meta_gc(lua_State* __unused L) {
    if (classUD) [classUD removeAllObjects] ;
    classUD = nil ;
    return 0 ;
}

// Metatable for userdata objects
static const luaL_Reg class_userdata_metaLib[] = {
    {"imageName",           objc_class_getImageName},
    {"instanceSize",        objc_class_getInstanceSize},
    {"ivarLayout",          objc_class_getIvarLayout},
    {"name",                objc_class_getName},
    {"superclass",          objc_class_getSuperClass},
    {"weakIvarLayout",      objc_class_getWeakIvarLayout},
    {"isMetaClass",         objc_class_isMetaClass},
    {"version",             objc_class_getVersion},
    {"propertyList",        objc_class_getPropertyList},
    {"property",            objc_class_getProperty},
    {"ivarList",            objc_class_getIvarList},
    {"instanceVariable",    objc_class_getInstanceVariable},
    {"classVariable",       objc_class_getClassVariable},
    {"adoptedProtocols",    objc_class_getAdoptedProtocols},
    {"conformsToProtocol",  objc_class_conformsToProtocol},
    {"methodList",          objc_class_getMethodList},
    {"respondsToSelector",  objc_class_respondsToSelector},
    {"instanceMethod",      objc_class_getInstanceMethod},
    {"classMethod",         objc_class_getClassMethod},
    {"metaClass",           objc_class_getMetaClass},

    {"__tostring",          class_userdata_tostring},
    {"__eq",                class_userdata_eq},
    {"__gc",                class_userdata_gc},
    {NULL,                  NULL}
};

// Functions for returned object when module loads
static luaL_Reg class_moduleLib[] = {
    {"fromString", objc_classFromString},
    {"list",       objc_classList},

    {NULL,         NULL}
};

// Metatable for module, if needed
static const luaL_Reg class_module_metaLib[] = {
    {"__gc", class_meta_gc},
    {NULL,   NULL}
};

int luaopen_hs__asm_objc_class(lua_State* __unused L) {
    classUD = [[NSMapTable alloc] init] ;
    classRefTable = [[LuaSkin shared] registerLibraryWithObject:CLASS_USERDATA_TAG
                                                 functions:class_moduleLib
                                             metaFunctions:class_module_metaLib
                                           objectFunctions:class_userdata_metaLib];
    return 1;
}

#pragma mark - ===== IVAR ============================================================

static int        ivarRefTable ;
static NSMapTable *ivarUD ;

static int push_ivar(lua_State *L, Ivar iv) {
    if (iv) {
        if (![ivarUD objectForKey:[NSValue valueWithPointer:(void *)iv]]) {
            void** thePtr = lua_newuserdata(L, sizeof(Ivar)) ;
            *thePtr = (void *)iv ;
            luaL_getmetatable(L, IVAR_USERDATA_TAG) ;
            lua_setmetatable(L, -2) ;
            [ivarUD setObject:[NSNumber numberWithInt:[[LuaSkin shared] luaRef:ivarRefTable]]
                       forKey:[NSValue valueWithPointer:(void *)iv]] ;
        }
        [[LuaSkin shared] pushLuaRef:ivarRefTable ref:[[ivarUD objectForKey:[NSValue valueWithPointer:(void *)iv]] intValue]] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

#pragma mark - Module Functions

#pragma mark - Module Methods

static int objc_ivar_getName(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, IVAR_USERDATA_TAG, LS_TBREAK] ;
    Ivar iv = get_objectFromUserdata(Ivar, L, 1, IVAR_USERDATA_TAG) ;
    lua_pushstring(L, ivar_getName(iv)) ;
    return 1 ;
}

static int objc_ivar_getTypeEncoding(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, IVAR_USERDATA_TAG, LS_TBREAK] ;
    Ivar iv = get_objectFromUserdata(Ivar, L, 1, IVAR_USERDATA_TAG) ;
    lua_pushstring(L, ivar_getTypeEncoding(iv)) ;
    return 1 ;
}

static int objc_ivar_getOffset(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, IVAR_USERDATA_TAG, LS_TBREAK] ;
    Ivar iv = get_objectFromUserdata(Ivar, L, 1, IVAR_USERDATA_TAG) ;
    lua_pushinteger(L, ivar_getOffset(iv)) ;
    return 1 ;
}

#pragma mark - Lua Framework

static int ivar_userdata_tostring(lua_State* L) {
    Ivar iv = get_objectFromUserdata(Ivar, L, 1, IVAR_USERDATA_TAG) ;
    lua_pushfstring(L, "%s: %s (%p)", IVAR_USERDATA_TAG, ivar_getName(iv), iv) ;
    return 1 ;
}

static int ivar_userdata_eq(lua_State* L) {
    Ivar iv1 = get_objectFromUserdata(Ivar, L, 1, IVAR_USERDATA_TAG) ;
    Ivar iv2 = get_objectFromUserdata(Ivar, L, 2, IVAR_USERDATA_TAG) ;
    lua_pushboolean(L, (iv1 == iv2)) ;
    return 1 ;
}

static int ivar_userdata_gc(lua_State* L) {
// check to make sure we're not called with the wrong type for some reason...
    Ivar iv = get_objectFromUserdata(Ivar, L, 1, IVAR_USERDATA_TAG) ;
    if ([ivarUD objectForKey:[NSValue valueWithPointer:(void *)iv]]) {
        [[LuaSkin shared] luaUnref:ivarRefTable ref:[[ivarUD objectForKey:[NSValue valueWithPointer:(void *)iv]] intValue]] ;
        [ivarUD removeObjectForKey:[NSValue valueWithPointer:(void *)iv]] ;
    }

// Clear the pointer so it's no longer dangling
    void** thePtr = lua_touserdata(L, 1);
    *thePtr = nil ;

// Remove the Metatable so future use of the variable in Lua won't think its valid
    lua_pushnil(L) ;
    lua_setmetatable(L, 1) ;

    return 0 ;
}

static int ivar_meta_gc(lua_State* __unused L) {
    if (ivarUD) [ivarUD removeAllObjects] ;
    ivarUD = nil ;
    return 0 ;
}

// Metatable for userdata objects
static const luaL_Reg ivar_userdata_metaLib[] = {
    {"name",         objc_ivar_getName},
    {"typeEncoding", objc_ivar_getTypeEncoding},
    {"offset",       objc_ivar_getOffset},

    {"__tostring",   ivar_userdata_tostring},
    {"__eq",         ivar_userdata_eq},
    {"__gc",         ivar_userdata_gc},
    {NULL,           NULL}
};

// Functions for returned object when module loads
static luaL_Reg ivar_moduleLib[] = {
    {NULL, NULL}
};

// Metatable for module, if needed
static const luaL_Reg ivar_module_metaLib[] = {
    {"__gc", ivar_meta_gc},
    {NULL,   NULL}
};

int luaopen_hs__asm_objc_ivar(lua_State* __unused L) {
    ivarUD = [[NSMapTable alloc] init] ;
    ivarRefTable = [[LuaSkin shared] registerLibraryWithObject:IVAR_USERDATA_TAG
                                                 functions:ivar_moduleLib
                                             metaFunctions:ivar_module_metaLib
                                           objectFunctions:ivar_userdata_metaLib];

    return 1;
}

#pragma mark - ===== METHOD ==========================================================

static int        methodRefTable ;
static NSMapTable *methodUD ;

static int push_method(lua_State *L, Method meth) {
    if (meth) {
        if (![methodUD objectForKey:[NSValue valueWithPointer:(void *)meth]]) {
            void** thePtr = lua_newuserdata(L, sizeof(Method)) ;
            *thePtr = (void *)meth ;
            luaL_getmetatable(L, METHOD_USERDATA_TAG) ;
            lua_setmetatable(L, -2) ;
            int hold = [[LuaSkin shared] luaRef:methodRefTable] ;
            [methodUD setObject:[NSNumber numberWithInt:hold]
                         forKey:[NSValue valueWithPointer:(void *)meth]] ;
        }
        [[LuaSkin shared] pushLuaRef:methodRefTable ref:[[methodUD objectForKey:[NSValue valueWithPointer:(void *)meth]] intValue]] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

#pragma mark - Module Functions

#pragma mark - Module Methods

static int objc_method_getName(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, METHOD_USERDATA_TAG, LS_TBREAK] ;
    Method meth = get_objectFromUserdata(Method, L, 1, METHOD_USERDATA_TAG) ;
    push_selector(L, method_getName(meth)) ;
    return 1 ;
}

static int objc_method_getTypeEncoding(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, METHOD_USERDATA_TAG, LS_TBREAK] ;
    Method meth = get_objectFromUserdata(Method, L, 1, METHOD_USERDATA_TAG) ;
    lua_pushstring(L, method_getTypeEncoding(meth)) ;
    return 1 ;
}

static int objc_method_getReturnType(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, METHOD_USERDATA_TAG, LS_TBREAK] ;
    Method meth = get_objectFromUserdata(Method, L, 1, METHOD_USERDATA_TAG) ;
    const char      *result = method_copyReturnType(meth) ;

    lua_pushstring(L, result) ;
    free((void *)result) ;
    return 1 ;
}

static int objc_method_getArgumentType(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, METHOD_USERDATA_TAG, LS_TNUMBER, LS_TBREAK] ;
    Method meth = get_objectFromUserdata(Method, L, 1, METHOD_USERDATA_TAG) ;
    const char      *result = method_copyArgumentType(meth, (UInt)luaL_checkinteger(L, 2)) ;

    lua_pushstring(L, result) ;
    free((void *)result) ;
    return 1 ;
}

static int objc_method_getNumberOfArguments(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, METHOD_USERDATA_TAG, LS_TBREAK] ;
    Method meth = get_objectFromUserdata(Method, L, 1, METHOD_USERDATA_TAG) ;
    lua_pushinteger(L, method_getNumberOfArguments(meth)) ;
    return 1 ;
}

static int objc_method_getDescription(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, METHOD_USERDATA_TAG, LS_TBREAK] ;
    Method meth = get_objectFromUserdata(Method, L, 1, METHOD_USERDATA_TAG) ;

    struct objc_method_description *result = method_getDescription(meth) ;
    lua_newtable(L) ;
      lua_pushstring(L, result->types) ; lua_setfield(L, -2, "types") ;
      push_selector(L, result->name)   ; lua_setfield(L, -2, "selector") ;
    return 1 ;
}

#pragma mark - Lua Framework

static int method_userdata_tostring(lua_State* L) {
    Method meth = get_objectFromUserdata(Method, L, 1, METHOD_USERDATA_TAG) ;
    lua_pushfstring(L, "%s: %s (%p)", METHOD_USERDATA_TAG, method_getName(meth), meth) ;
    return 1 ;
}

static int method_userdata_eq(lua_State* L) {
    Method meth1 = get_objectFromUserdata(Method, L, 1, METHOD_USERDATA_TAG) ;
    Method meth2 = get_objectFromUserdata(Method, L, 2, METHOD_USERDATA_TAG) ;
    lua_pushboolean(L, (meth1 == meth2)) ;
    return 1 ;
}

static int method_userdata_gc(lua_State* L) {
// check to make sure we're not called with the wrong type for some reason...
    Method meth = get_objectFromUserdata(Method, L, 1, METHOD_USERDATA_TAG) ;
    if ([methodUD objectForKey:[NSValue valueWithPointer:(void *)meth]]) {
        [[LuaSkin shared] luaUnref:methodRefTable ref:[[methodUD objectForKey:[NSValue valueWithPointer:(void *)meth]] intValue]] ;
        [methodUD removeObjectForKey:[NSValue valueWithPointer:(void *)meth]] ;
    }

// Clear the pointer so it's no longer dangling
    void** thePtr = lua_touserdata(L, 1);
    *thePtr = nil ;

// Remove the Metatable so future use of the variable in Lua won't think its valid
    lua_pushnil(L) ;
    lua_setmetatable(L, 1) ;

    return 0 ;
}

static int method_meta_gc(lua_State* __unused L) {
    if (methodUD) [methodUD removeAllObjects] ;
    methodUD = nil ;
    return 0 ;
}

// Metatable for userdata objects
static const luaL_Reg method_userdata_metaLib[] = {
    {"selector",          objc_method_getName},
    {"typeEncoding",      objc_method_getTypeEncoding},
    {"returnType",        objc_method_getReturnType},
    {"argumentType",      objc_method_getArgumentType},
    {"numberOfArguments", objc_method_getNumberOfArguments},
    {"description",       objc_method_getDescription},

    {"__tostring",        method_userdata_tostring},
    {"__eq",              method_userdata_eq},
    {"__gc",              method_userdata_gc},
    {NULL,                NULL}
};

// Functions for returned object when module loads
static luaL_Reg method_moduleLib[] = {
    {NULL, NULL}
};

// Metatable for module, if needed
static const luaL_Reg method_module_metaLib[] = {
    {"__gc", method_meta_gc},
    {NULL,   NULL}
};

int luaopen_hs__asm_objc_method(lua_State* __unused L) {
    methodUD = [[NSMapTable alloc] init] ;
    methodRefTable = [[LuaSkin shared] registerLibraryWithObject:METHOD_USERDATA_TAG
                                                 functions:method_moduleLib
                                             metaFunctions:method_module_metaLib
                                           objectFunctions:method_userdata_metaLib];

    return 1;
}

#pragma mark - ===== OBJECT ==========================================================

static int        objectRefTable ;
static NSMapTable *objectUD ;

static int push_object(lua_State *L, id obj) {
    if (obj) {
        if (![objectUD objectForKey:obj]) {
            void** thePtr = lua_newuserdata(L, sizeof(id)) ;
    // Don't alter retain count for Class objects
            *thePtr = (__bridge_retained void *)obj ;
            luaL_getmetatable(L, ID_USERDATA_TAG) ;
            lua_setmetatable(L, -2) ;
            [objectUD setObject:[NSNumber numberWithInt:[[LuaSkin shared] luaRef:objectRefTable]]
                        forKey:obj] ;
        }
        [[LuaSkin shared] pushLuaRef:objectRefTable ref:[[objectUD objectForKey:obj] intValue]] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

#pragma mark - Module Functions

#pragma mark - Module Methods

static int objc_object_getClassName(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, ID_USERDATA_TAG, LS_TBREAK] ;
    id obj = get_objectFromUserdata(__bridge id, L, 1, ID_USERDATA_TAG) ;
    lua_pushstring(L, object_getClassName(obj)) ;
    return 1 ;
}

static int objc_object_getClass(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, ID_USERDATA_TAG, LS_TBREAK] ;
    id obj = get_objectFromUserdata(__bridge id, L, 1, ID_USERDATA_TAG) ;
    push_class(L, object_getClass(obj)) ;
    return 1 ;
}

static int object_value(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, ID_USERDATA_TAG, LS_TBREAK] ;
    @try {
        id obj = get_objectFromUserdata(__bridge id, L, 1, ID_USERDATA_TAG) ;
        [[LuaSkin shared] pushNSObject:obj] ;
    }
    @catch ( NSException *theException ) {
        return errorOnException(L, ID_USERDATA_TAG, theException) ;
    }
    return 1 ;
}

#pragma mark - Lua Framework

static int object_userdata_tostring(lua_State* L) {
    id obj = get_objectFromUserdata(__bridge id, L, 1, ID_USERDATA_TAG) ;
    lua_pushfstring(L, "%s: %s (%p)", ID_USERDATA_TAG, object_getClassName(obj), obj) ;
    return 1 ;
}

static int object_userdata_eq(lua_State* L) {
    id obj1 = get_objectFromUserdata(__bridge id, L, 1, ID_USERDATA_TAG) ;
    id obj2 = get_objectFromUserdata(__bridge id, L, 2, ID_USERDATA_TAG) ;
    lua_pushboolean(L, [obj1 isEqual:obj2]) ;
    return 1 ;
}

static int object_userdata_gc(lua_State* L) {
// check to make sure we're not called with the wrong type for some reason...
    id obj = get_objectFromUserdata(__bridge_transfer id, L, 1, ID_USERDATA_TAG) ;
    if ([objectUD objectForKey:obj]) {
        [[LuaSkin shared] luaUnref:objectRefTable ref:[[objectUD objectForKey:obj] intValue]] ;
        [objectUD removeObjectForKey:obj] ;
    }
    obj = nil ;

// Clear the pointer so it's no longer dangling
    void** thePtr = lua_touserdata(L, 1);
    *thePtr = nil ;

// Remove the Metatable so future use of the variable in Lua won't think its valid
    lua_pushnil(L) ;
    lua_setmetatable(L, 1) ;

    return 0 ;
}

static int object_meta_gc(lua_State* __unused L) {
    if (objectUD) [objectUD removeAllObjects] ;
    objectUD = nil ;
    return 0 ;
}

// Metatable for userdata objects
static const luaL_Reg object_userdata_metaLib[] = {
    {"class",       objc_object_getClass},
    {"className",   objc_object_getClassName},
    {"value",       object_value},

    {"__tostring", object_userdata_tostring},
    {"__eq",       object_userdata_eq},
    {"__gc",       object_userdata_gc},
    {NULL,         NULL}
};

// Functions for returned obj when module loads
static luaL_Reg object_moduleLib[] = {
    {NULL, NULL}
};

// Metatable for module, if needed
static const luaL_Reg object_module_metaLib[] = {
    {"__gc", object_meta_gc},
    {NULL,   NULL}
};

int luaopen_hs__asm_objc_object(lua_State* __unused L) {
    objectUD = [[NSMapTable alloc] init] ;
    objectRefTable = [[LuaSkin shared] registerLibraryWithObject:ID_USERDATA_TAG
                                                 functions:object_moduleLib
                                             metaFunctions:object_module_metaLib
                                           objectFunctions:object_userdata_metaLib];

    return 1;
}

#pragma mark - ===== PROPERTY ========================================================

static int        propertyRefTable ;
static NSMapTable *propertyUD ;

static int push_property(lua_State *L, objc_property_t prop) {
    if (prop) {
        if (![propertyUD objectForKey:[NSValue valueWithPointer:(void *)prop]]) {
            void** thePtr = lua_newuserdata(L, sizeof(objc_property_t)) ;
            *thePtr = (void *)prop ;
            luaL_getmetatable(L, PROPERTY_USERDATA_TAG) ;
            lua_setmetatable(L, -2) ;
            [propertyUD setObject:[NSNumber numberWithInt:[[LuaSkin shared] luaRef:propertyRefTable]]
                           forKey:[NSValue valueWithPointer:(void *)prop]] ;
        }
        [[LuaSkin shared] pushLuaRef:propertyRefTable ref:[[propertyUD objectForKey:[NSValue valueWithPointer:(void *)prop]] intValue]] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

#pragma mark - Module Functions

#pragma mark - Module Methods

static int objc_property_getName(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, PROPERTY_USERDATA_TAG, LS_TBREAK] ;
    objc_property_t prop = get_objectFromUserdata(objc_property_t, L, 1, PROPERTY_USERDATA_TAG) ;
    lua_pushstring(L, property_getName(prop)) ;
    return 1 ;
}

static int objc_property_getAttributes(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, PROPERTY_USERDATA_TAG, LS_TBREAK] ;
    objc_property_t prop = get_objectFromUserdata(objc_property_t, L, 1, PROPERTY_USERDATA_TAG) ;
    lua_pushstring(L, property_getAttributes(prop)) ;
    return 1 ;
}

static int objc_property_getAttributeValue(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, PROPERTY_USERDATA_TAG, LS_TSTRING, LS_TBREAK] ;
    objc_property_t prop = get_objectFromUserdata(objc_property_t, L, 1, PROPERTY_USERDATA_TAG) ;
    const char      *result = property_copyAttributeValue(prop, luaL_checkstring(L, 2)) ;

    lua_pushstring(L, result) ;
    free((void *)result) ;
    return 1 ;
}

static int objc_property_getAttributeList(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, PROPERTY_USERDATA_TAG, LS_TBREAK] ;
    objc_property_t prop = get_objectFromUserdata(objc_property_t, L, 1, PROPERTY_USERDATA_TAG) ;

    lua_newtable(L) ;
      UInt                      count ;
      objc_property_attribute_t *attributeList = property_copyAttributeList(prop, &count) ;
      for(UInt i = 0 ; i < count ; i++) {
//           lua_newtable(L) ;
//             lua_pushstring(L, attributeList[i].name) ;  lua_setfield(L, -2, "name") ;
//             lua_pushstring(L, attributeList[i].value) ; lua_setfield(L, -2, "value") ;
//           lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
        lua_pushstring(L, attributeList[i].value) ; lua_setfield(L, -2, attributeList[i].name) ;
      }
      free(attributeList) ;
    return 1 ;
}

#pragma mark - Lua Framework

static int property_userdata_tostring(lua_State* L) {
    objc_property_t prop = get_objectFromUserdata(objc_property_t, L, 1, PROPERTY_USERDATA_TAG) ;
    lua_pushfstring(L, "%s: %s (%p)", PROPERTY_USERDATA_TAG, property_getName(prop), prop) ;
    return 1 ;
}

static int property_userdata_eq(lua_State* L) {
    objc_property_t prop1 = get_objectFromUserdata(objc_property_t, L, 1, PROPERTY_USERDATA_TAG) ;
    objc_property_t prop2 = get_objectFromUserdata(objc_property_t, L, 2, PROPERTY_USERDATA_TAG) ;
    lua_pushboolean(L, (prop1 == prop2)) ;
    return 1 ;
}

static int property_userdata_gc(lua_State* L) {
// check to make sure we're not called with the wrong type for some reason...
    objc_property_t prop = get_objectFromUserdata(objc_property_t, L, 1, PROPERTY_USERDATA_TAG) ;
    if ([propertyUD objectForKey:[NSValue valueWithPointer:(void *)prop]]) {
        [[LuaSkin shared] luaUnref:propertyRefTable ref:[[propertyUD objectForKey:[NSValue valueWithPointer:(void *)prop]] intValue]] ;
        [propertyUD removeObjectForKey:[NSValue valueWithPointer:(void *)prop]] ;
    }

// Clear the pointer so its not pointing at anything
    void** thePtr = lua_touserdata(L, 1);
    *thePtr = nil ;

// Remove the Metatable so future use of the variable in Lua won't think its valid
    lua_pushnil(L) ;
    lua_setmetatable(L, 1) ;

    return 0 ;
}

static int property_meta_gc(lua_State* __unused L) {
    if (propertyUD) [propertyUD removeAllObjects] ;
    propertyUD = nil ;
    return 0 ;
}

// Metatable for userdata objects
static const luaL_Reg property_userdata_metaLib[] = {
    {"attributeValue", objc_property_getAttributeValue},
    {"attributes",     objc_property_getAttributes},
    {"name",           objc_property_getName},
    {"attributeList",  objc_property_getAttributeList},

    {"__tostring",     property_userdata_tostring},
    {"__eq",           property_userdata_eq},
    {"__gc",           property_userdata_gc},
    {NULL,             NULL}
};

// Functions for returned object when module loads
static luaL_Reg property_moduleLib[] = {
    {NULL, NULL}
};

// Metatable for module, if needed
static const luaL_Reg property_module_metaLib[] = {
    {"__gc", property_meta_gc},
    {NULL,   NULL}
};

int luaopen_hs__asm_objc_property(lua_State* __unused L) {
    propertyUD = [[NSMapTable alloc] init] ;
    propertyRefTable = [[LuaSkin shared] registerLibraryWithObject:PROPERTY_USERDATA_TAG
                                                 functions:property_moduleLib
                                             metaFunctions:property_module_metaLib
                                           objectFunctions:property_userdata_metaLib];

    return 1;
}

#pragma mark - ===== PROTOCOL ========================================================

static int        protocolRefTable ;
static NSMapTable *protocolUD ;

static int push_protocol(lua_State *L, Protocol *prot) {
    if (prot) {
        if (![protocolUD objectForKey:prot]) {
            void** thePtr = lua_newuserdata(L, sizeof(Protocol *)) ;
    // Don't alter retain count for Protocol objects
            *thePtr = (__bridge void *)prot ;
            luaL_getmetatable(L, PROTOCOL_USERDATA_TAG) ;
            lua_setmetatable(L, -2) ;
            [protocolUD setObject:[NSNumber numberWithInt:[[LuaSkin shared] luaRef:protocolRefTable]]
                           forKey:prot] ;
        }
        [[LuaSkin shared] pushLuaRef:protocolRefTable ref:[[protocolUD objectForKey:prot] intValue]] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

#pragma mark - Module Functions

static int objc_protocolFromString(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TSTRING, LS_TBREAK] ;
    Protocol *prot = objc_getProtocol(luaL_checkstring(L, 1)) ;

    push_protocol(L, prot) ;
    return 1 ;
}

static int objc_protocolList(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TBREAK] ;

    lua_newtable(L) ;
      UInt  count ;
      Protocol * __unsafe_unretained *protocolList = objc_copyProtocolList(&count) ;
      for(UInt i = 0 ; i < count ; i++) {
          push_protocol(L, protocolList[i]) ;
          lua_setfield(L, -2, protocol_getName(protocolList[i])) ;
      }
      if (protocolList) free(protocolList) ;
    return 1 ;
}

#pragma mark - Module Methods

static int objc_protocol_getName(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, PROTOCOL_USERDATA_TAG, LS_TBREAK] ;
    Protocol *prot = get_objectFromUserdata(__bridge Protocol *, L, 1, PROTOCOL_USERDATA_TAG) ;
    lua_pushstring(L, protocol_getName(prot)) ;
    return 1 ;
}

static int objc_protocol_getPropertyList(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, PROTOCOL_USERDATA_TAG, LS_TBREAK] ;
    Protocol *prot = get_objectFromUserdata(__bridge Protocol *, L, 1, PROTOCOL_USERDATA_TAG) ;

    lua_newtable(L) ;
      UInt            count ;
      objc_property_t *propertyList = protocol_copyPropertyList(prot, &count) ;
      for(UInt i = 0 ; i < count ; i++) {
          push_property(L, propertyList[i]) ;
          lua_setfield(L, -2, property_getName(propertyList[i])) ;
      }
      if (propertyList) free(propertyList) ;
    return 1 ;
}

static int objc_protocol_getProperty(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, PROTOCOL_USERDATA_TAG,
                                LS_TSTRING,
                                LS_TBOOLEAN,
                                LS_TBOOLEAN, LS_TBREAK] ;
    Protocol *prot = get_objectFromUserdata(__bridge Protocol *, L, 1, PROTOCOL_USERDATA_TAG) ;
    push_property(L, protocol_getProperty(prot, luaL_checkstring(L, 2),
                                             (BOOL)lua_toboolean(L, 3),
                                             (BOOL)lua_toboolean(L, 4))) ;
    return 1 ;
}


static int objc_protocol_getAdoptedProtocols(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, PROTOCOL_USERDATA_TAG, LS_TBREAK] ;
    Protocol *prot = get_objectFromUserdata(__bridge Protocol *, L, 1, PROTOCOL_USERDATA_TAG) ;

    lua_newtable(L) ;
      UInt  count ;
      Protocol * __unsafe_unretained *protocolList = protocol_copyProtocolList(prot, &count) ;
      for(UInt i = 0 ; i < count ; i++) {
          push_protocol(L, protocolList[i]) ;
          lua_setfield(L, -2, protocol_getName(protocolList[i])) ;
      }
      if (protocolList) free(protocolList) ;
    return 1 ;
}

static int objc_protocol_conformsToProtocol(lua_State* L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, PROTOCOL_USERDATA_TAG,
                                LS_TUSERDATA, PROTOCOL_USERDATA_TAG, LS_TBREAK] ;
    Protocol *prot1 = get_objectFromUserdata(__bridge Protocol *, L, 1, PROTOCOL_USERDATA_TAG) ;
    Protocol *prot2 = get_objectFromUserdata(__bridge Protocol *, L, 2, PROTOCOL_USERDATA_TAG) ;
    lua_pushboolean(L, protocol_conformsToProtocol(prot1, prot2)) ;
    return 1 ;
}

static int objc_protocol_getMethodDescriptionList(lua_State* L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, PROTOCOL_USERDATA_TAG,
                                LS_TBOOLEAN,
                                LS_TBOOLEAN, LS_TBREAK] ;
    Protocol *prot = get_objectFromUserdata(__bridge Protocol *, L, 1, PROTOCOL_USERDATA_TAG) ;
    UInt count ;
    struct objc_method_description *results = protocol_copyMethodDescriptionList(prot,
                                                                (BOOL)lua_toboolean(L, 2),
                                                                (BOOL)lua_toboolean(L, 3),
                                                                      &count) ;
    lua_newtable(L) ;
    for(UInt i = 0 ; i < count ; i++) {
        lua_newtable(L) ;
          lua_pushstring(L, results[i].types) ; lua_setfield(L, -2, "types") ;
          push_selector(L, results[i].name)   ; lua_setfield(L, -2, "selector") ;
//         lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
        lua_setfield(L, -2, sel_getName(results[i].name)) ;
    }
    if (results) free(results) ;
    return 1 ;
}

static int objc_protocol_getMethodDescription(lua_State* L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, PROTOCOL_USERDATA_TAG,
                                LS_TUSERDATA, SEL_USERDATA_TAG,
                                LS_TBOOLEAN,
                                LS_TBOOLEAN, LS_TBREAK] ;
    Protocol *prot = get_objectFromUserdata(__bridge Protocol *, L, 1, PROTOCOL_USERDATA_TAG) ;
    SEL      sel   = get_objectFromUserdata(SEL, L, 2, SEL_USERDATA_TAG) ;

    struct objc_method_description  result = protocol_getMethodDescription(prot, sel,
                                                                (BOOL)lua_toboolean(L, 3),
                                                                (BOOL)lua_toboolean(L, 4)) ;
    if (result.types == NULL || result.name == NULL) {
        lua_pushnil(L) ;
    } else {
        lua_newtable(L) ;
          lua_pushstring(L, result.types) ; lua_setfield(L, -2, "types") ;
          push_selector(L, result.name)   ; lua_setfield(L, -2, "selector") ;
    }
    return 1 ;
}

#pragma mark - Lua Framework

static int protocol_userdata_tostring(lua_State* L) {
    Protocol *prot = get_objectFromUserdata(__bridge Protocol *, L, 1, PROTOCOL_USERDATA_TAG) ;
    lua_pushfstring(L, "%s: %s (%p)", PROTOCOL_USERDATA_TAG, protocol_getName(prot), prot) ;
    return 1 ;
}

static int protocol_userdata_eq(lua_State* L) {
    Protocol *prot1 = get_objectFromUserdata(__bridge Protocol *, L, 1, PROTOCOL_USERDATA_TAG) ;
    Protocol *prot2 = get_objectFromUserdata(__bridge Protocol *, L, 2, PROTOCOL_USERDATA_TAG) ;
    lua_pushboolean(L, protocol_isEqual(prot1, prot2)) ;
    return 1 ;
}

static int protocol_userdata_gc(lua_State* L) {
// since we don't retain, we don't need to transfer, but this does check to make sure we're
// not called with the wrong type for some reason...
    Protocol *prot = get_objectFromUserdata(__bridge Protocol *, L, 1, PROTOCOL_USERDATA_TAG) ;
    if ([protocolUD objectForKey:prot]) {
        [[LuaSkin shared] luaUnref:protocolRefTable ref:[[protocolUD objectForKey:prot] intValue]] ;
        [protocolUD removeObjectForKey:prot] ;
    }

// Clear the pointer so it's no longer dangling
    void** thePtr = lua_touserdata(L, 1);
    *thePtr = nil ;

// Remove the Metatable so future use of the variable in Lua won't think its valid
    lua_pushnil(L) ;
    lua_setmetatable(L, 1) ;

    return 0 ;
}

static int protocol_meta_gc(lua_State* __unused L) {
    if (protocolUD) [protocolUD removeAllObjects] ;
    protocolUD = nil ;
    return 0 ;
}

// Metatable for userdata objects
static const luaL_Reg protocol_userdata_metaLib[] = {
    {"name",                  objc_protocol_getName},
    {"propertyList",          objc_protocol_getPropertyList},
    {"property",              objc_protocol_getProperty},
    {"adoptedProtocols",      objc_protocol_getAdoptedProtocols},
    {"conformsToProtocol",    objc_protocol_conformsToProtocol},
    {"methodDescriptionList", objc_protocol_getMethodDescriptionList},
    {"methodDescription",     objc_protocol_getMethodDescription},

    {"__tostring",            protocol_userdata_tostring},
    {"__eq",                  protocol_userdata_eq},
    {"__gc",                  protocol_userdata_gc},
    {NULL,                    NULL}
};

// Functions for returned object when module loads
static luaL_Reg protocol_moduleLib[] = {
    {"fromString", objc_protocolFromString},
    {"list",       objc_protocolList},

    {NULL,         NULL}
};

// Metatable for module, if needed
static const luaL_Reg protocol_module_metaLib[] = {
    {"__gc", protocol_meta_gc},
    {NULL,   NULL}
};

int luaopen_hs__asm_objc_protocol(lua_State* __unused L) {
    protocolUD = [[NSMapTable alloc] init] ;
    protocolRefTable = [[LuaSkin shared] registerLibraryWithObject:PROTOCOL_USERDATA_TAG
                                                 functions:protocol_moduleLib
                                             metaFunctions:protocol_module_metaLib
                                           objectFunctions:protocol_userdata_metaLib];

    return 1;
}

#pragma mark - ===== SELECTOR ========================================================

static int        selectorRefTable ;
static NSMapTable *selectorUD ;

static int push_selector(lua_State *L, SEL sel) {
    if (sel) {
        if (![selectorUD objectForKey:[NSValue valueWithPointer:(void *)sel]]) {
            void** thePtr = lua_newuserdata(L, sizeof(SEL)) ;
            *thePtr = (void *)sel ;
            luaL_getmetatable(L, SEL_USERDATA_TAG) ;
            lua_setmetatable(L, -2) ;
            [selectorUD setObject:[NSNumber numberWithInt:[[LuaSkin shared] luaRef:selectorRefTable]]
                           forKey:[NSValue valueWithPointer:(void *)sel]] ;
        }
        [[LuaSkin shared] pushLuaRef:selectorRefTable ref:[[selectorUD objectForKey:[NSValue valueWithPointer:(void *)sel]] intValue]] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

#pragma mark - Module Functions

// sel_registerName (which is what NSSelectorFromString uses) creates the selector, even if it doesn't
// exist yet... so, no fromString function here.  See init.lua which adds selector methods to class,
// protocol, and object which check for the selector string in the "current" context without creating
// anything that doesn't already exist yet.

#pragma mark - Module Methods

static int objc_sel_getName(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, SEL_USERDATA_TAG, LS_TBREAK] ;
    SEL sel = get_objectFromUserdata(SEL, L, 1, SEL_USERDATA_TAG) ;
    lua_pushstring(L, sel_getName(sel)) ;
    return 1 ;
}

#pragma mark - Lua Framework

static int selector_userdata_tostring(lua_State* L) {
    SEL sel = get_objectFromUserdata(SEL, L, 1, SEL_USERDATA_TAG) ;
    lua_pushfstring(L, "%s: %s (%p)", SEL_USERDATA_TAG, sel_getName(sel), sel) ;
    return 1 ;
}

static int selector_userdata_eq(lua_State* L) {
    SEL sel1 = get_objectFromUserdata(SEL, L, 1, SEL_USERDATA_TAG) ;
    SEL sel2 = get_objectFromUserdata(SEL, L, 2, SEL_USERDATA_TAG) ;
    lua_pushboolean(L, sel_isEqual(sel1, sel2)) ;
    return 1 ;
}

static int selector_userdata_gc(lua_State* L) {
// check to make sure we're not called with the wrong type for some reason...
    SEL sel = get_objectFromUserdata(SEL, L, 1, SEL_USERDATA_TAG) ;
    if ([selectorUD objectForKey:[NSValue valueWithPointer:(void *)sel]]) {
        [[LuaSkin shared] luaUnref:selectorRefTable ref:[[selectorUD objectForKey:[NSValue valueWithPointer:(void *)sel]] intValue]] ;
        [selectorUD removeObjectForKey:[NSValue valueWithPointer:(void *)sel]] ;
    }

// Clear the pointer so it's no longer dangling
    void** thePtr = lua_touserdata(L, 1);
    *thePtr = nil ;

// Remove the Metatable so future use of the variable in Lua won't think its valid
    lua_pushnil(L) ;
    lua_setmetatable(L, 1) ;

    return 0 ;
}

static int selector_meta_gc(lua_State* __unused L) {
    if (selectorUD) [selectorUD removeAllObjects] ;
    selectorUD = nil ;
    return 0 ;
}

// Metatable for userdata objects
static const luaL_Reg selector_userdata_metaLib[] = {
    {"name",       objc_sel_getName},

    {"__tostring", selector_userdata_tostring},
    {"__eq",       selector_userdata_eq},
    {"__gc",       selector_userdata_gc},
    {NULL,         NULL}
};

// Functions for returned object when module loads
static luaL_Reg selector_moduleLib[] = {
    {NULL, NULL}
};

// Metatable for module, if needed
static const luaL_Reg selector_module_metaLib[] = {
    {"__gc", selector_meta_gc},
    {NULL,   NULL}
};

int luaopen_hs__asm_objc_selector(lua_State* __unused L) {
    selectorUD = [[NSMapTable alloc] init] ;
    selectorRefTable = [[LuaSkin shared] registerLibraryWithObject:SEL_USERDATA_TAG
                                                 functions:selector_moduleLib
                                             metaFunctions:selector_module_metaLib
                                           objectFunctions:selector_userdata_metaLib];

    return 1;
}

#pragma mark - ===== MODULE CORE =====================================================

static int refTable ;

#pragma mark - Module Functions

static int objc_getImageNames(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TBREAK] ;

    lua_newtable(L) ;
      UInt  count ;
      const char **files = objc_copyImageNames(&count) ;
      for(UInt i = 0 ; i < count ; i++) {
          lua_pushstring(L, files[i]) ;
          lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
      }
      if (files) free(files) ;
    return 1 ;
}

static int objc_classNamesForImage(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TSTRING, LS_TBREAK] ;

    lua_newtable(L) ;
      UInt  count ;
      const char **classes = objc_copyClassNamesForImage(luaL_checkstring(L, 1), &count) ;
      for(UInt i = 0 ; i < count ; i++) {
          lua_pushstring(L, classes[i]) ;
          lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
      }
      if (classes) free(classes) ;
    return 1 ;
}

// per /usr/include/objc/message.h:

/* Floating-point-returning Messaging Primitives
 *
 * Use these functions to call methods that return floating-point values
 * on the stack.
 * Consult your local function call ABI documentation for details.
 *
 * arm:    objc_msgSend_fpret not used
 * i386:   objc_msgSend_fpret used for `float`, `double`, `long double`.
 * x86-64: objc_msgSend_fpret used for `long double`.
 *
 * arm:    objc_msgSend_fp2ret not used
 * i386:   objc_msgSend_fp2ret not used
 * x86-64: objc_msgSend_fp2ret used for `_Complex long double`.
 *
 * These functions must be cast to an appropriate function pointer type
 * before being called.
 */

// id                              objc_msgSend(id self, SEL op, ...)
// double                          objc_msgSend_fpret(id self, SEL op, ...)
// void                            objc_msgSend_stret(void * stretAddr, id theReceiver, SEL theSelector, ...)
// id                              objc_msgSendSuper(struct objc_super *super, SEL op, ...)
// void                            objc_msgSendSuper_stret(struct objc_super *super, SEL op, ...)

static int lua_msgSend(lua_State *L) {
    int rcvPos = (lua_type(L, 1) == LUA_TUSERDATA) ? 1 : 2 ;
    int selPos = rcvPos + 1 ;

    BOOL  callSuper = NO ;
    BOOL  rcvIsClass = NO ;
    int   argCount = lua_gettop(L) - selPos ;
    Class cls ;
    id    rcv ;

    if (rcvPos == 2) callSuper = (BOOL)lua_toboolean(L, 1) ;

    if (luaL_testudata(L, rcvPos, CLASS_USERDATA_TAG)) {
        cls = get_objectFromUserdata(__bridge Class, L, rcvPos, CLASS_USERDATA_TAG) ;
        rcv = (id)cls ;
        rcvIsClass = YES ;
    } else if(luaL_testudata(L, rcvPos, ID_USERDATA_TAG)) {
        rcv = get_objectFromUserdata(__bridge id, L, rcvPos, ID_USERDATA_TAG) ;
        cls = object_getClass(rcv) ;
        rcvIsClass = NO ;
    } else {
        luaL_checkudata(L, rcvPos, ID_USERDATA_TAG) ; // use the ID type for the error message
    }
    SEL sel = get_objectFromUserdata(SEL, L, selPos, SEL_USERDATA_TAG) ;

    char *returnType  = method_copyReturnType((rcvIsClass ? class_getClassMethod(cls, sel) :
                                                            class_getInstanceMethod(cls, sel))) ;

    if (!returnType)
        return luaL_error(L, "%s is not a%s method for %s", sel_getName(sel),
                            (rcvIsClass ? " class" : "n instance"), class_getName(cls)) ;

#ifdef DEBUG_msgSend
    lua_getglobal(L, "print") ;
    lua_pushfstring(L, "Class: %s Selector: %s with %d arguments, return type:%s.",
            (callSuper ? class_getName(class_getSuperclass(cls)) : class_getName(cls)),
            sel_getName(sel),
            argCount,
            returnType) ;
    lua_pcall(L, 1, 0, 0) ;
#endif

    @try { // not sure if objc_msgSend used this way supports exceptions, but worth a try...
        switch(returnType[0]) {
            case 'c': {    // char
                char result = (char)objc_msgSend(rcv, sel) ;
                if (result == 0 || result == 1)
                    lua_pushboolean(L, result) ;
                else
                    lua_pushinteger(L, result) ;
                break ;
            }
            case 'C': {    // unsigned char
                unsigned char result = (unsigned char)objc_msgSend(rcv, sel) ;
                if (result == 0 || result == 1)
                    lua_pushboolean(L, result) ;
                else
                    lua_pushinteger(L, result) ;
                break ;
            }
            case 'i': {    // int
                int result = (int)objc_msgSend(rcv, sel) ;
                lua_pushinteger(L, result) ;
                break ;
            }
            case 's': {    // short
                short result = (short)objc_msgSend(rcv, sel) ;
                lua_pushinteger(L, result) ;
                break ;
            }
            case 'l': {    // long
                long result = (long)objc_msgSend(rcv, sel) ;
                lua_pushinteger(L, result) ;
                break ;
            }
            case 'q':      // long long
            case 'Q': {    // unsigned long long (lua can't do unsigned long long; choose bits over magnitude)
                long long result = (long long)objc_msgSend(rcv, sel) ;
                lua_pushinteger(L, result) ;
                break ;
            }
            case 'I': {    // unsigned int
                unsigned int result = (unsigned int)objc_msgSend(rcv, sel) ;
                lua_pushinteger(L, result) ;
                break ;
            }
            case 'S': {    // unsigned short
                unsigned short result = (unsigned short)objc_msgSend(rcv, sel) ;
                lua_pushinteger(L, result) ;
                break ;
            }
            case 'L': {    // unsigned long
                unsigned long result = (unsigned long)objc_msgSend(rcv, sel) ;
                lua_pushinteger(L, (lua_Integer)result) ;
                break ;
            }

            case 'f': {    // float
                float result = (float)objc_msgSend_fpret(rcv, sel) ;
                lua_pushnumber(L, result) ;
                break ;
            }
            case 'd': {    // double
                double result = (double)objc_msgSend_fpret(rcv, sel) ;
                lua_pushnumber(L, result) ;
                break ;
            }

            case 'B': {    // C++ bool or a C99 _Bool
                char result = (char)objc_msgSend(rcv, sel) ;
                lua_pushboolean(L, result) ;
                break ;
            }

            case 'v': {    // void
                (void)objc_msgSend(rcv, sel) ;
                lua_pushnil(L) ;
                break ;
            }

            case '*': {    // char * -- ARC needs to be tricked into this...
                char *result = (char *)((__bridge void *)objc_msgSend(rcv, sel)) ;
                lua_pushstring(L, result) ;
                break ;
            }

            case '@': {    // id
                id result = objc_msgSend(rcv, sel) ;
                push_object(L, result) ;
                break ;
            }

            case '#': {    // Class
                Class result = (Class)objc_msgSend(rcv, sel) ;
                push_class(L, result) ;
                break ;
            }

            case ':': {    // SEL -- ARC needs to be tricked into this...
                SEL result = (SEL)((__bridge void *)objc_msgSend(rcv, sel)) ;
                push_selector(L, result) ;
                break ;
            }

//     [array type]    An array
//     {name=type...}  A structure
//     (name=type...)  A union
//     bnum            A bit field of num bits
//     ^type           A pointer to type
//     ?               An unknown type (among other things, this code is used for function pointers)

            default:
                return luaL_error(L, "return type %s not supported yet", returnType) ;
                break ;
        }
    }
    @catch ( NSException *theException ) {
        return errorOnException(L, "objc_msgSend", theException) ;
    }

    free(returnType) ;

    return 1 ;
}
static int lua_msgSendSuper(lua_State *L) {
    lua_pushboolean(L, YES) ;
    lua_insert(L, 1) ;
    lua_msgSend(L) ;
    return 1 ;
}

#pragma mark - LuaSkin conversion functions

static int NSMethodSignature_toLua(lua_State *L, id obj) {
    NSMethodSignature *sig = obj ;
    lua_newtable(L) ;
      lua_pushstring(L, [sig methodReturnType]) ;                 lua_setfield(L, -2, "methodReturnType") ;
      lua_pushinteger(L, (lua_Integer)[sig methodReturnLength]) ; lua_setfield(L, -2, "methodReturnLength") ;
      lua_pushinteger(L, (lua_Integer)[sig frameLength]) ;        lua_setfield(L, -2, "frameLength") ;
      lua_pushinteger(L, (lua_Integer)[sig numberOfArguments]) ;  lua_setfield(L, -2, "numberOfArguments") ;
      lua_newtable(L) ;
        for (NSUInteger i = 0 ; i < [sig numberOfArguments] ; i++) {
            lua_pushstring(L, [sig getArgumentTypeAtIndex:i]) ; lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
        }
      lua_setfield(L, -2, "arguments") ;

    return 1 ;
}

static int NSException_toLua(lua_State *L, id obj) {
    NSException *theError = obj ;

    lua_newtable(L) ;
      [[LuaSkin shared] pushNSObject:[theError name]] ;                     lua_setfield(L, -2, "name") ;
      [[LuaSkin shared] pushNSObject:[theError reason]] ;                   lua_setfield(L, -2, "reason") ;
      [[LuaSkin shared] pushNSObject:[theError userInfo]] ;                 lua_setfield(L, -2, "userInfo") ;
      [[LuaSkin shared] pushNSObject:[theError callStackReturnAddresses]] ; lua_setfield(L, -2, "callStackReturnAddresses") ;
      [[LuaSkin shared] pushNSObject:[theError callStackSymbols]] ;         lua_setfield(L, -2, "callStackSymbols") ;
    return 1 ;
}

static int tryToRegisterHandlers(__unused lua_State *L) {
    [[LuaSkin shared] registerPushNSHelper:NSMethodSignature_toLua forClass:"NSMethodSignature"] ;
    [[LuaSkin shared] registerPushNSHelper:NSException_toLua       forClass:"NSException"] ;
    return 0 ;
}

#pragma mark - Lua Framework Stuff

static luaL_Reg moduleLib[] = {
    {"objc_msgSend",       lua_msgSend},
    {"objc_msgSendSuper",  lua_msgSendSuper},
    {"imageNames",         objc_getImageNames},
    {"classNamesForImage", objc_classNamesForImage},

    {NULL,                 NULL}
};

int luaopen_hs__asm_objc_internal(lua_State* L) {
   refTable = [[LuaSkin shared] registerLibrary:moduleLib metaFunctions:nil] ;

    lua_pushcfunction(L, tryToRegisterHandlers) ;
    if (lua_pcall(L, 0, 0, 0) != LUA_OK) {
        printToConsole(L, (char *)lua_tostring(L, -1)) ;
        lua_pop(L, 1) ;
    }

    luaopen_hs__asm_objc_class(L) ;    lua_setfield(L, -2, "class") ;
    luaopen_hs__asm_objc_ivar(L) ;     lua_setfield(L, -2, "ivar") ;
    luaopen_hs__asm_objc_method(L) ;   lua_setfield(L, -2, "method") ;
    luaopen_hs__asm_objc_object(L) ;   lua_setfield(L, -2, "object") ;
    luaopen_hs__asm_objc_property(L) ; lua_setfield(L, -2, "property") ;
    luaopen_hs__asm_objc_protocol(L) ; lua_setfield(L, -2, "protocol") ;
    luaopen_hs__asm_objc_selector(L) ; lua_setfield(L, -2, "selector") ;

    return 1;
}
