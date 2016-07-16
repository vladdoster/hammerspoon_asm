//   keep elementSpec function?
//   should circle and arc remain or auto-convert or be removed?

@import Cocoa ;
@import LuaSkin ;

#define USERDATA_TAG "hs._asm.canvas"
static int refTable = LUA_NOREF;

// Can't have "static" or "constant" dynamic NSObjects like NSArray, so define in lua_open
static NSDictionary *languageDictionary ;

#define get_objectFromUserdata(objType, L, idx, tag) (objType*)*((void**)luaL_checkudata(L, idx, tag))
// #define get_structFromUserdata(objType, L, idx, tag) ((objType *)luaL_checkudata(L, idx, tag))
// #define get_cfobjectFromUserdata(objType, L, idx, tag) *((objType *)luaL_checkudata(L, idx, tag))

@interface ASMCanvasWindow : NSPanel <NSWindowDelegate>
@property int                 selfRef ;
@end

@interface ASMCanvasView : NSView
@property int                 mouseCallbackRef ;
@property BOOL                mouseTracking ;
@property BOOL                canvasMouseDown ;
@property BOOL                canvasMouseUp ;
@property BOOL                canvasMouseEnterExit ;
@property BOOL                canvasMouseMove ;
@property NSUInteger          previousTrackedIndex ;
@property NSMutableDictionary *canvasDefaults ;
@property NSMutableArray      *elementList ;
@property NSMutableArray      *elementBounds ;
@property NSAffineTransform   *canvasTransform ;
@end

typedef NS_ENUM(NSInteger, attributeValidity) {
    attributeValid,
    attributeNulling,
    attributeInvalid,
};

#define ALL_TYPES  @[ @"arc", @"circle", @"ellipticalArc", @"image", @"oval", @"points", @"rectangle", @"resetClip", @"segments", @"text", @"canvas" ]
#define VISIBLE    @[ @"arc", @"circle", @"ellipticalArc", @"image", @"oval", @"points", @"rectangle", @"segments", @"text", @"canvas" ]
#define PRIMITIVES @[ @"arc", @"circle", @"ellipticalArc", @"oval", @"points", @"rectangle", @"segments" ]
#define CLOSED     @[ @"arc", @"circle", @"ellipticalArc", @"oval", @"rectangle", @"segments" ]


#define STROKE_JOIN_STYLES @{ \
        @"miter" : @(NSMiterLineJoinStyle), \
        @"round" : @(NSBevelLineJoinStyle), \
        @"bevel" : @(NSBevelLineJoinStyle), \
}

#define STROKE_CAP_STYLES @{ \
        @"butt"   : @(NSButtLineCapStyle), \
        @"round"  : @(NSRoundLineCapStyle), \
        @"square" : @(NSSquareLineCapStyle), \
}

#define COMPOSITING_TYPES @{ \
        @"clear"           : @(NSCompositeClear), \
        @"copy"            : @(NSCompositeCopy), \
        @"sourceOver"      : @(NSCompositeSourceOver), \
        @"sourceIn"        : @(NSCompositeSourceIn), \
        @"sourceOut"       : @(NSCompositeSourceOut), \
        @"sourceAtop"      : @(NSCompositeSourceAtop), \
        @"destinationOver" : @(NSCompositeDestinationOver), \
        @"destinationIn"   : @(NSCompositeDestinationIn), \
        @"destinationOut"  : @(NSCompositeDestinationOut), \
        @"destinationAtop" : @(NSCompositeDestinationAtop), \
        @"XOR"             : @(NSCompositeXOR), \
        @"plusDarker"      : @(NSCompositePlusDarker), \
        @"plusLighter"     : @(NSCompositePlusLighter), \
}

#define WINDING_RULES @{ \
        @"evenOdd" : @(NSEvenOddWindingRule), \
        @"nonZero" : @(NSNonZeroWindingRule), \
}

#pragma mark - Support Functions and Classes

static NSDictionary *defineLanguageDictionary() {
    // the default shadow has no offset or blur radius, so lets setup one that is at least visible
    NSShadow *defaultShadow = [[NSShadow alloc] init] ;
    [defaultShadow setShadowOffset:NSMakeSize(5.0, -5.0)];
    [defaultShadow setShadowBlurRadius:5.0];
//     [defaultShadow setShadowColor:[[NSColor blackColor] colorWithAlphaComponent:0.3]];

    return @{
        @"action" : @{
            @"class"       : @[ [NSString class] ],
            @"luaClass"    : @"string",
            @"default"     : @"strokeAndFill",
            @"values"      : @[ @"stroke", @"fill", @"strokeAndFill", @"clip", @"build", @"skip" ],
            @"nullable" : @(YES),
            @"optionalFor" : ALL_TYPES,
        },
        @"absolutePosition" : @{
            @"class"       : @[ [NSNumber class] ],
            @"luaClass"    : @"boolean",
            @"objCType"    : @(@encode(BOOL)),
            @"nullable"    : @(YES),
            @"default"     : @(YES),
            @"optionalFor" : VISIBLE,
        },
        @"absoluteSize" : @{
            @"class"       : @[ [NSNumber class] ],
            @"luaClass"    : @"boolean",
            @"objCType"    : @(@encode(BOOL)),
            @"nullable"    : @(YES),
            @"default"     : @(YES),
            @"optionalFor" : VISIBLE,
        },
        @"antialias" : @{
            @"class"       : @[ [NSNumber class] ],
            @"luaClass"    : @"boolean",
            @"objCType"    : @(@encode(BOOL)),
            @"nullable"    : @(YES),
            @"default"     : @(YES),
            @"optionalFor" : VISIBLE,
        },
        @"arcRadii" : @{
            @"class"       : @[ [NSNumber class] ],
            @"luaClass"    : @"boolean",
            @"objCType"    : @(@encode(BOOL)),
            @"nullable"    : @(YES),
            @"default"     : @(YES),
            @"optionalFor" : @[ @"arc", @"ellipticalArc" ],
        },
        @"arcClockwise" : @{
            @"class"       : @[ [NSNumber class] ],
            @"luaClass"    : @"boolean",
            @"objCType"    : @(@encode(BOOL)),
            @"nullable"    : @(YES),
            @"default"     : @(YES),
            @"optionalFor" : @[ @"arc", @"ellipticalArc" ],
        },
        @"canvas" : @{
            @"class"       : @[ [ASMCanvasWindow class] ],
            @"luaClass"    : @"hs._asm.canvas object",
            @"nullable"    : @(YES),
            @"default"     : [NSNull null],
            @"requiredFor" : @[ @"canvas" ],
        },
        @"compositeRule" : @{
            @"class"       : @[ [NSString class] ],
            @"luaClass"    : @"string",
            @"values"      : [COMPOSITING_TYPES allKeys],
            @"nullable"    : @(YES),
            @"default"     : @"sourceOver",
            @"optionalFor" : VISIBLE,
        },
        @"center" : @{
            @"class"         : @[ [NSDictionary class] ],
            @"luaClass"      : @"table",
            @"keys"          : @{
                @"x" : @{
                    @"class"    : @[ [NSString class], [NSNumber class] ],
                    @"luaClass" : @"number or string",
                },
                @"y" : @{
                    @"class"    : @[ [NSString class], [NSNumber class] ],
                    @"luaClass" : @"number or string",
                },
            },
            @"default"       : @{
                                   @"x" : @"50%",
                                   @"y" : @"50%",
                               },
            @"nullable"      : @(NO),
            @"requiredFor"   : @[ @"circle", @"arc" ],
        },
        @"closed" : @{
            @"class"       : @[ [NSNumber class] ],
            @"luaClass"    : @"boolean",
            @"objCType"    : @(@encode(BOOL)),
            @"nullable"    : @(NO),
            @"default"     : @(NO),
            @"requiredFor" : @[ @"segments" ],
        },
        @"coordinates" : @{
            @"class"           : @[ [NSArray class] ],
            @"luaClass"        : @"table",
            @"default"         : @[ ],
            @"nullable"        : @(NO),
            @"requiredFor"     : @[ @"segments", @"points" ],
            @"memberClass"     : [NSDictionary class],
            @"memberLuaClass"  : @"point table",
            @"memberClassKeys" : @{
                @"x"   : @{
                    @"class"       : @[ [NSNumber class], [NSString class] ],
                    @"luaClass"    : @"number or string",
                    @"default"     : @"0.0",
                    @"requiredFor" : @[ @"segments", @"points" ],
                    @"nullable"    : @(NO),
                },
                @"y"   : @{
                    @"class"       : @[ [NSNumber class], [NSString class] ],
                    @"luaClass"    : @"number or string",
                    @"default"     : @"0.0",
                    @"requiredFor" : @[ @"segments", @"points" ],
                    @"nullable"    : @(NO),
                },
                @"c1x" : @{
                    @"class"       : @[ [NSNumber class], [NSString class] ],
                    @"luaClass"    : @"number or string",
                    @"default"     : @"0.0",
                    @"optionalFor" : @[ @"segments" ],
                    @"nullable"    : @(YES),
                },
                @"c1y" : @{
                    @"class"       : @[ [NSNumber class], [NSString class] ],
                    @"luaClass"    : @"number or string",
                    @"default"     : @"0.0",
                    @"optionalFor" : @[ @"segments" ],
                    @"nullable"    : @(YES),
                },
                @"c2x" : @{
                    @"class"       : @[ [NSNumber class], [NSString class] ],
                    @"luaClass"    : @"number or string",
                    @"default"     : @"0.0",
                    @"optionalFor" : @[ @"segments" ],
                    @"nullable"    : @(YES),
                },
                @"c2y" : @{
                    @"class"       : @[ [NSNumber class], [NSString class] ],
                    @"luaClass"    : @"number or string",
                    @"default"     : @"0.0",
                    @"optionalFor" : @[ @"segments" ],
                    @"nullable"    : @(YES),
                },
            },
        },
        @"endAngle" : @{
            @"class"       : @[ [NSNumber class] ],
            @"luaClass"    : @"number",
            @"default"     : @(360.0),
            @"nullable"    : @(NO),
            @"requiredFor" : @[ @"arc", @"ellipticalArc" ],
        },
        @"fillColor" : @{
            @"class"       : @[ [NSColor class] ],
            @"luaClass"    : @"hs.drawing.color table",
            @"nullable"    : @(YES),
            @"default"     : [NSColor redColor],
            @"optionalFor" : CLOSED,
        },
        @"fillGradient" : @{
            @"class"       : @[ [NSString class] ],
            @"luaClass"    : @"string",
            @"values"      : @[
                                   @"none",
                                   @"linear",
                                   @"radial",
                             ],
            @"nullable"    : @(YES),
            @"default"     : @"none",
            @"optionalFor" : CLOSED,
        },
        @"fillGradientAngle"  : @{
            @"class"       : @[ [NSNumber class] ],
            @"luaClass"    : @"number",
            @"nullable"    : @(YES),
            @"default"     : @(0.0),
            @"optionalFor" : CLOSED,
        },
        @"fillGradientCenter" : @{
            @"class"         : @[ [NSDictionary class] ],
            @"luaClass"      : @"table",
            @"keys"          : @{
                @"x" : @{
                    @"class"     : @[ [NSNumber class] ],
                    @"luaClass"  : @"number",
                    @"maxNumber" : @(1.0),
                    @"minNumber" : @(-1.0),
                },
                @"y" : @{
                    @"class"    : @[ [NSNumber class] ],
                    @"luaClass" : @"number",
                    @"maxNumber" : @(1.0),
                    @"minNumber" : @(-1.0),
                },
            },
            @"default"       : @{
                                   @"x" : @(0.0),
                                   @"y" : @(0.0),
                               },
            @"nullable"      : @(YES),
            @"optionalFor"   : CLOSED,
        },
        @"fillGradientColors" : @{
            @"class"       : @[ [NSDictionary class] ],
            @"luaClass"    : @"table",
            @"keys"        : @{
                @"startColor" : @{
                    @"class"    : @[ [NSColor class] ],
                    @"luaClass" : @"hs.drawing.color table",
                },
                @"endColor" : @{
                    @"class"    : @[ [NSColor class] ],
                    @"luaClass" : @"hs.drawing.color table",
                },
            },
            @"default"     : @{
                                 @"startColor" : [NSColor blackColor],
                                 @"endColor"   : [NSColor whiteColor],
                             },
            @"nullable"    : @(YES),
            @"optionalFor" : CLOSED,
        },
        @"flatness" : @{
            @"class"       : @[ [NSNumber class] ],
            @"luaClass"    : @"number",
            @"nullable"    : @(YES),
            @"default"     : @([NSBezierPath defaultFlatness]),
            @"optionalFor" : PRIMITIVES,
        },
        @"flattenPath" : @{
            @"class"       : @[ [NSNumber class] ],
            @"luaClass"    : @"boolean",
            @"objCType"    : @(@encode(BOOL)),
            @"nullable"    : @(YES),
            @"default"     : @(NO),
            @"optionalFor" : PRIMITIVES,
        },
        @"frame" : @{
            @"class"         : @[ [NSDictionary class] ],
            @"luaClass"      : @"table",
            @"keys"          : @{
                @"x" : @{
                    @"class"    : @[ [NSString class], [NSNumber class] ],
                    @"luaClass" : @"number or string",
                },
                @"y" : @{
                    @"class"    : @[ [NSString class], [NSNumber class] ],
                    @"luaClass" : @"number or string",
                },
                @"h" : @{
                    @"class"    : @[ [NSString class], [NSNumber class] ],
                    @"luaClass" : @"number or string",
                },
                @"w" : @{
                    @"class"    : @[ [NSString class], [NSNumber class] ],
                    @"luaClass" : @"number or string",
                },
            },
            @"default"       : @{
                                   @"x" : @"0%",
                                   @"y" : @"0%",
                                   @"h" : @"100%",
                                   @"w" : @"100%",
                               },
            @"nullable"      : @(NO),
            @"requiredFor"   : @[ @"rectangle", @"oval", @"ellipticalArc", @"text", @"image", @"canvas" ],
        },
        @"id" : @{
            @"class"       : @[ [NSString class], [NSNumber class] ],
            @"luaClass"    : @"string or number",
            @"nullable"    : @(YES),
            @"optionalFor" : VISIBLE,
        },
        @"image" : @{
            @"class"       : @[ [NSImage class] ],
            @"luaClass"    : @"hs.image object",
            @"nullable"    : @(YES),
            @"default"     : [[NSImage alloc] initWithSize:NSMakeSize(1.0, 1.0)],
            @"optionalFor" : @[ @"image" ],
        },
        @"miterLimit" : @{
            @"class"       : @[ [NSNumber class] ],
            @"luaClass"    : @"number",
            @"default"     : @([NSBezierPath defaultMiterLimit]),
            @"nullable"    : @(YES),
            @"optionalFor" : PRIMITIVES,
        },
        @"padding" : @{
            @"class"       : @[ [NSNumber class] ],
            @"luaClass"    : @"number",
            @"default"     : @(0.0),
            @"nullable"    : @(YES),
            @"optionalFor" : VISIBLE,
        },
        @"radius" : @{
            @"class"       : @[ [NSNumber class], [NSString class] ],
            @"luaClass"    : @"number or string",
            @"nullable"    : @(NO),
            @"default"     : @"50%",
            @"requiredFor" : @[ @"arc", @"circle" ],
        },
        @"reversePath" : @{
            @"class"       : @[ [NSNumber class] ],
            @"luaClass"    : @"boolean",
            @"objCType"    : @(@encode(BOOL)),
            @"nullable"    : @(YES),
            @"default"     : @(NO),
            @"optionalFor" : PRIMITIVES,
        },
        @"roundedRectRadii" : @{
            @"class"         : @[ [NSDictionary class] ],
            @"luaClass"      : @"table",
            @"keys"          : @{
                @"xRadius" : @{
                    @"class"    : @[ [NSNumber class] ],
                    @"luaClass" : @"number",
                },
                @"yRadius" : @{
                    @"class"    : @[ [NSNumber class] ],
                    @"luaClass" : @"number",
                },
            },
            @"default"       : @{
                                   @"xRadius" : @(0.0),
                                   @"yRadius" : @(0.0),
                               },
            @"nullable"      : @(YES),
            @"optionalFor"   : @[ @"rectangle" ],
        },
        @"shadow" : @{
            @"class"       : @[ [NSShadow class] ],
            @"luaClass"    : @"shadow table",
            @"nullable"    : @(YES),
            @"default"     : defaultShadow,
            @"optionalFor" : PRIMITIVES,
        },
        @"startAngle" : @{
            @"class"       : @[ [NSNumber class] ],
            @"luaClass"    : @"number",
            @"default"     : @(0.0),
            @"nullable"    : @(NO),
            @"requiredFor" : @[ @"arc", @"ellipticalArc" ],
        },
        @"strokeCapStyle" : @{
            @"class"       : @[ [NSString class] ],
            @"luaClass"    : @"string",
            @"values"      : [STROKE_CAP_STYLES allKeys],
            @"nullable"    : @(YES),
            @"default"     : @"butt",
            @"optionalFor" : PRIMITIVES,
        },
        @"strokeColor" : @{
            @"class"       : @[ [NSColor class] ],
            @"luaClass"    : @"hs.drawing.color table",
            @"nullable"    : @(YES),
            @"default"     : [NSColor blackColor],
            @"optionalFor" : PRIMITIVES,
        },
        @"strokeDashPattern" : @{
            @"class"          : @[ [NSArray class] ],
            @"luaClass"       : @"table",
            @"nullable"       : @(YES),
            @"default"        : @[ ],
            @"memberClass"    : [NSNumber class],
            @"memberLuaClass" : @"number",
            @"optionalFor"    : PRIMITIVES,
        },
        @"strokeDashPhase" : @{
            @"class"       : @[ [NSNumber class] ],
            @"luaClass"    : @"number",
            @"default"     : @(0.0),
            @"nullable"    : @(YES),
            @"optionalFor" : PRIMITIVES,
        },
        @"strokeJoinStyle" : @{
            @"class"       : @[ [NSString class] ],
            @"luaClass"    : @"string",
            @"values"      : [STROKE_JOIN_STYLES allKeys],
            @"nullable"    : @(YES),
            @"default"     : @"miter",
            @"optionalFor" : PRIMITIVES,
        },
        @"strokeWidth" : @{
            @"class"       : @[ [NSNumber class] ],
            @"luaClass"    : @"number",
            @"default"     : @([NSBezierPath defaultLineWidth]),
            @"nullable"    : @(YES),
            @"optionalFor" : PRIMITIVES,
        },
        @"text" : @{
            @"class"       : @[ [NSString class], [NSNumber class], [NSAttributedString class] ],
            @"luaClass"    : @"string or hs.styledText object",
            @"default"     : @"",
            @"nullable"    : @(YES),
            @"requiredFor" : @[ @"text" ],
        },
        @"textColor" : @{
            @"class"       : @[ [NSColor class] ],
            @"luaClass"    : @"hs.drawing.color table",
            @"nullable"    : @(YES),
            @"default"     : [NSColor colorWithCalibratedWhite:1.0 alpha:1.0],
            @"optionalFor" : @[ @"text" ],
        },
        @"textFont" : @{
            @"class"       : @[ [NSString class] ],
            @"luaClass"    : @"string",
            @"nullable"    : @(YES),
            @"default"     : [[NSFont systemFontOfSize: 27] fontName],
            @"optionalFor" : @[ @"text" ],
        },
        @"textSize" : @{
            @"class"       : @[ [NSNumber class] ],
            @"luaClass"    : @"number",
            @"nullable"    : @(YES),
            @"default"     : @(27.0),
            @"optionalFor" : @[ @"text" ],
        },
        @"trackMouseEnterExit" : @{
            @"class"       : @[ [NSNumber class] ],
            @"luaClass"    : @"boolean",
            @"objCType"    : @(@encode(BOOL)),
            @"nullable"    : @(YES),
            @"default"     : @(NO),
            @"optionalFor" : VISIBLE,
        },
        @"trackMouseDown" : @{
            @"class"       : @[ [NSNumber class] ],
            @"luaClass"    : @"boolean",
            @"objCType"    : @(@encode(BOOL)),
            @"nullable"    : @(YES),
            @"default"     : @(NO),
            @"optionalFor" : VISIBLE,
        },
        @"trackMouseUp" : @{
            @"class"       : @[ [NSNumber class] ],
            @"luaClass"    : @"boolean",
            @"objCType"    : @(@encode(BOOL)),
            @"nullable"    : @(YES),
            @"default"     : @(NO),
            @"optionalFor" : VISIBLE,
        },
        @"trackMouseMove" : @{
            @"class"       : @[ [NSNumber class] ],
            @"luaClass"    : @"boolean",
            @"objCType"    : @(@encode(BOOL)),
            @"nullable"    : @(YES),
            @"default"     : @(NO),
            @"optionalFor" : VISIBLE,
        },
        @"transformation" : @{
            @"class"       : @[ [NSAffineTransform class] ],
            @"luaClass"    : @"transform table",
            @"nullable"    : @(YES),
            @"default"     : [NSAffineTransform transform],
            @"optionalFor" : VISIBLE,
        },
        @"type" : @{
            @"class"       : @[ [NSString class] ],
            @"luaClass"    : @"string",
            @"values"      : ALL_TYPES,
            @"nullable"    : @(NO),
            @"requiredFor" : ALL_TYPES,
        },
        @"windingRule" : @{
            @"class"       : @[ [NSString class] ],
            @"luaClass"    : @"string",
            @"values"      : [WINDING_RULES allKeys],
            @"nullable"    : @(YES),
            @"default"     : @"nonZero",
            @"optionalFor" : PRIMITIVES,
        },
        @"withShadow" : @{
            @"class"       : @[ [NSNumber class] ],
            @"luaClass"    : @"boolean",
            @"objCType"    : @(@encode(BOOL)),
            @"nullable"    : @(YES),
            @"default"     : @(NO),
            @"optionalFor" : PRIMITIVES,
        },
    } ;
}


static attributeValidity isValueValidForDictionary(NSString *keyName, id keyValue, NSDictionary *attributeDefinition) {
    __block attributeValidity validity = attributeValid ;
    __block NSString          *errorMessage ;

    BOOL checked = NO ;
    while (!checked) {  // doing this as a loop so we can break out as soon as we know enough
        checked = YES ; // but we really don't want to loop

        if (!keyValue || [keyValue isKindOfClass:[NSNull class]]) {
            if (attributeDefinition[@"nullable"] && [attributeDefinition[@"nullable"] boolValue]) {
                validity = attributeNulling ;
            } else {
                errorMessage = [NSString stringWithFormat:@"%@ is not nullable", keyName] ;
            }
            break ;
        }

        if ([attributeDefinition[@"class"] isKindOfClass:[NSArray class]]) {
            BOOL found = NO ;
            for (NSUInteger i = 0 ; i < [attributeDefinition[@"class"] count] ; i++) {
                found = [keyValue isKindOfClass:attributeDefinition[@"class"][i]] ;
                if (found) break ;
            }
            if (!found) {
                errorMessage = [NSString stringWithFormat:@"%@ must be a %@", keyName, attributeDefinition[@"luaClass"]] ;
                break ;
            }
        } else {
            if (![keyValue isKindOfClass:attributeDefinition[@"class"]]) {
                errorMessage = [NSString stringWithFormat:@"%@ must be a %@", keyName, attributeDefinition[@"luaClass"]] ;
                break ;
            }
        }

        if (attributeDefinition[@"objCType"]) {
            if (strcmp([attributeDefinition[@"objCType"] UTF8String], [keyValue objCType])) {
                errorMessage = [NSString stringWithFormat:@"%@ must be a %@", keyName, attributeDefinition[@"luaClass"]] ;
                break ;
            }
        }

        if (attributeDefinition[@"values"]) {
            BOOL found = NO ;
            for (NSUInteger i = 0 ; i < [attributeDefinition[@"values"] count] ; i++) {
                found = [attributeDefinition[@"values"][i] isEqualToString:keyValue] ;
                if (found) break ;
            }
            if (!found) {
                errorMessage = [NSString stringWithFormat:@"%@ must be one of %@", keyName, [attributeDefinition[@"values"] componentsJoinedByString:@", "]] ;
                break ;
            }
        }

        if (attributeDefinition[@"maxNumber"]) {
            if ([keyValue doubleValue] > [attributeDefinition[@"maxNumber"] doubleValue]) {
                errorMessage = [NSString stringWithFormat:@"%@ must be <= %f", keyName, [attributeDefinition[@"maxNumber"] doubleValue]] ;
                break ;
            }
        }

        if (attributeDefinition[@"minNumber"]) {
            if ([keyValue doubleValue] < [attributeDefinition[@"minNumber"] doubleValue]) {
                errorMessage = [NSString stringWithFormat:@"%@ must be >= %f", keyName, [attributeDefinition[@"minNumber"] doubleValue]] ;
                break ;
            }
        }

        if ([keyValue isKindOfClass:[NSDictionary class]]) {
            NSDictionary *subKeys = attributeDefinition[@"keys"] ;
            for (NSString *subKeyName in subKeys) {
                NSDictionary *subKeyMiniDefinition = subKeys[subKeyName] ;
                if ([subKeyMiniDefinition[@"class"] isKindOfClass:[NSArray class]]) {
                    BOOL found = NO ;
                    for (NSUInteger i = 0 ; i < [subKeyMiniDefinition[@"class"] count] ; i++) {
                        found = [keyValue[subKeyName] isKindOfClass:subKeyMiniDefinition[@"class"][i]] ;
                        if (found) break ;
                    }
                    if (!found) {
                        errorMessage = [NSString stringWithFormat:@"field %@ of %@ must be a %@", subKeyName, keyName, subKeyMiniDefinition[@"luaClass"]] ;
                        break ;
                    }
                } else {
                    if (![keyValue[subKeyName] isKindOfClass:subKeyMiniDefinition[@"class"]]) {
                        errorMessage = [NSString stringWithFormat:@"field %@ of %@ must be a %@", subKeyName, keyName, subKeyMiniDefinition[@"luaClass"]] ;
                        break ;
                    }
                }

                if (subKeyMiniDefinition[@"objCType"]) {
                    if (strcmp([subKeyMiniDefinition[@"objCType"] UTF8String], [keyValue[subKeyName] objCType])) {
                        errorMessage = [NSString stringWithFormat:@"field %@ of %@ must be a %@", subKeyName, keyName, subKeyMiniDefinition[@"luaClass"]] ;
                        break ;
                    }
                }

                if (subKeyMiniDefinition[@"values"]) {
                    BOOL found = NO ;
                    NSString *subKeyValue = keyValue[subKeyName] ;
                    for (NSUInteger i = 0 ; i < [subKeyMiniDefinition[@"values"] count] ; i++) {
                        found = [subKeyMiniDefinition[@"values"][i] isEqualToString:subKeyValue] ;
                        if (found) break ;
                    }
                    if (!found) {
                        errorMessage = [NSString stringWithFormat:@"field %@ of %@ must be one of %@", subKeyName, keyName, [subKeyMiniDefinition[@"values"] componentsJoinedByString:@", "]] ;
                        break ;
                    }
                }

                if (subKeyMiniDefinition[@"maxNumber"]) {
                    if ([keyValue[subKeyName] doubleValue] > [subKeyMiniDefinition[@"maxNumber"] doubleValue]) {
                        errorMessage = [NSString stringWithFormat:@"field %@ of %@ must be <= %f", subKeyName, keyName, [subKeyMiniDefinition[@"maxNumber"] doubleValue]] ;
                        break ;
                    }
                }

                if (subKeyMiniDefinition[@"minNumber"]) {
                    if ([keyValue[subKeyName] doubleValue] < [subKeyMiniDefinition[@"minNumber"] doubleValue]) {
                        errorMessage = [NSString stringWithFormat:@"field %@ of %@ must be >= %f", subKeyName, keyName, [subKeyMiniDefinition[@"minNumber"] doubleValue]] ;
                        break ;
                    }
                }

            }
            if (errorMessage) break ;
        }

        if ([keyValue isKindOfClass:[NSArray class]]) {
            BOOL isGood = YES ;
            if ([keyValue count] > 0) {
                for (NSUInteger i = 0 ; i < [keyValue count] ; i++) {
                    if (![keyValue[i] isKindOfClass:attributeDefinition[@"memberClass"]]) {
                        isGood = NO ;
                        break ;
                    } else if ([keyValue[i] isKindOfClass:[NSDictionary class]]) {
                        [keyValue[i] enumerateKeysAndObjectsUsingBlock:^(NSString *subKey, id obj, BOOL *stop) {
                            NSDictionary *subKeyDefinition = attributeDefinition[@"memberClassKeys"][subKey] ;
                            if (subKeyDefinition) {
                                validity = isValueValidForDictionary(subKey, obj, subKeyDefinition) ;
                            } else {
                                validity = attributeInvalid ;
                                errorMessage = [NSString stringWithFormat:@"%@ is not a valid subkey for a %@ value", subKey, attributeDefinition[@"memberLuaClass"]] ;
                            }
                            if (validity != attributeValid) *stop = YES ;
                        }] ;
                    }
                }
                if (!isGood) {
                    errorMessage = [NSString stringWithFormat:@"%@ must be an array of %@ values", keyName, attributeDefinition[@"memberLuaClass"]] ;
                    break ;
                }
            }
        }
    }
    if (errorMessage) {
        [LuaSkin logError:[NSString stringWithFormat:@"%s:%@", USERDATA_TAG, errorMessage]] ;
        validity = attributeInvalid ;
    }
    return validity ;
}

static attributeValidity isValueValidForAttribute(NSString *keyName, id keyValue) {
    NSDictionary      *attributeDefinition = languageDictionary[keyName] ;
    if (attributeDefinition) {
        return isValueValidForDictionary(keyName, keyValue, attributeDefinition) ;
    } else {
        [LuaSkin logError:[NSString stringWithFormat:@"%s:%@ is not a valid canvas attribute", USERDATA_TAG, keyName]] ;
        return attributeInvalid ;
    }
}

static NSNumber *convertPercentageStringToNumber(NSString *stringValue) {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.locale = [NSLocale currentLocale] ;
    formatter.numberStyle = NSNumberFormatterDecimalStyle ;

    NSNumber *tmpValue = [formatter numberFromString:stringValue] ;
    if (!tmpValue) {
        formatter.numberStyle = NSNumberFormatterPercentStyle ;
        tmpValue = [formatter numberFromString:stringValue] ;
    }
    return tmpValue ;
}

static inline NSRect RectWithFlippedYCoordinate(NSRect theRect) {
    return NSMakeRect(theRect.origin.x,
                      [[NSScreen screens][0] frame].size.height - theRect.origin.y - theRect.size.height,
                      theRect.size.width,
                      theRect.size.height) ;
}

static int canvas_orderHelper(lua_State *L, NSWindowOrderingMode mode) {
    LuaSkin *skin = [LuaSkin shared];
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TBREAK | LS_TVARARG] ;

    ASMCanvasWindow *canvasWindow = [skin luaObjectAtIndex:1 toClass:"ASMCanvasWindow"] ;
    NSInteger       relativeTo = 0 ;

    if (lua_gettop(L) > 1) {
        [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                        LS_TUSERDATA, USERDATA_TAG,
                        LS_TBREAK] ;
        relativeTo = [[skin luaObjectAtIndex:2 toClass:"ASMCanvasWindow"] windowNumber] ;
    }

    [canvasWindow orderWindow:mode relativeTo:relativeTo] ;

    lua_pushvalue(L, 1);
    return 1 ;
}

static int userdata_gc(lua_State* L) ;

#pragma mark -
@implementation ASMCanvasWindow
- (instancetype)initWithContentRect:(NSRect)contentRect
                          styleMask:(NSUInteger)windowStyle
                            backing:(NSBackingStoreType)bufferingType
                              defer:(BOOL)deferCreation {

    LuaSkin *skin = [LuaSkin shared];

    if (!(isfinite(contentRect.origin.x) && isfinite(contentRect.origin.y) && isfinite(contentRect.size.height) && isfinite(contentRect.size.width))) {
        [skin logError:[NSString stringWithFormat:@"%s: non-finite co-ordinates/size specified", USERDATA_TAG]];
        return nil;
    }

    self = [super initWithContentRect:contentRect
                            styleMask:windowStyle
                              backing:bufferingType
                                defer:deferCreation];
    if (self) {
        _selfRef = LUA_NOREF ;

        [self setDelegate:self];

        [self setFrameOrigin:RectWithFlippedYCoordinate(contentRect).origin];

        // Configure the window
        self.releasedWhenClosed = NO;
        self.backgroundColor    = [NSColor clearColor];
        self.opaque             = NO;
        self.hasShadow          = NO;
        self.ignoresMouseEvents = YES;
        self.restorable         = NO;
        self.hidesOnDeactivate  = NO;
        self.animationBehavior  = NSWindowAnimationBehaviorNone;
        self.level              = NSScreenSaverWindowLevel;
    }
    return self;
}

- (BOOL)shouldDelayWindowOrderingForEvent:(__unused NSEvent *)theEvent {
    [LuaSkin logWarn:@"yeah, I'm needed"] ;
    return NO ;
}

#pragma mark - NSWindowDelegate Methods

- (BOOL)windowShouldClose:(id __unused)sender {
    return NO;
}

#pragma mark - Window Animation Methods

- (void)fadeIn:(NSTimeInterval)fadeTime {
    [self setAlphaValue:0.0];
    [self makeKeyAndOrderFront:nil];
    [NSAnimationContext beginGrouping];
      [[NSAnimationContext currentContext] setDuration:fadeTime];
      [[self animator] setAlphaValue:1.0];
    [NSAnimationContext endGrouping];
}

- (void)fadeOut:(NSTimeInterval)fadeTime andDelete:(BOOL)deleteCanvas {
    [NSAnimationContext beginGrouping];
#if __has_feature(objc_arc)
      __weak ASMCanvasWindow *bself = self; // in ARC, __block would increase retain count
#else
      __block ASMCanvasWindow *bself = self;
#endif
      [[NSAnimationContext currentContext] setDuration:fadeTime];
      [[NSAnimationContext currentContext] setCompletionHandler:^{
          // unlikely that bself will go to nil after this starts, but this keeps the warnings down from [-Warc-repeated-use-of-weak]
          ASMCanvasWindow *mySelf = bself ;
          if (mySelf) {
              if (deleteCanvas) {
              LuaSkin *skin = [LuaSkin shared] ;
                  lua_State *L = [skin L] ;
                  lua_pushcfunction(L, userdata_gc) ;
                  [skin pushLuaRef:refTable ref:mySelf.selfRef] ;
                  if (lua_pcall(L, 1, 0, 0) != LUA_OK) {
                      [skin logBreadcrumb:[NSString stringWithFormat:@"%s:error invoking _gc for delete (with fade) method:%s", USERDATA_TAG, lua_tostring(L, -1)]] ;
                      lua_pop(L, 1) ;
                      [mySelf close] ;  // the least we can do is close the canvas if an error occurs with __gc
                  }
              } else {
                  [mySelf orderOut:nil];
                  [mySelf setAlphaValue:1.0];
              }
          }
      }];
      [[self animator] setAlphaValue:0.0];
    [NSAnimationContext endGrouping];
}
@end

#pragma mark -
@implementation ASMCanvasView
- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        _mouseCallbackRef = LUA_NOREF;
        _canvasDefaults   = [[NSMutableDictionary alloc] init] ;
        _elementList      = [[NSMutableArray alloc] init] ;
        _elementBounds    = [[NSMutableArray alloc] init] ;
        _canvasTransform  = [NSAffineTransform transform] ;

        _canvasMouseDown      = NO ;
        _canvasMouseUp        = NO ;
        _canvasMouseEnterExit = NO ;
        _canvasMouseMove      = NO ;

        _mouseTracking        = NO ;
        _previousTrackedIndex = NSNotFound ;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wassign-enum"
        [self addTrackingArea:[[NSTrackingArea alloc] initWithRect:frameRect
                                                           options:NSTrackingMouseMoved |
                                                                   NSTrackingMouseEnteredAndExited |
                                                                   NSTrackingActiveAlways |
                                                                   NSTrackingInVisibleRect
                                                             owner:self
                                                          userInfo:nil]] ;
#pragma clang diagnostic pop
    }
    return self;
}

- (BOOL)isFlipped { return YES; }

- (BOOL)acceptsFirstMouse:(__unused NSEvent *)theEvent {
    if (self.window == nil) return NO;
    return !self.window.ignoresMouseEvents;
}

- (void)mouseMoved:(NSEvent *)theEvent {
    BOOL canvasMouseEvents = _canvasMouseDown || _canvasMouseUp || _canvasMouseEnterExit || _canvasMouseMove ;

    if ((_mouseCallbackRef != LUA_NOREF) && (_mouseTracking || canvasMouseEvents)) {
        NSPoint event_location = theEvent.locationInWindow;
        NSPoint local_point = [self convertPoint:event_location fromView:nil];

        __block NSUInteger targetIndex = NSNotFound ;
        __block NSPoint actualpoint = local_point ;

        [_elementBounds enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary *box, NSUInteger idx, BOOL *stop) {
            NSUInteger elementIdx  = [box[@"index"] unsignedIntegerValue] ;
            if ([[self getElementValueFor:@"trackMouseEnterExit" atIndex:elementIdx] boolValue] || [[self getElementValueFor:@"trackMouseMove" atIndex:elementIdx] boolValue]) {
                NSAffineTransform *pointTransform = [self->_canvasTransform copy] ;
                [pointTransform appendTransform:[self getElementValueFor:@"transformation" atIndex:elementIdx]] ;
                [pointTransform invert] ;
                actualpoint = [pointTransform transformPoint:local_point] ;
                if ((box[@"frame"] && NSPointInRect(actualpoint, [box[@"frame"] rectValue])) || (box[@"path"] && [box[@"path"] containsPoint:actualpoint]))
                {
                    targetIndex = idx ;
                    *stop = YES ;
                }
            }
        }] ;

        NSUInteger realTargetIndex = (targetIndex != NSNotFound) ?
                    [_elementBounds[targetIndex][@"index"] unsignedIntegerValue]  : NSNotFound ;
        NSUInteger realPrevIndex = (_previousTrackedIndex != NSNotFound) ?
                    [_elementBounds[_previousTrackedIndex][@"index"] unsignedIntegerValue]  : NSNotFound ;

        if (_previousTrackedIndex == targetIndex) {
            if ((targetIndex != NSNotFound) && [[self getElementValueFor:@"trackMouseMove" atIndex:realPrevIndex] boolValue]) {
                id targetID = [self getElementValueFor:@"id" atIndex:realPrevIndex onlyIfSet:YES] ;
                if (!targetID) targetID = @(realPrevIndex + 1) ;
                [self doMouseCallback:@"mouseMove" for:targetID at:local_point] ;
            }
        } else {
            if ((_previousTrackedIndex != NSNotFound) && [[self getElementValueFor:@"trackMouseEnterExit" atIndex:realPrevIndex] boolValue]) {
                id targetID = [self getElementValueFor:@"id" atIndex:realPrevIndex onlyIfSet:YES] ;
                if (!targetID) targetID = @(realPrevIndex + 1) ;
                [self doMouseCallback:@"mouseExit" for:targetID at:local_point] ;
            }
            if (targetIndex != NSNotFound) {
                id targetID = [self getElementValueFor:@"id" atIndex:realTargetIndex onlyIfSet:YES] ;
                if (!targetID) targetID = @(realTargetIndex + 1) ;
                if ([[self getElementValueFor:@"trackMouseEnterExit" atIndex:realTargetIndex] boolValue]) {
                    [self doMouseCallback:@"mouseEnter" for:targetID at:local_point] ;
                } else if ([[self getElementValueFor:@"trackMouseMove" atIndex:realTargetIndex] boolValue]) {
                    [self doMouseCallback:@"mouseMove" for:targetID at:local_point] ;
                }
                if (_canvasMouseEnterExit && (_previousTrackedIndex == NSNotFound)) {
                    [self doMouseCallback:@"mouseExit" for:@"_canvas_" at:local_point] ;
                }
            }
        }

        if ((_canvasMouseEnterExit || _canvasMouseMove) && (targetIndex == NSNotFound)) {
            if (_previousTrackedIndex == NSNotFound && _canvasMouseMove) {
                [self doMouseCallback:@"mouseMove" for:@"_canvas_" at:local_point] ;
            } else if (_previousTrackedIndex != NSNotFound && _canvasMouseEnterExit) {
                [self doMouseCallback:@"mouseEnter" for:@"_canvas_" at:local_point] ;
            }
        }
        _previousTrackedIndex = targetIndex ;
    }
}

- (void)mouseEntered:(NSEvent *)theEvent {
    if ((_mouseCallbackRef != LUA_NOREF) && _canvasMouseEnterExit) {
        NSPoint event_location = theEvent.locationInWindow;
        NSPoint local_point = [self convertPoint:event_location fromView:nil];

        [self doMouseCallback:@"mouseEnter" for:@"_canvas_" at:local_point] ;
    }
}

- (void)mouseExited:(NSEvent *)theEvent {
    if (_mouseCallbackRef != LUA_NOREF) {
        NSPoint event_location = theEvent.locationInWindow;
        NSPoint local_point = [self convertPoint:event_location fromView:nil];
        if (_previousTrackedIndex != NSNotFound) {
            NSUInteger realPrevIndex = (_previousTrackedIndex != NSNotFound) ?
                    [_elementBounds[_previousTrackedIndex][@"index"] unsignedIntegerValue]  : NSNotFound ;
            if ([[self getElementValueFor:@"trackMouseEnterExit" atIndex:realPrevIndex] boolValue]) {
                id targetID = [self getElementValueFor:@"id" atIndex:realPrevIndex onlyIfSet:YES] ;
                if (!targetID) targetID = @(realPrevIndex + 1) ;
                [self doMouseCallback:@"mouseExit" for:targetID at:local_point] ;
            }
        }
        if (_canvasMouseEnterExit) {
            [self doMouseCallback:@"mouseExit" for:@"_canvas_" at:local_point] ;
        }
    }
    _previousTrackedIndex = NSNotFound ;
}

- (void)doMouseCallback:(NSString *)message for:(id)elementIdentifier at:(NSPoint)location {
    if (elementIdentifier) {
        LuaSkin *skin = [LuaSkin shared];
        [skin pushLuaRef:refTable ref:_mouseCallbackRef];
        [skin pushLuaRef:refTable ref:((ASMCanvasWindow *)self.window).selfRef] ;
        [skin pushNSObject:message] ;
        [skin pushNSObject:elementIdentifier] ;
        lua_pushnumber(skin.L, location.x) ;
        lua_pushnumber(skin.L, location.y) ;
        if (![skin protectedCallAndTraceback:5 nresults:0]) {
            [skin logError:[NSString stringWithFormat:@"%s:clickCallback for %@ callback error: %s",
                                                      USERDATA_TAG,
                                                      message,
                                                      lua_tostring(skin.L, -1)]];
            lua_pop(skin.L, 1) ;
        }
    }
}

- (void)mouseDown:(NSEvent *)theEvent {
    [NSApp preventWindowOrdering];
    if (_mouseCallbackRef != LUA_NOREF) {
        BOOL isDown = (theEvent.type == NSLeftMouseDown)  ||
                      (theEvent.type == NSRightMouseDown) ||
                      (theEvent.type == NSOtherMouseDown) ;

        NSPoint event_location = theEvent.locationInWindow;
        NSPoint local_point = [self convertPoint:event_location fromView:nil];
//         [LuaSkin logWarn:[NSString stringWithFormat:@"mouse click at (%f, %f)", local_point.x, local_point.y]] ;

        __block id targetID = nil ;
        __block NSPoint actualpoint = local_point ;

        [_elementBounds enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary *box, __unused NSUInteger idx, BOOL *stop) {
            NSUInteger elementIdx  = [box[@"index"] unsignedIntegerValue] ;
            if ([[self getElementValueFor:(isDown ? @"trackMouseDown" : @"trackMouseUp") atIndex:elementIdx] boolValue]) {
                NSAffineTransform *pointTransform = [self->_canvasTransform copy] ;
                [pointTransform appendTransform:[self getElementValueFor:@"transformation" atIndex:elementIdx]] ;
                [pointTransform invert] ;
                actualpoint = [pointTransform transformPoint:local_point] ;
                if ((box[@"frame"] && NSPointInRect(actualpoint, [box[@"frame"] rectValue])) || (box[@"path"] && [box[@"path"] containsPoint:actualpoint]))
                {
                    targetID = [self getElementValueFor:@"id" atIndex:elementIdx onlyIfSet:YES] ;
                    if (!targetID) targetID = @(elementIdx + 1) ;
                    *stop = YES ;
                }
            }
        }] ;

        if (!targetID) {
            if (isDown && _canvasMouseDown) {
                [self doMouseCallback:@"mouseDown" for:@"_canvas_" at:actualpoint] ;
            } else if (!isDown && _canvasMouseUp) {
                [self doMouseCallback:@"mouseUp" for:@"_canvas_" at:actualpoint] ;
            }
        }
    }
}

- (void)rightMouseDown:(NSEvent *)theEvent { [self mouseDown:theEvent] ; }
- (void)otherMouseDown:(NSEvent *)theEvent { [self mouseDown:theEvent] ; }
- (void)mouseUp:(NSEvent *)theEvent        { [self mouseDown:theEvent] ; }
- (void)rightMouseUp:(NSEvent *)theEvent   { [self mouseDown:theEvent] ; }
- (void)otherMouseUp:(NSEvent *)theEvent   { [self mouseDown:theEvent] ; }

- (NSBezierPath *)pathForElementAtIndex:(NSUInteger)idx {
    NSBezierPath *elementPath = nil ;
    NSString     *elementType = [self getElementValueFor:@"type" atIndex:idx] ;

    NSDictionary *frame = [self getElementValueFor:@"frame" atIndex:idx resolvePercentages:YES] ;
    NSRect  frameRect = NSMakeRect([frame[@"x"] doubleValue], [frame[@"y"] doubleValue],
                                   [frame[@"w"] doubleValue], [frame[@"h"] doubleValue]) ;

#pragma mark - ARC
    if ([elementType isEqualToString:@"arc"]) {
        NSDictionary *center = [self getElementValueFor:@"center" atIndex:idx resolvePercentages:YES] ;
        CGFloat cx = [center[@"x"] doubleValue] ;
        CGFloat cy = [center[@"y"] doubleValue] ;
        CGFloat r  = [[self getElementValueFor:@"radius" atIndex:idx resolvePercentages:YES] doubleValue] ;
        NSPoint myCenterPoint = NSMakePoint(cx, cy) ;
        elementPath = [NSBezierPath bezierPath];
        CGFloat startAngle = [[self getElementValueFor:@"startAngle" atIndex:idx] doubleValue] - 90 ;
        CGFloat endAngle   = [[self getElementValueFor:@"endAngle" atIndex:idx] doubleValue] - 90 ;
        BOOL    arcDir     = [[self getElementValueFor:@"arcClockwise" atIndex:idx] boolValue] ;
        BOOL    arcLegs    = [[self getElementValueFor:@"arcRadii" atIndex:idx] boolValue] ;
        if (arcLegs) [elementPath moveToPoint:myCenterPoint] ;
        [elementPath appendBezierPathWithArcWithCenter:myCenterPoint
                                                radius:r
                                            startAngle:startAngle
                                              endAngle:endAngle
                                             clockwise:!arcDir // because our canvas is flipped, we have to reverse this
        ] ;
        if (arcLegs) [elementPath lineToPoint:myCenterPoint] ;
    } else
#pragma mark - CIRCLE
    if ([elementType isEqualToString:@"circle"]) {
        NSDictionary *center = [self getElementValueFor:@"center" atIndex:idx resolvePercentages:YES] ;
        CGFloat cx = [center[@"x"] doubleValue] ;
        CGFloat cy = [center[@"y"] doubleValue] ;
        CGFloat r  = [[self getElementValueFor:@"radius" atIndex:idx resolvePercentages:YES] doubleValue] ;
        elementPath = [NSBezierPath bezierPath];
        [elementPath appendBezierPathWithOvalInRect:NSMakeRect(cx - r, cy - r, r * 2, r * 2)] ;
    } else
#pragma mark - ELLIPTICALARC
    if ([elementType isEqualToString:@"ellipticalArc"]) {
        CGFloat cx     = frameRect.origin.x + frameRect.size.width / 2 ;
        CGFloat cy     = frameRect.origin.y + frameRect.size.height / 2 ;
        CGFloat r      = frameRect.size.width / 2 ;

        NSAffineTransform *moveTransform = [NSAffineTransform transform] ;
        [moveTransform translateXBy:cx yBy:cy] ;
        NSAffineTransform *scaleTransform = [NSAffineTransform transform] ;
        [scaleTransform scaleXBy:1.0 yBy:(frameRect.size.height / frameRect.size.width)] ;
        NSAffineTransform *finalTransform = [[NSAffineTransform alloc] initWithTransform:scaleTransform] ;
        [finalTransform appendTransform:moveTransform] ;
        elementPath = [NSBezierPath bezierPath];
        CGFloat startAngle = [[self getElementValueFor:@"startAngle" atIndex:idx] doubleValue] - 90 ;
        CGFloat endAngle   = [[self getElementValueFor:@"endAngle" atIndex:idx] doubleValue] - 90 ;
        BOOL    arcDir     = [[self getElementValueFor:@"arcClockwise" atIndex:idx] boolValue] ;
        BOOL    arcLegs    = [[self getElementValueFor:@"arcRadii" atIndex:idx] boolValue] ;
        if (arcLegs) [elementPath moveToPoint:NSZeroPoint] ;
        [elementPath appendBezierPathWithArcWithCenter:NSZeroPoint
                                                radius:r
                                            startAngle:startAngle
                                              endAngle:endAngle
                                             clockwise:!arcDir // because our canvas is flipped, we have to reverse this
        ] ;
        if (arcLegs) [elementPath lineToPoint:NSZeroPoint] ;
        elementPath = [finalTransform transformBezierPath:elementPath] ;
    } else
#pragma mark - OVAL
    if ([elementType isEqualToString:@"oval"]) {
        elementPath = [NSBezierPath bezierPath];
        [elementPath appendBezierPathWithOvalInRect:frameRect] ;
    } else
#pragma mark - RECTANGLE
    if ([elementType isEqualToString:@"rectangle"]) {
        elementPath = [NSBezierPath bezierPath];
        NSDictionary *roundedRect = [self getElementValueFor:@"roundedRectRadii" atIndex:idx] ;
        [elementPath appendBezierPathWithRoundedRect:frameRect
                                          xRadius:[roundedRect[@"xRadius"] doubleValue]
                                          yRadius:[roundedRect[@"yRadius"] doubleValue]] ;
    } else
#pragma mark - POINTS
    if ([elementType isEqualToString:@"points"]) {
        elementPath = [NSBezierPath bezierPath];
        NSArray *coordinates = [self getElementValueFor:@"coordinates" atIndex:idx resolvePercentages:YES] ;

        [coordinates enumerateObjectsUsingBlock:^(NSDictionary *aPoint, __unused NSUInteger idx2, __unused BOOL *stop2) {
            NSNumber *xNumber   = aPoint[@"x"] ;
            NSNumber *yNumber   = aPoint[@"y"] ;
            [elementPath appendBezierPathWithRect:NSMakeRect([xNumber doubleValue], [yNumber doubleValue], 1.0, 1.0)] ;
        }] ;
    } else
#pragma mark - SEGMENTS
    if ([elementType isEqualToString:@"segments"]) {
        elementPath = [NSBezierPath bezierPath];
        NSArray *coordinates = [self getElementValueFor:@"coordinates" atIndex:idx resolvePercentages:YES] ;

        [coordinates enumerateObjectsUsingBlock:^(NSDictionary *aPoint, NSUInteger idx2, __unused BOOL *stop2) {
            NSNumber *xNumber   = aPoint[@"x"] ;
            NSNumber *yNumber   = aPoint[@"y"] ;
            NSNumber *c1xNumber = aPoint[@"c1x"] ;
            NSNumber *c1yNumber = aPoint[@"c1y"] ;
            NSNumber *c2xNumber = aPoint[@"c2x"] ;
            NSNumber *c2yNumber = aPoint[@"c2y"] ;
            BOOL goodForCurve = (c1xNumber) && (c1yNumber) && (c2xNumber) && (c2yNumber) ;
            if (idx2 == 0) {
                [elementPath moveToPoint:NSMakePoint([xNumber doubleValue], [yNumber doubleValue])] ;
            } else if (!goodForCurve) {
                [elementPath lineToPoint:NSMakePoint([xNumber doubleValue], [yNumber doubleValue])] ;
            } else {
                [elementPath curveToPoint:NSMakePoint([xNumber doubleValue], [yNumber doubleValue])
                            controlPoint1:NSMakePoint([c1xNumber doubleValue], [c1yNumber doubleValue])
                            controlPoint2:NSMakePoint([c2xNumber doubleValue], [c2yNumber doubleValue])] ;
            }
        }] ;
        if ([[self getElementValueFor:@"closed" atIndex:idx] boolValue]) {
            [elementPath closePath] ;
        }
    }

    return elementPath ;
}

- (void)drawRect:(__unused NSRect)rect {
    NSDisableScreenUpdates() ;

    NSGraphicsContext* gc = [NSGraphicsContext currentContext];
    [gc saveGraphicsState];

    [_canvasTransform concat] ;

    [NSBezierPath setDefaultLineWidth:[[self getDefaultValueFor:@"strokeWidth" onlyIfSet:NO] doubleValue]] ;
    [NSBezierPath setDefaultMiterLimit:[[self getDefaultValueFor:@"miterLimit" onlyIfSet:NO] doubleValue]] ;
    [NSBezierPath setDefaultFlatness:[[self getDefaultValueFor:@"flatness" onlyIfSet:NO] doubleValue]] ;

    NSString *LJS = [self getDefaultValueFor:@"strokeJoinStyle" onlyIfSet:NO] ;
    [NSBezierPath setDefaultLineJoinStyle:[STROKE_JOIN_STYLES[LJS] unsignedIntValue]] ;

    NSString *LCS = [self getDefaultValueFor:@"strokeCapStyle" onlyIfSet:NO] ;
    [NSBezierPath setDefaultLineJoinStyle:[STROKE_CAP_STYLES[LCS] unsignedIntValue]] ;

    NSString *WR = [self getDefaultValueFor:@"windingRule" onlyIfSet:NO] ;
    [NSBezierPath setDefaultWindingRule:[WINDING_RULES[WR] unsignedIntValue]] ;

    NSString *CS = [self getDefaultValueFor:@"compositeRule" onlyIfSet:NO] ;
    gc.compositingOperation = [COMPOSITING_TYPES[CS] unsignedIntValue] ;

    [[self getDefaultValueFor:@"antialias" onlyIfSet:NO] boolValue] ;
    [[self getDefaultValueFor:@"fillColor" onlyIfSet:NO] setFill] ;
    [[self getDefaultValueFor:@"strokeColor" onlyIfSet:NO] setStroke] ;

    _elementBounds = [[NSMutableArray alloc] init] ;

    // renderPath needs to persist through iterations, so define it here
    __block NSBezierPath *renderPath ;
    __block BOOL         clippingModified = NO ;
    __block BOOL         needMouseTracking = NO ;

    [_elementList enumerateObjectsUsingBlock:^(NSDictionary *element, NSUInteger idx, __unused BOOL *stop) {
        NSBezierPath *elementPath ;
        NSString     *elementType = element[@"type"] ;
        NSString     *action      = [self getElementValueFor:@"action" atIndex:idx] ;

        if (![action isEqualTo:@"skip"]) {
            if (!needMouseTracking) {
                needMouseTracking = [[self getElementValueFor:@"trackMouseEnterExit" atIndex:idx] boolValue] || [[self getElementValueFor:@"trackMouseMove" atIndex:idx] boolValue] ;
            }

            BOOL wasClippingChanged = NO ; // necessary to keep graphicsState stack properly ordered

            [gc saveGraphicsState] ;

            BOOL hasShadow = [[self getElementValueFor:@"withShadow" atIndex:idx] boolValue] ;
            if (hasShadow) [(NSShadow *)[self getElementValueFor:@"shadow" atIndex:idx] set] ;

            NSNumber *shouldAntialias = [self getElementValueFor:@"antialias" atIndex:idx onlyIfSet:YES] ;
            if (shouldAntialias) gc.shouldAntialias = [shouldAntialias boolValue] ;

            NSString *compositingString = [self getElementValueFor:@"compositeRule" atIndex:idx onlyIfSet:YES] ;
            if (compositingString) gc.compositingOperation = [COMPOSITING_TYPES[compositingString] unsignedIntValue] ;

            NSColor *fillColor = [self getElementValueFor:@"fillColor" atIndex:idx onlyIfSet:YES] ;
            if (fillColor) [fillColor setFill] ;

            NSColor *strokeColor = [self getElementValueFor:@"strokeColor" atIndex:idx onlyIfSet:YES] ;
            if (strokeColor) [strokeColor setStroke] ;

            NSAffineTransform *elementTransform = [self getElementValueFor:@"transformation" atIndex:idx] ;
            if (elementTransform) [elementTransform concat] ;

            elementPath = [self pathForElementAtIndex:idx] ;

            // First, if it's not a path, make sure it's not an element which doesn't have a path...

            if (!elementPath) {
                NSDictionary *frame = [self getElementValueFor:@"frame" atIndex:idx resolvePercentages:YES] ;
                NSRect  frameRect = NSMakeRect([frame[@"x"] doubleValue], [frame[@"y"] doubleValue],
                                               [frame[@"w"] doubleValue], [frame[@"h"] doubleValue]) ;

    #pragma mark - IMAGE
                if ([elementType isEqualToString:@"image"]) {
                // to support drawing image attributes, we'd need to use subviews and some way to link view to element dictionary, since subviews is an array... gonna need thought if desired... only really useful missing option is animates; others can be created by hand or by adjusting transform or frame
                    NSImage      *theImage = [self getElementValueFor:@"image" atIndex:idx onlyIfSet:YES] ;
                    if (theImage) [theImage drawInRect:frameRect] ;
                    [self->_elementBounds addObject:@{
                        @"index" : @(idx),
                        @"frame" : [NSValue valueWithRect:frameRect]
                    }] ;
                    elementPath = nil ; // shouldn't be necessary, but lets be explicit
                } else
    #pragma mark - TEXT
                if ([elementType isEqualToString:@"text"]) {
                    id textEntry = [self getElementValueFor:@"text" atIndex:idx onlyIfSet:YES] ;
                    if (!textEntry) {
                        textEntry = @"" ;
                    } else if([textEntry isKindOfClass:[NSNumber class]]) {
                        textEntry = [(NSNumber *)textEntry stringValue] ;
                    }

                    if ([textEntry isKindOfClass:[NSString class]]) {
                        NSString *myFont = [self getElementValueFor:@"textFont" atIndex:idx onlyIfSet:NO] ;
                        NSNumber *mySize = [self getElementValueFor:@"textSize" atIndex:idx onlyIfSet:NO] ;
                        NSDictionary *attributes = @{
                            NSForegroundColorAttributeName : [self getElementValueFor:@"textColor" atIndex:idx onlyIfSet:NO],
                            NSFontAttributeName            : [NSFont fontWithName:myFont size:[mySize doubleValue]],
                        } ;
                        [(NSString *)textEntry drawInRect:frameRect withAttributes:attributes] ;
                    } else {
                        [(NSAttributedString *)textEntry drawInRect:frameRect] ;
                    }
                    [self->_elementBounds addObject:@{
                        @"index" : @(idx),
                        @"frame" : [NSValue valueWithRect:frameRect]
                    }] ;
                    elementPath = nil ; // shouldn't be necessary, but lets be explicit
                } else
    #pragma mark - CANVAS
                if ([elementType isEqualToString:@"canvas"]) {
                    // NOTE: I think we'll have to delete all sub-views each time through, though maybe not since
                    // we'll have the view itself in the window object... but see notes for removeFromSuperView
                    // NOTE: What about __gc if a sub-canvas is deleted but not removed first?
                    ASMCanvasWindow *canvas = [self getElementValueFor:@"canvas" atIndex:idx onlyIfSet:NO] ;
                    if ([canvas isKindOfClass:[ASMCanvasWindow class]]) {
                        ASMCanvasView   *canvasView = (ASMCanvasView *)canvas.contentView ;
                        if (![canvasView isDescendantOf:self]) {
                            [self addSubview:canvasView] ;
                        }
                        canvasView.needsDisplay = YES ;
                        [canvasView setFrame:frameRect] ;
                        [self->_elementBounds addObject:@{
                            @"index" : @(idx),
                            @"frame" : [NSValue valueWithRect:frameRect]
                        }] ;
                    }
                } else
    #pragma mark - RESETCLIP
                if ([elementType isEqualToString:@"resetClip"]) {
                    [gc restoreGraphicsState] ; // from beginning of enumeration
                    wasClippingChanged = YES ;
                    if (clippingModified) {
                        [gc restoreGraphicsState] ; // from clip action
                        clippingModified = NO ;
                    } else {
                        [LuaSkin logWarn:[NSString stringWithFormat:@"%s:drawRect - un-nested resetClip at index %lu", USERDATA_TAG, idx + 1]] ;
                    }
                    elementPath = nil ; // shouldn't be necessary, but lets be explicit
                } else {
                    [LuaSkin logWarn:[NSString stringWithFormat:@"%s:drawRect - unrecognized type %@ at index %lu", USERDATA_TAG, elementType, idx + 1]] ;
                }
            }
            // Now, if it's still not a path, we don't render it.  But if it is...

    #pragma mark - Render Logic
            if (elementPath) {
                NSNumber *miterLimit = [self getElementValueFor:@"miterLimit" atIndex:idx onlyIfSet:YES] ;
                if (miterLimit) elementPath.miterLimit = [miterLimit doubleValue] ;

                NSNumber *flatness = [self getElementValueFor:@"flatness" atIndex:idx onlyIfSet:YES] ;
                if (flatness) elementPath.flatness = [flatness doubleValue] ;

                if ([[self getElementValueFor:@"flattenPath" atIndex:idx] boolValue]) {
                    elementPath = elementPath.bezierPathByFlatteningPath ;
                }
                if ([[self getElementValueFor:@"reversePath" atIndex:idx] boolValue]) {
                    elementPath = elementPath.bezierPathByReversingPath ;
                }

                NSString *windingRule = [self getElementValueFor:@"windingRule" atIndex:idx onlyIfSet:YES] ;
                if (windingRule) elementPath.windingRule = [WINDING_RULES[windingRule] unsignedIntValue] ;

                if (renderPath) {
                    [renderPath appendBezierPath:elementPath] ;
                } else {
                    renderPath = elementPath ;
                }

                if ([action isEqualToString:@"clip"]) {
                    [gc restoreGraphicsState] ; // from beginning of enumeration
                    wasClippingChanged = YES ;
                    if (!clippingModified) {
                        [gc saveGraphicsState] ;
                        clippingModified = YES ;
                    }
                    [renderPath addClip] ;
                    renderPath = nil ;

                } else if ([action isEqualToString:@"fill"] || [action isEqualToString:@"stroke"] || [action isEqualToString:@"strokeAndFill"]) {
                    if (![elementType isEqualToString:@"points"] && ([action isEqualToString:@"fill"] || [action isEqualToString:@"strokeAndFill"])) {
                        NSString     *fillGradient   = [self getElementValueFor:@"fillGradient" atIndex:idx] ;
                        if (![fillGradient isEqualToString:@"none"]) {
                            NSDictionary *gradientColors = [self getElementValueFor:@"fillGradientColors" atIndex:idx] ;
                            NSColor      *startColor     = gradientColors[@"startColor"] ;
                            NSColor      *endColor       = gradientColors[@"endColor"] ;
                            if ([fillGradient isEqualToString:@"linear"]) {
                                NSGradient* gradient = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
                                [gradient drawInBezierPath:renderPath angle:[[self getElementValueFor:@"fillGradientAngle" atIndex:idx] doubleValue]] ;
                            } else if ([fillGradient isEqualToString:@"radial"]) {
                                NSGradient* gradient = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
                                NSDictionary *centerPoint = [self getElementValueFor:@"fillGradientCenter" atIndex:idx] ;
                                [gradient drawInBezierPath:renderPath
                                    relativeCenterPosition:NSMakePoint([centerPoint[@"x"] doubleValue], [centerPoint[@"y"] doubleValue])] ;
                            }
                        } else {
                            [renderPath fill] ;
                        }
                    }

                    if ([action isEqualToString:@"stroke"] || [action isEqualToString:@"strokeAndFill"]) {
                        NSNumber *strokeWidth = [self getElementValueFor:@"strokeWidth" atIndex:idx onlyIfSet:YES] ;
                        if (strokeWidth) renderPath.lineWidth  = [strokeWidth doubleValue] ;

                        NSString *lineJoinStyle = [self getElementValueFor:@"strokeJoinStyle" atIndex:idx onlyIfSet:YES] ;
                        if (lineJoinStyle) renderPath.lineJoinStyle = [STROKE_JOIN_STYLES[lineJoinStyle] unsignedIntValue] ;

                        NSString *lineCapStyle = [self getElementValueFor:@"strokeCapStyle" atIndex:idx onlyIfSet:YES] ;
                        if (lineCapStyle) renderPath.lineCapStyle = [STROKE_CAP_STYLES[lineCapStyle] unsignedIntValue] ;

                        NSArray *strokeDashes = [self getElementValueFor:@"strokeDashPattern" atIndex:idx] ;
                        if ([strokeDashes count] > 0) {
                            NSUInteger count = [strokeDashes count] ;
                            CGFloat    phase = [[self getElementValueFor:@"strokeDashPhase" atIndex:idx] doubleValue] ;
                            CGFloat *pattern ;
                            pattern = (CGFloat *)malloc(sizeof(CGFloat) * count) ;
                            if (pattern) {
                                for (NSUInteger i = 0 ; i < count ; i++) {
                                    pattern[i] = [strokeDashes[i] doubleValue] ;
                                }
                                [renderPath setLineDash:pattern count:(NSInteger)count phase:phase];
                                free(pattern) ;
                            }
                        }

                        [renderPath stroke] ;
                    }
                    [self->_elementBounds addObject:@{
                        @"index" : @(idx),
                        @"path"  : renderPath,
                    }] ;
                    renderPath = nil ;
                } else if (![action isEqualToString:@"build"]) {
                    [LuaSkin logWarn:[NSString stringWithFormat:@"%s:drawRect - unrecognized action %@ at index %lu", USERDATA_TAG, action, idx + 1]] ;
                }
            }
            // to keep nesting correct, this was already done if we adjusted clipping this round
            if (!wasClippingChanged) [gc restoreGraphicsState] ;
//         } else if ([action isEqualToString:@"skip"]) {
//             renderPath = nil ;
        }
    }] ;

    if (clippingModified) [gc restoreGraphicsState] ; // balance our saves

    _mouseTracking = needMouseTracking ;
    [gc restoreGraphicsState];
    NSEnableScreenUpdates() ;
}

// To facilitate the way frames and points are specified, we get our tables from lua with the LS_NSRawTables option... this forces rect-tables and point-tables to be just that - tables, but also prevents color tables, styledtext tables, and transform tables from being converted... so we add fixes for them here...
// Plus we allow some "laziness" on the part of the programmer to leave out __luaSkinType when crafting the tables by hand, either to make things cleaner/easier or for historical reasons...

- (id)massageKeyValue:(id)oldValue forKey:(NSString *)keyName {
    LuaSkin *skin = [LuaSkin shared] ;
    lua_State *L = [skin L] ;

    id newValue = oldValue ; // assume we're not changing anything
//     [LuaSkin logWarn:[NSString stringWithFormat:@"keyname %@ (%@) oldValue is %@", keyName, NSStringFromClass([oldValue class]), [oldValue debugDescription]]] ;

    // fix "...Color" tables
    if ([keyName hasSuffix:@"Color"] && ([oldValue isKindOfClass:[NSDictionary class]] || [oldValue isKindOfClass:[NSArray class]])) {
        [skin pushNSObject:oldValue] ;
        lua_pushstring(L, "NSColor") ;
        lua_setfield(L, -2, "__luaSkinType") ;
        newValue = [skin toNSObjectAtIndex:-1] ;
        lua_pop(L, 1) ;

    // fix NSAffineTransform table
    } else if ([keyName isEqualToString:@"transformation"] && ([oldValue isKindOfClass:[NSDictionary class]] || [oldValue isKindOfClass:[NSArray class]])) {
        [skin pushNSObject:oldValue] ;
        lua_pushstring(L, "NSAffineTransform") ;
        lua_setfield(L, -2, "__luaSkinType") ;
        newValue = [skin toNSObjectAtIndex:-1] ;
        lua_pop(L, 1) ;

    // fix NSShadow table
    } else if ([keyName isEqualToString:@"shadow"] && ([oldValue isKindOfClass:[NSDictionary class]] || [oldValue isKindOfClass:[NSArray class]])) {
        [skin pushNSObject:oldValue] ;
        lua_pushstring(L, "NSShadow") ;
        lua_setfield(L, -2, "__luaSkinType") ;
        newValue = [skin toNSObjectAtIndex:-1] ;
        lua_pop(L, 1) ;

    // fix hs.styledText as Table
    } else if ([keyName isEqualToString:@"text"] && ([oldValue isKindOfClass:[NSDictionary class]] || [oldValue isKindOfClass:[NSArray class]])) {
        [skin pushNSObject:oldValue] ;
        lua_pushstring(L, "NSAttributedString") ;
        lua_setfield(L, -2, "__luaSkinType") ;
        newValue = [skin toNSObjectAtIndex:-1] ;
        lua_pop(L, 1) ;

    // recurse into fields which have subfields to check those as well -- this should be done last in case the dictionary can be coerced into an object, like the color tables handled above
    } else if ([oldValue isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *blockValue = [[NSMutableDictionary alloc] init] ;
        [oldValue enumerateKeysAndObjectsUsingBlock:^(id blockKeyName, id valueForKey, __unused BOOL *stop) {
            [blockValue setObject:[self massageKeyValue:valueForKey forKey:blockKeyName] forKey:blockKeyName] ;
        }] ;
        newValue = blockValue ;
    }
//     [LuaSkin logWarn:[NSString stringWithFormat:@"newValue is %@", [newValue debugDescription]]] ;

    return newValue ;
}

- (id)getDefaultValueFor:(NSString *)keyName onlyIfSet:(BOOL)onlyIfSet {
    NSDictionary *attributeDefinition = languageDictionary[keyName] ;
    id result ;
    if (!attributeDefinition[@"default"]) {
        return nil ;
    } else if (_canvasDefaults[keyName]) {
        result = _canvasDefaults[keyName] ;
    } else if (!onlyIfSet) {
        result = attributeDefinition[@"default"] ;
    } else {
        result = nil ;
    }

    if ([[result class] conformsToProtocol:@protocol(NSMutableCopying)]) {
        result = [result mutableCopy] ;
    } else if ([[result class] conformsToProtocol:@protocol(NSCopying)]) {
        result = [result copy] ;
    }
    return result ;
}

- (attributeValidity)setDefaultFor:(NSString *)keyName to:(id)keyValue {
    attributeValidity validityStatus       = attributeInvalid ;
    if ([languageDictionary[keyName][@"nullable"] boolValue]) {
        keyValue = [self massageKeyValue:keyValue forKey:keyName] ;
        validityStatus = isValueValidForAttribute(keyName, keyValue) ;
        switch (validityStatus) {
            case attributeValid:
                _canvasDefaults[keyName] = keyValue ;
                break ;
            case attributeNulling:
                [_canvasDefaults removeObjectForKey:keyName] ;
                break ;
            case attributeInvalid:
                break ;
            default:
                [LuaSkin logWarn:@"unexpected validity status returned; notify developers"] ;
                break ;
        }
    }
    self.needsDisplay = true ;
    return validityStatus ;
}

- (id)getElementValueFor:(NSString *)keyName atIndex:(NSUInteger)index {
    return [self getElementValueFor:keyName atIndex:index resolvePercentages:NO onlyIfSet:NO] ;
}

- (id)getElementValueFor:(NSString *)keyName atIndex:(NSUInteger)index onlyIfSet:(BOOL)onlyIfSet {
    return [self getElementValueFor:keyName atIndex:index resolvePercentages:NO onlyIfSet:onlyIfSet] ;
}

- (id)getElementValueFor:(NSString *)keyName atIndex:(NSUInteger)index resolvePercentages:(BOOL)resolvePercentages {
    return [self getElementValueFor:keyName atIndex:index resolvePercentages:resolvePercentages onlyIfSet:NO] ;
}

- (id)getElementValueFor:(NSString *)keyName atIndex:(NSUInteger)index resolvePercentages:(BOOL)resolvePercentages onlyIfSet:(BOOL)onlyIfSet {
    if (index > [_elementList count]) return nil ;
    NSDictionary *elementAttributes = _elementList[index] ;
    id foundObject = elementAttributes[keyName] ? elementAttributes[keyName] : (onlyIfSet ? nil : [self getDefaultValueFor:keyName onlyIfSet:NO]) ;
    if ([[foundObject class] conformsToProtocol:@protocol(NSMutableCopying)]) {
        foundObject = [foundObject mutableCopy] ;
    } else if ([[foundObject class] conformsToProtocol:@protocol(NSCopying)]) {
        foundObject = [foundObject copy] ;
    }

    if (foundObject && resolvePercentages) {
        CGFloat padding = [[self getElementValueFor:@"padding" atIndex:index] doubleValue] ;
        CGFloat paddedWidth = self.frame.size.width - padding * 2 ;
        CGFloat paddedHeight = self.frame.size.height - padding * 2 ;

        if ([keyName isEqualToString:@"radius"]) {
            if ([foundObject isKindOfClass:[NSString class]]) {
                NSNumber *percentage = convertPercentageStringToNumber(foundObject) ;
                foundObject = [NSNumber numberWithDouble:([percentage doubleValue] * paddedWidth)] ;
            }
        } else if ([keyName isEqualToString:@"center"]) {
            if ([foundObject[@"x"] isKindOfClass:[NSString class]]) {
                NSNumber *percentage = convertPercentageStringToNumber(foundObject[@"x"]) ;
                foundObject[@"x"] = [NSNumber numberWithDouble:(padding + [percentage doubleValue] * paddedWidth)] ;
            }
            if ([foundObject[@"y"] isKindOfClass:[NSString class]]) {
                NSNumber *percentage = convertPercentageStringToNumber(foundObject[@"y"]) ;
                foundObject[@"y"] = [NSNumber numberWithDouble:(padding + [percentage doubleValue] * paddedHeight)] ;
            }
        } else if ([keyName isEqualToString:@"frame"]) {
            if ([foundObject[@"x"] isKindOfClass:[NSString class]]) {
                NSNumber *percentage = convertPercentageStringToNumber(foundObject[@"x"]) ;
                foundObject[@"x"] = [NSNumber numberWithDouble:(padding + [percentage doubleValue] * paddedWidth)] ;
            }
            if ([foundObject[@"y"] isKindOfClass:[NSString class]]) {
                NSNumber *percentage = convertPercentageStringToNumber(foundObject[@"y"]) ;
                foundObject[@"y"] = [NSNumber numberWithDouble:(padding + [percentage doubleValue] * paddedHeight)] ;
            }
            if ([foundObject[@"w"] isKindOfClass:[NSString class]]) {
                NSNumber *percentage = convertPercentageStringToNumber(foundObject[@"w"]) ;
                foundObject[@"w"] = [NSNumber numberWithDouble:([percentage doubleValue] * paddedWidth)] ;
            }
            if ([foundObject[@"h"] isKindOfClass:[NSString class]]) {
                NSNumber *percentage = convertPercentageStringToNumber(foundObject[@"h"]) ;
                foundObject[@"h"] = [NSNumber numberWithDouble:([percentage doubleValue] * paddedHeight)] ;
            }
        } else if ([keyName isEqualToString:@"coordinates"]) {
        // make sure we adjust a copy and not the actual items as defined; this is necessary because the copy above just does the top level element; this attribute is an array of objects unlike above attributes
            NSMutableArray *ourCopy = [[NSMutableArray alloc] init] ;
            [(NSMutableArray *)foundObject enumerateObjectsUsingBlock:^(NSMutableDictionary *subItem, NSUInteger idx, __unused BOOL *stop) {
                NSMutableDictionary *targetItem = [[NSMutableDictionary alloc] init] ;
                for (NSString *field in @[ @"x", @"y", @"c1x", @"c1y", @"c2x", @"c2y" ]) {
                    if (subItem[field] && [subItem[field] isKindOfClass:[NSString class]]) {
                        NSNumber *percentage = convertPercentageStringToNumber(subItem[field]) ;
                        CGFloat ourPadding = [field hasSuffix:@"x"] ? paddedWidth : paddedHeight ;
                        targetItem[field] = [NSNumber numberWithDouble:(padding + [percentage doubleValue] * ourPadding)] ;
                    } else {
                        targetItem[field] = subItem[field] ;
                    }
                }
                ourCopy[idx] = targetItem ;
            }] ;
            foundObject = ourCopy ;
        }
    }

    return foundObject ;
}

- (attributeValidity)setElementValueFor:(NSString *)keyName atIndex:(NSUInteger)index to:(id)keyValue {
    if (index > [_elementList count]) return attributeInvalid ;
    keyValue = [self massageKeyValue:keyValue forKey:keyName] ;
    __block attributeValidity validityStatus = isValueValidForAttribute(keyName, keyValue) ;

    switch (validityStatus) {
        case attributeValid: {
            if ([keyName isEqualToString:@"radius"]) {
                if ([keyValue isKindOfClass:[NSString class]]) {
                    NSNumber *percentage = convertPercentageStringToNumber(keyValue) ;
                    if (!percentage) {
                        [LuaSkin logError:[NSString stringWithFormat:@"%s:invalid percentage string specified for %@ for element %lu", USERDATA_TAG, keyName, index + 1]];
                        validityStatus = attributeInvalid ;
                        break ;
                    }
                }
            } else if ([keyName isEqualToString:@"center"]) {
                if ([keyValue[@"x"] isKindOfClass:[NSString class]]) {
                    NSNumber *percentage = convertPercentageStringToNumber(keyValue[@"x"]) ;
                    if (!percentage) {
                        [LuaSkin logError:[NSString stringWithFormat:@"%s:invalid percentage string specified for field x of %@ for element %lu", USERDATA_TAG, keyName, index + 1]];
                        validityStatus = attributeInvalid ;
                        break ;
                    }
                }
                if ([keyValue[@"y"] isKindOfClass:[NSString class]]) {
                    NSNumber *percentage = convertPercentageStringToNumber(keyValue[@"y"]) ;
                    if (!percentage) {
                        [LuaSkin logError:[NSString stringWithFormat:@"%s:invalid percentage string specified for field y of %@ for element %lu", USERDATA_TAG, keyName, index + 1]];
                        validityStatus = attributeInvalid ;
                        break ;
                    }
                }
            } else if ([keyName isEqualToString:@"frame"]) {
                if ([keyValue[@"x"] isKindOfClass:[NSString class]]) {
                    NSNumber *percentage = convertPercentageStringToNumber(keyValue[@"x"]) ;
                    if (!percentage) {
                        [LuaSkin logError:[NSString stringWithFormat:@"%s:invalid percentage string specified for field x of %@ for element %lu", USERDATA_TAG, keyName, index + 1]];
                        validityStatus = attributeInvalid ;
                        break ;
                    }
                }
                if ([keyValue[@"y"] isKindOfClass:[NSString class]]) {
                    NSNumber *percentage = convertPercentageStringToNumber(keyValue[@"y"]) ;
                    if (!percentage) {
                        [LuaSkin logError:[NSString stringWithFormat:@"%s:invalid percentage string specified for field y of %@ for element %lu", USERDATA_TAG, keyName, index + 1]];
                        validityStatus = attributeInvalid ;
                        break ;
                    }
                }
                if ([keyValue[@"w"] isKindOfClass:[NSString class]]) {
                    NSNumber *percentage = convertPercentageStringToNumber(keyValue[@"w"]) ;
                    if (!percentage) {
                        [LuaSkin logError:[NSString stringWithFormat:@"%s:invalid percentage string specified for field w of %@ for element %lu", USERDATA_TAG, keyName, index + 1]];
                        validityStatus = attributeInvalid ;
                        break ;
                    }
                }
                if ([keyValue[@"h"] isKindOfClass:[NSString class]]) {
                    NSNumber *percentage = convertPercentageStringToNumber(keyValue[@"h"]) ;
                    if (!percentage) {
                        [LuaSkin logError:[NSString stringWithFormat:@"%s:invalid percentage string specified for field h of %@ for element %lu", USERDATA_TAG, keyName, index + 1]];
                        validityStatus = attributeInvalid ;
                        break ;
                    }
                }
            } else if ([keyName isEqualToString:@"coordinates"]) {
                [(NSMutableArray *)keyValue enumerateObjectsUsingBlock:^(NSMutableDictionary *subItem, NSUInteger idx, BOOL *stop) {
                    NSMutableSet *seenFields = [[NSMutableSet alloc] init] ;
                    for (NSString *field in @[ @"x", @"y", @"c1x", @"c1y", @"c2x", @"c2y" ]) {
                        if (subItem[field]) {
                            [seenFields addObject:field] ;
                            if ([subItem[field] isKindOfClass:[NSString class]]) {
                                NSNumber *percentage = convertPercentageStringToNumber(subItem[field]) ;
                                if (!percentage) {
                                    [LuaSkin logError:[NSString stringWithFormat:@"%s:invalid percentage string specified for field %@ at index %lu of %@ for element %lu", USERDATA_TAG, field, idx + 1, keyName, index + 1]];
                                    validityStatus = attributeInvalid ;
                                    *stop = YES ;
                                    break ;
                                }
                            }
                        }
                    }
                    BOOL goodForPoint = [seenFields containsObject:@"x"] && [seenFields containsObject:@"y"] ;
                    BOOL goodForCurve = goodForPoint && [seenFields containsObject:@"c1x"] && [seenFields containsObject:@"c1y"] &&
                                                        [seenFields containsObject:@"c2x"] && [seenFields containsObject:@"c2y"] ;
                    BOOL partialCurve = ([seenFields containsObject:@"c1x"] || [seenFields containsObject:@"c1y"] ||
                                        [seenFields containsObject:@"c2x"] || [seenFields containsObject:@"c2y"]) && !goodForCurve ;

                    if (!goodForPoint) {
                        [LuaSkin logError:[NSString stringWithFormat:@"%s:index %lu of %@ for element %lu does not specify a valid point or curve with control points", USERDATA_TAG, idx + 1, keyName, index + 1]];
                        validityStatus = attributeInvalid ;
                    } else if (goodForPoint && partialCurve) {
                        [LuaSkin logWarn:[NSString stringWithFormat:@"%s:index %lu of %@ for element %lu does not contain complete curve control points; treating as a singular point", USERDATA_TAG, idx + 1, keyName, index + 1]];
                    }
                }] ;
                if (validityStatus == attributeInvalid) break ;
            }
            if ([keyName isEqualToString:@"canvas"]) {
                ASMCanvasWindow *newCanvas = (ASMCanvasWindow *)keyValue ;
                ASMCanvasWindow *oldCanvas = (ASMCanvasWindow *)_elementList[index][keyName] ;
                if (![newCanvas isEqualTo:oldCanvas]) {
                    ASMCanvasView *canvasView = newCanvas.contentView ;
                    if (![canvasView isDescendantOf:self]) {
                        [oldCanvas.contentView removeFromSuperview] ;
                        if (canvasView) [self addSubview:canvasView] ;
                    } else {
                        [LuaSkin logWarn:[NSString stringWithFormat:@"%s:cannot assign canvas to element %lu; the sub-canvas is already in use within the parent canvas.", USERDATA_TAG, index + 1]] ;
                    }
                }
            }
            _elementList[index][keyName] = keyValue ;
            if ([keyName isEqualToString:@"type"]) {
                // add defaults, if not already present, for type (recurse into this method as needed)
                NSSet *defaultsForType = [languageDictionary keysOfEntriesPassingTest:^BOOL(NSString *typeName, NSDictionary *typeDefinition, __unused BOOL *stop){
                    return ![typeName isEqualToString:@"type"] && typeDefinition[@"requiredFor"] && [typeDefinition[@"requiredFor"] containsObject:keyValue] ;
                }] ;
                for (NSString *additionalKey in defaultsForType) {
                    if (!_elementList[index][additionalKey]) {
                        [self setElementValueFor:additionalKey atIndex:index to:[self getDefaultValueFor:additionalKey onlyIfSet:NO]] ;
                    }
                }
            }
        }   break ;
        case attributeNulling:
            if ([keyName isEqualToString:@"canvas"]) {
                ASMCanvasWindow *oldCanvas = (ASMCanvasWindow *)_elementList[index][keyName] ;
                [oldCanvas.contentView removeFromSuperview] ;
            }
            [(NSMutableDictionary *)_elementList[index] removeObjectForKey:keyName] ;
            break ;
        case attributeInvalid:
            break ;
        default:
            [LuaSkin logWarn:@"unexpected validity status returned; notify developers"] ;
            break ;
    }
    self.needsDisplay = true ;
    return validityStatus ;
}

@end

#pragma mark - Module Functions

/// hs._asm.canvas.new(rect) -> canvasObject
/// Constructor
/// Create a new canvas object at the specified coordinates
///
/// Parameters:
///  * `rect` - A rect-table containing the co-ordinates and size for the canvas object
///
/// Returns:
///  * a new, empty, canvas object, or nil if the canvas cannot be created with the specified coordinates
///
/// Notes:
///  * The size of the canvas defines the visible area of the canvas -- any portion of a canvas element which extends past the canvas's edges will be clipped.
///  * a rect-table is a table with key-value pairs specifying the top-left coordinate on the screen for the canvas (keys `x`  and `y`) and the size (keys `h` and `w`) of the canvas. The table may be crafted by any method which includes these keys, including the use of an `hs.geometry` object.
static int canvas_new(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TTABLE, LS_TBREAK] ;

    ASMCanvasWindow *canvasWindow = [[ASMCanvasWindow alloc] initWithContentRect:[skin tableToRectAtIndex:1]
                                                                       styleMask:NSBorderlessWindowMask
                                                                         backing:NSBackingStoreBuffered
                                                                           defer:YES] ;
    if (canvasWindow) {
        canvasWindow.contentView = [[ASMCanvasView alloc] initWithFrame:canvasWindow.contentView.bounds];
        [skin pushNSObject:canvasWindow] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

/// hs._asm.canvas.elementSpec() -> table
/// Function
/// Returns the list of attributes and their specifications that are recognized for canvas elements by this module.
///
/// Parameters:
///  * None
///
/// Returns:
///  * A table containing the attributes and specifications defined for this module.
///
/// Notes:
///  * This is primarily for debugging purposes and may be removed in the future.
static int dumpLanguageDictionary(__unused lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TBREAK] ;
    [skin pushNSObject:languageDictionary withOptions:LS_NSDescribeUnknownTypes] ;
    return 1 ;
}

#pragma mark - Module Methods

/// hs._asm.canvas:transformation([matrix]) -> canvasObject | current value
/// Method
/// Get or set the matrix transformation which is applied to every element in the canvas before being individually processed and added to the canvas.
///
/// Parameters:
///  * `matrix` - an optional table specifying the matrix table, as defined by the [hs._asm.canvas.matrix](MATRIX.md) module, to be applied to every element of the canvas, or an explicit `nil` to reset the transformation to the identity matrix.
///
/// Returns:
///  * if an argument is provided, returns the canvasObject, otherwise returns the current value
///
/// Notes:
///  * An example use for this method would be to change the canvas's origin point { x = 0, y = 0 } from the lower left corner of the canvas to somewhere else, like the middle of the canvas.
static int canvas_canvasTransformation(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TTABLE | LS_TNIL | LS_TOPTIONAL, LS_TBREAK] ;
    ASMCanvasWindow *canvasWindow = [skin luaObjectAtIndex:1 toClass:"ASMCanvasWindow"] ;
    ASMCanvasView   *canvasView   = (ASMCanvasView *)canvasWindow.contentView ;

    if (lua_gettop(L) == 1) {
        [skin pushNSObject:canvasView.canvasTransform] ;
    } else {
        NSAffineTransform *transform = [NSAffineTransform transform] ;
        if (lua_type(L, 2) == LUA_TTABLE) transform = [skin luaObjectAtIndex:2 toClass:"NSAffineTransform"] ;
        canvasView.canvasTransform = transform ;
        canvasView.needsDisplay = true ;
        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.canvas:show([fadeInTime]) -> canvasObject
/// Method
/// Displays the canvas object
///
/// Parameters:
///  * `fadeInTime` - An optional number of seconds over which to fade in the canvas object. Defaults to zero.
///
/// Returns:
///  * The canvas object
static int canvas_show(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TNUMBER | LS_TOPTIONAL,
                    LS_TBREAK] ;

    ASMCanvasWindow *canvasWindow = [skin luaObjectAtIndex:1 toClass:"ASMCanvasWindow"] ;

    if (lua_gettop(L) == 1) {
        [canvasWindow makeKeyAndOrderFront:nil];
    } else {
        [canvasWindow fadeIn:lua_tonumber(L, 2)];
    }

    lua_pushvalue(L, 1);
    return 1;
}

/// hs._asm.canvas:hide([fadeOutTime]) -> canvasObject
/// Method
/// Hides the canvas object
///
/// Parameters:
///  * `fadeOutTime` - An optional number of seconds over which to fade out the canvas object. Defaults to zero.
///
/// Returns:
///  * The canvas object
static int canvas_hide(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TNUMBER | LS_TOPTIONAL,
                    LS_TBREAK] ;

    ASMCanvasWindow *canvasWindow = [skin luaObjectAtIndex:1 toClass:"ASMCanvasWindow"] ;

    if (lua_gettop(L) == 1) {
        [canvasWindow orderOut:nil];
    } else {
        [canvasWindow fadeOut:lua_tonumber(L, 2) andDelete:NO];
    }

    lua_pushvalue(L, 1);
    return 1;
}

/// hs._asm.canvas:mouseCallback(mouseCallbackFn) -> canvasObject
/// Method
/// Sets a callback for mouse events with respect to the canvas
///
/// Parameters:
///  * `mouseCallbackFn`   - A function, can be nil, that will be called when a mouse event occurs within the canvas, and an element beneath the mouse's current position has one of the `trackMouse...` attributes set to true.
///
/// Returns:
///  * The canvas object
///
/// Notes:
///  * The callback function should expect 5 arguments: the canvas object itself, a message specifying the type of mouse event, the canvas element `id` (or index position in the canvas if the `id` attribute is not set for the element), the x position of the mouse when the event was triggered within the rendered portion of the canvas element, and the y position of the mouse when the event was triggered within the rendered portion of the canvas element.
///  * See also [hs._asm.canvas:canvasMouseEvents](#canvasMouseEvents) for tracking mouse events in regions of the canvas not covered by an element with mouse tracking enabled.
///
///  * The following mouse attributes may be set to true for a canvas element and will invoke the callback with the specified message:
///    * `trackMouseDown`      - indicates that a callback should be invoked when a mouse button is clicked down on the canvas element.  The message will be "mouseDown".
///    * `trackMouseUp`        - indicates that a callback should be invoked when a mouse button has been released over the canvas element.  The message will be "mouseUp".
///    * `trackMouseEnterExit` - indicates that a callback should be invoked when the mouse pointer enters or exits the  canvas element.  The message will be "mouseEnter".
///    * `trackMouseMove`      - indicates that a callback should be invoked when the mouse pointer moves within the canvas element.  The message will be "mouseMove".
///
///  * The callback mechanism uses reverse z-indexing to determine which element will receive the callback -- the topmost element of the canvas which has enabled callbacks for the specified message will be invoked.
///
///  * No distinction is made between the left, right, or other mouse buttons. If you need to determine which specific button was pressed, use `hs.eventtap.checkMouseButtons()` within your callback to check.
///
///  * The hit point detection occurs by comparing the mouse pointer location to the rendered content of each individual canvas object... if an object which obscures a lower object does not have mouse tracking enabled, the lower object may still receive the event if it does have tracking enabled.  Likewise, clipping regions which remove content from the visible area of a rendered object are not honored during this test.
static int canvas_mouseCallback(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared];
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TFUNCTION | LS_TNIL,
                    LS_TBREAK] ;

    ASMCanvasWindow *canvasWindow = [skin luaObjectAtIndex:1 toClass:"ASMCanvasWindow"] ;
    ASMCanvasView   *canvasView   = (ASMCanvasView *)canvasWindow.contentView ;

    // We're either removing callback(s), or setting new one(s). Either way, remove existing.
    canvasView.mouseCallbackRef = [skin luaUnref:refTable ref:canvasView.mouseCallbackRef];
    canvasView.previousTrackedIndex = NSNotFound ;
    canvasWindow.ignoresMouseEvents = YES ;

    if (lua_type(L, 2) == LUA_TFUNCTION) {
        lua_pushvalue(L, 2);
        canvasView.mouseCallbackRef = [skin luaRef:refTable] ;
        canvasWindow.ignoresMouseEvents = NO ;
    }

    lua_pushvalue(L, 1);
    return 1;
}

/// hs._asm.canvas:clickActivating([flag]) -> canvasObject | currentValue
/// Method
/// Get or set whether or not clicking on a canvas with a click callback defined should bring all of Hammerspoon's open windows to the front.
///
/// Parameters:
///  * `flag` - an optional boolean indicating whether or not clicking on a canvas with a click callback function defined should activate Hammerspoon and bring its windows forward. Defaults to true.
///
/// Returns:
///  * If an argument is provided, returns the canvas object; otherwise returns the current setting.
///
/// Notes:
///  * Setting this to false changes a canvas object's AXsubrole value and may affect the results of filters used with `hs.window.filter`, depending upon how they are defined.
static int canvas_clickActivating(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TBOOLEAN | LS_TOPTIONAL,
                    LS_TBREAK] ;

    ASMCanvasWindow *canvasWindow = [skin luaObjectAtIndex:1 toClass:"ASMCanvasWindow"] ;

    if (lua_type(L, 2) != LUA_TNONE) {
        if (lua_toboolean(L, 2)) {
            canvasWindow.styleMask &= (unsigned long)~NSNonactivatingPanelMask ;
        } else {
            canvasWindow.styleMask |= NSNonactivatingPanelMask ;
        }
        lua_pushvalue(L, 1) ;
    } else {
        lua_pushboolean(L, ((canvasWindow.styleMask & NSNonactivatingPanelMask) != NSNonactivatingPanelMask)) ;
    }

    return 1;
}

/// hs._asm.canvas:canvasMouseEvents([down], [up], [enterExit], [move]) -> canvasObject | current values
/// Method
/// Get or set whether or not regions of the canvas which are not otherwise covered by an element with mouse tracking enabled should generate a callback for mouse events.
///
/// Parameters:
///  * `down`      - an optional boolean, or nil placeholder, specifying whether or not the mouse button being pushed down should generate a callback for the canvas areas not otherwise covered by an element with mouse tracking enabled.
///  * `up`        - an optional boolean, or nil placeholder, specifying whether or not the mouse button being released should generate a callback for the canvas areas not otherwise covered by an element with mouse tracking enabled.
///  * `enterExit` - an optional boolean, or nil placeholder, specifying whether or not the mouse pointer entering or exiting the canvas bounds should generate a callback for the canvas areas not otherwise covered by an element with mouse tracking enabled.
///  * `move`      - an optional boolean, or nil placeholder, specifying whether or not the mouse pointer moving within the canvas bounds should generate a callback for the canvas areas not otherwise covered by an element with mouse tracking enabled.
///
/// Returns:
///  * If any arguments are provided, returns the canvas Object, otherwise returns the current values as four separate boolean values (i.e. not in a table).
///
/// Notes:
///  * Each value that you wish to set must be provided in the order given above, but you may specify a position as `nil` to indicate that whatever it's current state, no change should be applied.  For example, to activate a callback for entering and exiting the canvas without changing the current callback status for up or down button clicks, you could use: `hs._asm.canvas:canvasMouseTracking(nil, nil, true)`.
///
///  * Use [hs._asm.canvas:mouseCallback](#mouseCallback) to set the callback function.  The identifier field in the callback's argument list will be "_canvas_", but otherwise identical to those specified in [hs._asm.canvas:mouseCallback](#mouseCallback).
static int canvas_canvasMouseEvents(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TBOOLEAN | LS_TNIL | LS_TOPTIONAL,
                    LS_TBOOLEAN | LS_TNIL | LS_TOPTIONAL,
                    LS_TBOOLEAN | LS_TNIL | LS_TOPTIONAL,
                    LS_TBOOLEAN | LS_TNIL | LS_TOPTIONAL,
                    LS_TBREAK] ;

    ASMCanvasWindow *canvasWindow = [skin luaObjectAtIndex:1 toClass:"ASMCanvasWindow"] ;
    ASMCanvasView   *canvasView   = (ASMCanvasView *)canvasWindow.contentView ;

    if (lua_gettop(L) == 1) {
        lua_pushboolean(L, canvasView.canvasMouseDown) ;
        lua_pushboolean(L, canvasView.canvasMouseUp) ;
        lua_pushboolean(L, canvasView.canvasMouseEnterExit) ;
        lua_pushboolean(L, canvasView.canvasMouseMove) ;
        return 4 ;
    } else {
        if (lua_type(L, 2) == LUA_TBOOLEAN) {
            canvasView.canvasMouseDown = (BOOL)lua_toboolean(L, 2) ;
        }
        if (lua_type(L, 3) == LUA_TBOOLEAN) {
            canvasView.canvasMouseUp = (BOOL)lua_toboolean(L, 2) ;
        }
        if (lua_type(L, 4) == LUA_TBOOLEAN) {
            canvasView.canvasMouseEnterExit = (BOOL)lua_toboolean(L, 2) ;
        }
        if (lua_type(L, 5) == LUA_TBOOLEAN) {
            canvasView.canvasMouseMove = (BOOL)lua_toboolean(L, 2) ;
        }

        lua_pushvalue(L, 1) ;
        return 1;
    }
}

/// hs._asm.canvas:topLeft([point]) -> canvasObject | currentValue
/// Method
/// Get or set the top-left coordinate of the canvas object
///
/// Parameters:
///  * `point` - An optional point-table specifying the new coordinate the top-left of the canvas object should be moved to
///
/// Returns:
///  * If an argument is provided, the canvas object; otherwise the current value.
///
/// Notes:
///  * a point-table is a table with key-value pairs specifying the new top-left coordinate on the screen of the canvas (keys `x`  and `y`). The table may be crafted by any method which includes these keys, including the use of an `hs.geometry` object.
static int canvas_topLeft(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared];
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TTABLE | LS_TOPTIONAL,
                    LS_TBREAK] ;

    ASMCanvasWindow *canvasWindow = [skin luaObjectAtIndex:1 toClass:"ASMCanvasWindow"] ;
    NSRect oldFrame = RectWithFlippedYCoordinate(canvasWindow.frame);

    if (lua_gettop(L) == 1) {
        [skin pushNSPoint:oldFrame.origin] ;
    } else {
        NSPoint newCoord = [skin tableToPointAtIndex:2] ;
        NSRect  newFrame = RectWithFlippedYCoordinate(NSMakeRect(newCoord.x, newCoord.y, oldFrame.size.width, oldFrame.size.height)) ;
        [canvasWindow setFrame:newFrame display:YES animate:NO];
        lua_pushvalue(L, 1);
    }
    return 1;
}

/// hs._asm.canvas:imageFromCanvas([rect]) -> hs.image object
/// Method
/// Returns an image of the canvas contents as an `hs.image` object.
///
/// Parameters:
///  * `rect` - an optional rect-table specifying the rectangle within the canvas to create an image of. Defaults to the full canvas.
///
/// Returns:
///  * an `hs.image` object
///
/// Notes:
///  * a rect-table is a table with key-value pairs specifying the top-left coordinate within the canvas (keys `x`  and `y`) and the size (keys `h` and `w`) of the rectangle.  The table may be crafted by any method which includes these keys, including the use of an `hs.geometry` object.
///
///  * The canvas does not have to be visible in order for an image to be generated from it.
static int canvas_canvasAsImage(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared];
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TTABLE | LS_TOPTIONAL,
                    LS_TBREAK] ;

    ASMCanvasWindow *canvasWindow = [skin luaObjectAtIndex:1 toClass:"ASMCanvasWindow"] ;
    ASMCanvasView   *canvasView   = (ASMCanvasView *)canvasWindow.contentView ;
    NSRect canvasFrame = canvasView.bounds ;

    if (lua_gettop(L) == 2) {
        canvasFrame = [skin tableToRectAtIndex:2] ;
    }
    NSData  *pdfData = [canvasView dataWithPDFInsideRect:canvasFrame] ;
    NSImage *image   = [[NSImage alloc] initWithData:pdfData] ;
    [skin pushNSObject:image] ;
    return 1;
}



/// hs._asm.canvas:size([size]) -> canvasObject | currentValue
/// Method
/// Get or set the size of a canvas object
///
/// Parameters:
///  * `size` - An optional size-table specifying the width and height the canvas object should be resized to
///
/// Returns:
///  * If an argument is provided, the canvas object; otherwise the current value.
///
/// Notes:
///  * a size-table is a table with key-value pairs specifying the size (keys `h` and `w`) the canvas should be resized to. The table may be crafted by any method which includes these keys, including the use of an `hs.geometry` object.
///
///  * elements in the canvas that have the `absolutePosition` attribute set to false will be moved so that their relative position within the canvas remains the same with respect to the new size.
///  * elements in the canvas that have the `absoluteSize` attribute set to false will be resized so that their relative size with respect to the canvas remains the same with respect to the new size.
static int canvas_size(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared];
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TTABLE | LS_TOPTIONAL,
                    LS_TBREAK] ;

    ASMCanvasWindow *canvasWindow = [skin luaObjectAtIndex:1 toClass:"ASMCanvasWindow"] ;
    ASMCanvasView   *canvasView   = (ASMCanvasView *)canvasWindow.contentView ;

    NSRect oldFrame = canvasWindow.frame;

    if (lua_gettop(L) == 1) {
        [skin pushNSSize:oldFrame.size] ;
    } else {
        NSSize newSize  = [skin tableToSizeAtIndex:2] ;
        NSRect newFrame = NSMakeRect(oldFrame.origin.x, oldFrame.origin.y + oldFrame.size.height - newSize.height, newSize.width, newSize.height);

        CGFloat xFactor = newFrame.size.width / oldFrame.size.width ;
        CGFloat yFactor = newFrame.size.height / oldFrame.size.height ;

        for (NSUInteger i = 0 ; i < [canvasView.elementList count] ; i++) {
            NSNumber *absPos = [canvasView getElementValueFor:@"absolutePosition" atIndex:i] ;
            NSNumber *absSiz = [canvasView getElementValueFor:@"absoluteSize" atIndex:i] ;
            if (absPos && absSiz) {
                BOOL absolutePosition = absPos ? [absPos boolValue] : YES ;
                BOOL absoluteSize     = absSiz ? [absSiz boolValue] : YES ;
                NSMutableDictionary *attributeDefinition = canvasView.elementList[i] ;
                if (!absolutePosition) {
                    [attributeDefinition enumerateKeysAndObjectsUsingBlock:^(NSString *keyName, id keyValue, __unused BOOL *stop) {
                        if ([keyName isEqualToString:@"center"] || [keyName isEqualToString:@"frame"]) {
                            if ([keyValue[@"x"] isKindOfClass:[NSNumber class]]) {
                                keyValue[@"x"] = [NSNumber numberWithDouble:([keyValue[@"x"] doubleValue] * xFactor)] ;
                            }
                            if ([keyValue[@"y"] isKindOfClass:[NSNumber class]]) {
                                keyValue[@"y"] = [NSNumber numberWithDouble:([keyValue[@"y"] doubleValue] * yFactor)] ;
                            }
                        } else if ([keyName isEqualTo:@"coordinates"]) {
                            [(NSMutableArray *)keyValue enumerateObjectsUsingBlock:^(NSMutableDictionary *subItem, __unused NSUInteger idx, __unused BOOL *stop2) {
                                for (NSString *field in @[ @"x", @"y", @"c1x", @"c1y", @"c2x", @"c2y" ]) {
                                    if (subItem[field] && [subItem[field] isKindOfClass:[NSNumber class]]) {
                                        CGFloat ourFactor = [field hasSuffix:@"x"] ? xFactor : yFactor ;
                                        subItem[field] = [NSNumber numberWithDouble:([subItem[field] doubleValue] * ourFactor)] ;
                                    }
                                }
                            }] ;

                        }
                    }] ;
                }
                if (!absoluteSize) {
                    [attributeDefinition enumerateKeysAndObjectsUsingBlock:^(NSString *keyName, id keyValue, __unused BOOL *stop) {
                        if ([keyName isEqualToString:@"frame"]) {
                            if ([keyValue[@"h"] isKindOfClass:[NSNumber class]]) {
                                keyValue[@"h"] = [NSNumber numberWithDouble:([keyValue[@"h"] doubleValue] * yFactor)] ;
                            }
                            if ([keyValue[@"w"] isKindOfClass:[NSNumber class]]) {
                                keyValue[@"w"] = [NSNumber numberWithDouble:([keyValue[@"w"] doubleValue] * xFactor)] ;
                            }
                        } else if ([keyName isEqualToString:@"radius"]) {
                            if ([keyValue isKindOfClass:[NSNumber class]]) {
                                attributeDefinition[keyName] = [NSNumber numberWithDouble:([keyValue doubleValue] * xFactor)] ;
                            }
                        }
                    }] ;
                }
            } else {
                [skin logError:[NSString stringWithFormat:@"%s:unable to get absolute positioning info for index position %lu", USERDATA_TAG, i + 1]] ;
            }
        }
        [canvasWindow setFrame:newFrame display:YES animate:NO];
        lua_pushvalue(L, 1);
    }
    return 1;
}

/// hs._asm.canvas:alpha([alpha]) -> canvasObject | currentValue
/// Method
/// Get or set the alpha level of the window containing the canvasObject.
///
/// Parameters:
///  * `alpha` - an optional number specifying the new alpha level (0.0 - 1.0, inclusive) for the canvasObject
///
/// Returns:
///  * If an argument is provided, the canvas object; otherwise the current value.
static int canvas_alpha(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared];
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TNUMBER | LS_TOPTIONAL,
                    LS_TBREAK] ;

    ASMCanvasWindow *canvasWindow = [skin luaObjectAtIndex:1 toClass:"ASMCanvasWindow"] ;

    if (lua_gettop(L) == 1) {
        lua_pushnumber(L, canvasWindow.alphaValue) ;
    } else {
        CGFloat newLevel = luaL_checknumber(L, 2);
        canvasWindow.alphaValue = ((newLevel < 0.0) ? 0.0 : ((newLevel > 1.0) ? 1.0 : newLevel)) ;
        lua_pushvalue(L, 1);
    }

    return 1 ;
}

/// hs._asm.canvas:orderAbove([canvas2]) -> canvasObject
/// Method
/// Moves canvas object above canvas2, or all canvas objects in the same presentation level, if canvas2 is not given.
///
/// Parameters:
///  * `canvas2` -An optional canvas object to place the canvas object above.
///
/// Returns:
///  * The canvas object
///
/// Notes:
///  * If the canvas object and canvas2 are not at the same presentation level, this method will will move the canvas object as close to the desired relationship as possible without changing the canvas object's presentation level. See [hs._asm.canvas.level](#level).
static int canvas_orderAbove(lua_State *L) {
    return canvas_orderHelper(L, NSWindowAbove) ;
}

/// hs._asm.canvas:orderBelow([canvas2]) -> canvasObject
/// Method
/// Moves canvas object below canvas2, or all canvas objects in the same presentation level, if canvas2 is not given.
///
/// Parameters:
///  * `canvas2` -An optional canvas object to place the canvas object below.
///
/// Returns:
///  * The canvas object
///
/// Notes:
///  * If the canvas object and canvas2 are not at the same presentation level, this method will will move the canvas object as close to the desired relationship as possible without changing the canvas object's presentation level. See [hs._asm.canvas.level](#level).
static int canvas_orderBelow(lua_State *L) {
    return canvas_orderHelper(L, NSWindowBelow) ;
}

/// hs._asm.canvas:level([level]) -> canvasObject | currentValue
/// Method
/// Sets the window level more precisely than sendToBack and bringToFront.
///
/// Parameters:
///  * `level` - an optional level, specified as a number or as a string, specifying the new window level for the canvasObject. If it is a string, it must match one of the keys in `hs.drawing.windowLevels`.
///
/// Returns:
///  * If an argument is provided, the canvas object; otherwise the current value.
///
/// Notes:
///  * see the notes for `hs.drawing.windowLevels`
static int canvas_level(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared];
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TNUMBER | LS_TSTRING | LS_TOPTIONAL,
                    LS_TBREAK] ;

    ASMCanvasWindow *canvasWindow = [skin luaObjectAtIndex:1 toClass:"ASMCanvasWindow"] ;

    if (lua_gettop(L) == 1) {
        lua_pushinteger(L, [canvasWindow level]) ;
    } else {
        lua_Integer targetLevel ;
        if (lua_type(L, 2) == LUA_TNUMBER) {
            [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                            LS_TNUMBER | LS_TINTEGER,
                            LS_TBREAK] ;
            targetLevel = lua_tointeger(L, 2) ;
        } else {
            if ([skin requireModule:"hs.drawing"]) {
                if (lua_getfield(L, -1, "windowLevels") == LUA_TTABLE) {
                    if (lua_getfield(L, -1, [[skin toNSObjectAtIndex:2] UTF8String]) == LUA_TNUMBER) {
                        targetLevel = lua_tointeger(L, -1) ;
                        lua_pop(L, 3) ; // value, windowLevels and hs.drawing
                    } else {
                        lua_pop(L, 3) ; // wrong value, windowLevels and hs.drawing
                        return luaL_error(L, [[NSString stringWithFormat:@"unrecognized window level: %@", [skin toNSObjectAtIndex:2]] UTF8String]) ;
                    }
                } else {
                    NSString *errorString = [NSString stringWithFormat:@"hs.drawing.windowLevels - table expected, found %s", lua_typename(L, (lua_type(L, -1)))] ;
                    lua_pop(L, 2) ; // windowLevels and hs.drawing
                    return luaL_error(L, [errorString UTF8String]) ;
                }
            } else {
                NSString *errorString = [NSString stringWithFormat:@"unable to load hs.drawing module to access windowLevels table:%s", lua_tostring(L, -1)] ;
                lua_pop(L, 1) ;
                return luaL_error(L, [errorString UTF8String]) ;
            }
        }

        targetLevel = (targetLevel < CGWindowLevelForKey(kCGMinimumWindowLevelKey)) ? CGWindowLevelForKey(kCGMinimumWindowLevelKey) : ((targetLevel > CGWindowLevelForKey(kCGMaximumWindowLevelKey)) ? CGWindowLevelForKey(kCGMaximumWindowLevelKey) : targetLevel) ;
        [canvasWindow setLevel:targetLevel] ;
        lua_pushvalue(L, 1) ;
    }

    return 1 ;
}

/// hs._asm.canvas:wantsLayer([flag]) -> canvasObject | currentValue
/// Method
/// Get or set whether or not the canvas object should be rendered by the view or by Core Animation.
///
/// Parameters:
///  * `flag` - optional boolean (default false) which indicates whether the canvas object should be rendered by the containing view (false) or by Core Animation (true).
///
/// Returns:
///  * If an argument is provided, the canvas object; otherwise the current value.
///
/// Notes:
///  * This method can help smooth the display of small text objects on non-Retina monitors.
static int canvas_wantsLayer(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TBOOLEAN | LS_TOPTIONAL,
                    LS_TBREAK] ;

    ASMCanvasWindow *canvasWindow = [skin luaObjectAtIndex:1 toClass:"ASMCanvasWindow"] ;
    ASMCanvasView   *canvasView   = (ASMCanvasView *)canvasWindow.contentView ;

    if (lua_type(L, 2) != LUA_TNONE) {
        [canvasView setWantsLayer:(BOOL)lua_toboolean(L, 2)];
        canvasView.needsDisplay = true ;
        lua_pushvalue(L, 1) ;
    } else {
        lua_pushboolean(L, (BOOL)[canvasView wantsLayer]) ;
    }

    return 1;
}

/// hs._asm.canvas:behavior([behavior]) -> canvasObject | currentValue
/// Method
/// Get or set the window behavior settings for the canvas object.
///
/// Parameters:
///  * `behavior` - an optional number representing the desired window behaviors for the canvas object.
///
/// Returns:
///  * If an argument is provided, the canvas object; otherwise the current value.
///
/// Notes:
///  * Window behaviors determine how the canvas object is handled by Spaces and Exposé. See `hs.drawing.windowBehaviors` for more information.
static int canvas_behavior(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TNUMBER | LS_TOPTIONAL,
                    LS_TBREAK] ;

    ASMCanvasWindow *canvasWindow = [skin luaObjectAtIndex:1 toClass:"ASMCanvasWindow"] ;

    if (lua_gettop(L) == 1) {
        lua_pushinteger(L, [canvasWindow collectionBehavior]) ;
    } else {
        [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                        LS_TNUMBER | LS_TINTEGER,
                        LS_TBREAK] ;

        NSInteger newLevel = lua_tointeger(L, 2);
        @try {
            [canvasWindow setCollectionBehavior:(NSWindowCollectionBehavior)newLevel] ;
        }
        @catch ( NSException *theException ) {
            return luaL_error(L, "%s: %s", [[theException name] UTF8String], [[theException reason] UTF8String]) ;
        }

        lua_pushvalue(L, 1);
    }

    return 1 ;
}

/// hs._asm.canvas:delete([fadeOutTime]) -> none
/// Method
/// Destroys the canvas object, optionally fading it out first (if currently visible).
///
/// Parameters:
///  * `fadeOutTime` - An optional number of seconds over which to fade out the canvas object. Defaults to zero.
///
/// Returns:
///  * None
///
/// Notes:
///  * This method is automatically called during garbage collection, notably during a Hammerspoon termination or reload, with a fade time of 0.
static int canvas_delete(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TNUMBER | LS_TOPTIONAL,
                    LS_TBREAK] ;

    ASMCanvasWindow *canvasWindow = [skin luaObjectAtIndex:1 toClass:"ASMCanvasWindow"] ;
    if ((lua_gettop(L) == 1) || (![canvasWindow isVisible])) {
        lua_pushcfunction(L, userdata_gc) ;
        lua_pushvalue(L, 1) ;
        if (lua_pcall(L, 1, 0, 0) != LUA_OK) {
            [skin logBreadcrumb:[NSString stringWithFormat:@"%s:error invoking _gc for delete method:%s", USERDATA_TAG, lua_tostring(L, -1)]] ;
            lua_pop(L, 1) ;
            [canvasWindow close] ; // the least we can do is close the canvas if an error occurs with __gc
        }
    } else {
        [canvasWindow fadeOut:lua_tonumber(L, 2) andDelete:YES];
    }

    lua_pushnil(L);
    return 1;
}

/// hs._asm.canvas:isShowing() -> boolean
/// Method
/// Returns whether or not the canvas is currently being shown.
///
/// Parameters:
///  * None
///
/// Returns:
///  * a boolean indicating whether or not the canvas is currently being shown (true) or is currently hidden (false).
///
/// Notes:
///  * This method only determines whether or not the canvas is being shown or is hidden -- it does not indicate whether or not the canvas is currently off screen or is occluded by other objects.
///  * See also [hs._asm.canvas:isOccluded](#isOccluded).
static int canvas_isShowing(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TBREAK] ;

    ASMCanvasWindow *canvasWindow = [skin luaObjectAtIndex:1 toClass:"ASMCanvasWindow"] ;
    lua_pushboolean(L, [canvasWindow isVisible]) ;
    return 1 ;
}

/// hs._asm.canvas:isOccluded() -> boolean
/// Method
/// Returns whether or not the canvas is currently occluded (hidden by other windows, off screen, etc).
///
/// Parameters:
///  * None
///
/// Returns:
///  * a boolean indicating whether or not the canvas is currently being occluded.
///
/// Notes:
///  * If any part of the canvas is visible (even if that portion of the canvas does not contain any canvas elements), then the canvas is not considered occluded.
///  * a canvas which is completely covered by one or more opaque windows is considered occluded; however, if the windows covering the canvas are not opaque, then the canvas is not occluded.
///  * a canvas that is currently hidden or with a height of 0 or a width of 0 is considered occluded.
///  * See also [hs._asm.canvas:isShowing](#isShowing).
static int canvas_isOccluded(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TBREAK] ;

    ASMCanvasWindow *canvasWindow = [skin luaObjectAtIndex:1 toClass:"ASMCanvasWindow"] ;
    lua_pushboolean(L, ([canvasWindow occlusionState] & NSWindowOcclusionStateVisible) != NSWindowOcclusionStateVisible) ;
    return 1 ;
}

/// hs._asm.canvas:canvasDefaultFor(keyName, [newValue]) -> canvasObject | currentValue
/// Method
/// Get or set the element default specified by keyName.
///
/// Paramters:
///  * `keyName` - the element default to examine or modify
///  * `value`   - an optional new value to set as the default fot his canvas when not specified explicitly in an element declaration.
///
/// Returns:
///  * If an argument is provided, the canvas object; otherwise the current value.
///
/// Notes:
///  * Not all keys will apply to all element types.
///  * Currently set and built-in defaults may be retrieved in a table with [hs._asm.canvas:canvasDefaults](#canvasDefaults).
static int canvas_canvasDefaultFor(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TSTRING,
                    LS_TANY | LS_TOPTIONAL,
                    LS_TBREAK] ;

    ASMCanvasWindow *canvasWindow = [skin luaObjectAtIndex:1 toClass:"ASMCanvasWindow"] ;
    ASMCanvasView   *canvasView   = (ASMCanvasView *)canvasWindow.contentView ;
    NSString *keyName = [skin toNSObjectAtIndex:2] ;

    if (!languageDictionary[keyName]) {
        return luaL_argerror(L, 2, [[NSString stringWithFormat:@"attribute name %@ unrecognized", keyName] UTF8String]) ;
    }

    id attributeDefault = [canvasView getDefaultValueFor:keyName onlyIfSet:NO] ;
    if (!attributeDefault) {
        return luaL_argerror(L, 2, [[NSString stringWithFormat:@"attribute %@ has no default value", keyName] UTF8String]) ;
    }

    if (lua_gettop(L) == 2) {
        [skin pushNSObject:attributeDefault] ;
    } else {
        id keyValue = [skin toNSObjectAtIndex:3 withOptions:LS_NSRawTables] ;

        switch([canvasView setDefaultFor:keyName to:keyValue]) {
            case attributeValid:
            case attributeNulling:
                break ;
            case attributeInvalid:
            default:
                if ([languageDictionary[keyName][@"nullable"] boolValue]) {
                    return luaL_argerror(L, 3, [[NSString stringWithFormat:@"invalid argument type for %@ specified", keyName] UTF8String]) ;
                } else {
                    return luaL_argerror(L, 2, [[NSString stringWithFormat:@"attribute default for %@ cannot be changed", keyName] UTF8String]) ;
                }
//                 break ;
        }

        lua_pushvalue(L, 1) ;
    }
    return 1 ;
}

/// hs._asm.canvas:insertElement(elementTable, [index]) -> canvasObject
/// Method
/// Insert a new element into the canvas at the specified index.
///
/// Parameters:
///  * `elementTable` - a table containing key-value pairs that define the element to be added to the canvas.
///  * `index`        - an optional integer between 1 and the canvas element count + 1 specifying the index position to put the new element.  Any element currently at that index, and those that follow, will be moved one position up in the element array.  Defaults to the canvas element count + 1 (i.e. after the end of the currently defined elements).
///
/// Returns:
///  * the canvasObject
///
/// Notes:
///  * see also [hs._asm.canvas:assignElement](#assignElement).
static int canvas_insertElementAtIndex(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TTABLE,
                    LS_TNUMBER | LS_TINTEGER | LS_TOPTIONAL,
                    LS_TBREAK] ;
    ASMCanvasWindow *canvasWindow = [skin luaObjectAtIndex:1 toClass:"ASMCanvasWindow"] ;
    ASMCanvasView   *canvasView   = (ASMCanvasView *)canvasWindow.contentView ;
    NSUInteger      elementCount  = [canvasView.elementList count] ;
    NSInteger       tablePosition = (lua_gettop(L) == 3) ? (lua_tointeger(L, 3) - 1) : (NSInteger)elementCount ;

    if (tablePosition < 0 || tablePosition > (NSInteger)elementCount) {
        return luaL_argerror(L, 3, [[NSString stringWithFormat:@"index %ld out of bounds", tablePosition + 1] UTF8String]) ;
    }

    NSDictionary *element = [skin toNSObjectAtIndex:2 withOptions:LS_NSRawTables] ;
    if ([element isKindOfClass:[NSDictionary class]]) {
        NSString *elementType = element[@"type"] ;
        if (elementType && [ALL_TYPES containsObject:elementType]) {
            [canvasView.elementList insertObject:[[NSMutableDictionary alloc] init] atIndex:(NSUInteger)tablePosition] ;
            [element enumerateKeysAndObjectsUsingBlock:^(NSString *keyName, id keyValue, __unused BOOL *stop) {
                // skip type in here to minimize the need to copy in defaults just to be overwritten
                if (![keyName isEqualTo:@"type"]) [canvasView setElementValueFor:keyName atIndex:(NSUInteger)tablePosition to:keyValue] ;
            }] ;
            [canvasView setElementValueFor:@"type" atIndex:(NSUInteger)tablePosition to:elementType] ;
        } else {
            return luaL_argerror(L, 2, [[NSString stringWithFormat:@"invalid type %@; must be one of %@", elementType, [ALL_TYPES componentsJoinedByString:@", "]] UTF8String]) ;
        }
    } else {
        return luaL_argerror(L, 2, "invalid element definition; must contain key-value pairs");
    }

    canvasView.needsDisplay = true ;
    lua_pushvalue(L, 1) ;
    return 1 ;
}

/// hs._asm.canvas:removeElement([index]) -> canvasObject
/// Method
/// Insert a new element into the canvas at the specified index.
///
/// Parameters:
///  * `index`        - an optional integer between 1 and the canvas element count specifying the index of the canvas element to remove. Any elements that follow, will be moved one position down in the element array.  Defaults to the canvas element count (i.e. the last element of the currently defined elements).
///
/// Returns:
///  * the canvasObject
static int canvas_removeElementAtIndex(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TNUMBER | LS_TINTEGER | LS_TOPTIONAL,
                    LS_TBREAK] ;
    ASMCanvasWindow *canvasWindow = [skin luaObjectAtIndex:1 toClass:"ASMCanvasWindow"] ;
    ASMCanvasView   *canvasView   = (ASMCanvasView *)canvasWindow.contentView ;
    NSUInteger      elementCount  = [canvasView.elementList count] ;
    NSInteger       tablePosition = (lua_gettop(L) == 2) ? (lua_tointeger(L, 2) - 1) : (NSInteger)elementCount - 1 ;

    if (tablePosition < 0 || tablePosition >= (NSInteger)elementCount) {
        return luaL_argerror(L, 2, [[NSString stringWithFormat:@"index %ld out of bounds", tablePosition + 1] UTF8String]) ;
    }

    [canvasView.elementList removeObjectAtIndex:(NSUInteger)tablePosition] ;

    canvasView.needsDisplay = true ;
    lua_pushvalue(L, 1) ;
    return 1 ;
}

/// hs._asm.canvas:elementAttribute(index, key, [value]) -> canvasObject | current value
/// Method
/// Get or set the attribute `key` for the canvas element at the specified index.
///
/// Parameters:
///  * `index` - the index of the canvas element whose attribute is to be retrieved or set.
///  * `key`   - the key name of the attribute to get or set.
///  * `value` - an optional value to assign to the canvas element's attribute.
///
/// Returns:
///  * if a value for the attribute is specified, returns the canvas object; otherwise returns the current value for the specified attribute.
static int canvas_elementAttributeAtIndex(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TNUMBER | LS_TINTEGER,
                    LS_TSTRING,
                    LS_TANY | LS_TOPTIONAL,
                    LS_TBREAK] ;
    ASMCanvasWindow *canvasWindow = [skin luaObjectAtIndex:1 toClass:"ASMCanvasWindow"] ;
    ASMCanvasView   *canvasView   = (ASMCanvasView *)canvasWindow.contentView ;
    NSString        *keyName      = [skin toNSObjectAtIndex:3] ;

    NSUInteger      elementCount  = [canvasView.elementList count] ;
    NSInteger       tablePosition = lua_tointeger(L, 2) - 1 ;

    BOOL            resolvePercentages = NO ;

    if (tablePosition < 0 || tablePosition >= (NSInteger)elementCount) {
        return luaL_argerror(L, 2, [[NSString stringWithFormat:@"index %ld out of bounds", tablePosition + 1] UTF8String]) ;
    }

    if (!languageDictionary[keyName]) {
        if (lua_gettop(L) == 3) {
            // check if keyname ends with _raw, if so we get with converted numeric values
            if ([keyName hasSuffix:@"_raw"]) {
                keyName = [keyName substringWithRange:NSMakeRange(0, [keyName length] - 4)] ;
                if (languageDictionary[keyName]) resolvePercentages = YES ;
            }
            if (!resolvePercentages) {
                lua_pushnil(L) ;
                return 1 ;
            }
        } else {
            return luaL_argerror(L, 3, [[NSString stringWithFormat:@"attribute name %@ unrecognized", keyName] UTF8String]) ;
        }
    }

    if (lua_gettop(L) == 3) {
        [skin pushNSObject:[canvasView getElementValueFor:keyName atIndex:(NSUInteger)tablePosition resolvePercentages:resolvePercentages onlyIfSet:NO]] ;
    } else {
        id keyValue = [skin toNSObjectAtIndex:4 withOptions:LS_NSRawTables] ;
        switch([canvasView setElementValueFor:keyName atIndex:(NSUInteger)tablePosition to:keyValue]) {
            case attributeValid:
            case attributeNulling:
                lua_pushvalue(L, 1) ;
                break ;
            case attributeInvalid:
            default:
                return luaL_argerror(L, 4, [[NSString stringWithFormat:@"invalid argument type for %@ specified", keyName] UTF8String]) ;
//                 break ;
        }
    }
    return 1 ;
}

/// hs._asm.canvas:elementKeys(index, [optional]) -> table
/// Method
/// Returns a list of the key names for the attributes set for the canvas element at the specified index.
///
/// Parameters:
///  * `index`    - the index of the element to get the assigned key list from.
///  * `optional` - an optional boolean, default false, indicating whether optional, but unset, keys relevant to this canvas object should also be included in the list returned.
///
/// Returns:
///  * a table containing the keys that are set for this canvas element.  May also optionally include keys which are not specifically set for this element but use inherited values from the canvas or module defaults.
///
/// Notes:
///  * Any attribute which has been explicitly set for the element will be included in the key list (even if it is ignored for the element type).  If the `optional` flag is set to true, the *additional* attribute names added to the list will only include those which are relevant to the element type.
static int canvas_elementKeysAtIndex(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TNUMBER | LS_TINTEGER,
                    LS_TBOOLEAN | LS_TOPTIONAL,
                    LS_TBREAK] ;
    ASMCanvasWindow *canvasWindow = [skin luaObjectAtIndex:1 toClass:"ASMCanvasWindow"] ;
    ASMCanvasView   *canvasView   = (ASMCanvasView *)canvasWindow.contentView ;
    NSUInteger      elementCount  = [canvasView.elementList count] ;
    NSInteger       tablePosition = lua_tointeger(L, 2) - 1 ;

    if (tablePosition < 0 || tablePosition >= (NSInteger)elementCount) {
        return luaL_argerror(L, 2, [[NSString stringWithFormat:@"index %ld out of bounds", tablePosition + 1] UTF8String]) ;
    }
    NSUInteger indexPosition = (NSUInteger)tablePosition ;

    NSMutableSet *list = [[NSMutableSet alloc] initWithArray:[(NSDictionary *)canvasView.elementList[indexPosition] allKeys]] ;
    if ((lua_gettop(L) == 3) && lua_toboolean(L, 3)) {
        NSString *ourType = canvasView.elementList[indexPosition][@"type"] ;
        [languageDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *keyName, NSDictionary *keyValue, __unused BOOL *stop) {
            if (keyValue[@"optionalFor"] && [keyValue[@"optionalFor"] containsObject:ourType]) {
                [list addObject:keyName] ;
            }
        }] ;
    }
    [skin pushNSObject:list] ;
    return 1 ;
}

/// hs._asm.canvas:elementCount() -> integer
/// Method
/// Returns the number of elements currently defined for the canvas object.
///
/// Parameters:
///  * None
///
/// Returns:
///  * the number of elements currently defined for the canvas object.
static int canvas_elementCount(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    ASMCanvasWindow *canvasWindow = [skin luaObjectAtIndex:1 toClass:"ASMCanvasWindow"] ;
    ASMCanvasView   *canvasView   = (ASMCanvasView *)canvasWindow.contentView ;
    lua_pushinteger(L, (lua_Integer)[canvasView.elementList count]) ;
    return 1 ;
}

/// hs._asm.canvas:canvasDefaults([module]) -> table
/// Method
/// Get a table of the default key-value pairs which apply to the canvas.
///
/// Parameters:
///  * `module` - an optional boolean flag, default false, indicating whether module defaults (true) should be included in the table.  If false, only those defaults which have been explicitly set for the canvas are returned.
///
/// Returns:
///  * a table containing key-value pairs for the defaults which apply to the canvas.
///
/// Notes:
///  * Not all keys will apply to all element types.
///  * To change the defaults for the canvas, use [hs._asm.canvas:canvasDefaultFor](#canvasDefaultFor).
static int canvas_canvasDefaults(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TBOOLEAN | LS_TOPTIONAL,
                    LS_TBREAK] ;
    ASMCanvasWindow *canvasWindow = [skin luaObjectAtIndex:1 toClass:"ASMCanvasWindow"] ;
    ASMCanvasView   *canvasView   = (ASMCanvasView *)canvasWindow.contentView ;
    if ((lua_gettop(L) == 2) && lua_toboolean(L, 2)) {
        lua_newtable(L) ;
        for (NSString *keyName in languageDictionary) {
            id keyValue = [canvasView getDefaultValueFor:keyName onlyIfSet:NO] ;
            if (keyValue) {
                [skin pushNSObject:keyValue] ; lua_setfield(L, -2, [keyName UTF8String]) ;
            }
        }
    } else {
        [skin pushNSObject:canvasView.canvasDefaults withOptions:LS_NSDescribeUnknownTypes] ;
    }
    return 1 ;
}

/// hs._asm.canvas:canvasDefaultKeys([module]) -> table
/// Method
/// Returns a list of the key names for the attributes set for the canvas defaults.
///
/// Parameters:
///  * `module` - an optional boolean flag, default false, indicating whether the key names for the module defaults (true) should be included in the list.  If false, only those defaults which have been explicitly set for the canvas are included.
///
/// Returns:
///  * a table containing the key names for the defaults which are set for this canvas. May also optionally include key names for all attributes which have a default value defined by the module.
static int canvas_canvasDefaultKeys(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TBOOLEAN | LS_TOPTIONAL,
                    LS_TBREAK] ;
    ASMCanvasWindow *canvasWindow = [skin luaObjectAtIndex:1 toClass:"ASMCanvasWindow"] ;
    ASMCanvasView   *canvasView   = (ASMCanvasView *)canvasWindow.contentView ;

    NSMutableSet *list = [[NSMutableSet alloc] initWithArray:[(NSDictionary *)canvasView.canvasDefaults allKeys]] ;
    if ((lua_gettop(L) == 3) && lua_toboolean(L, 3)) {
        [languageDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *keyName, NSDictionary *keyValue, __unused BOOL *stop) {
            if (keyValue[@"default"]) {
                [list addObject:keyName] ;
            }
        }] ;
    }
    [skin pushNSObject:list] ;
    return 1 ;
}

/// hs._asm.canvas:canvasElements() -> table
/// Method
/// Returns an array containing the elements defined for this canvas.  Each array entry will be a table containing the key-value pairs which have been set for that canvas element.
///
/// Parameters:
///  * None
///
/// Returns:
///  * an array of element tables which are defined for the canvas.
static int canvas_canvasElements(__unused lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TBREAK] ;
    ASMCanvasWindow *canvasWindow = [skin luaObjectAtIndex:1 toClass:"ASMCanvasWindow"] ;
    ASMCanvasView   *canvasView   = (ASMCanvasView *)canvasWindow.contentView ;
    [skin pushNSObject:canvasView.elementList withOptions:LS_NSDescribeUnknownTypes] ;
    return 1 ;
}

/// hs._asm.canvas:elementBounds(index) -> rectTable
/// Method
/// Returns the smallest rectangle which can fully contain the canvas element at the specified index.
///
/// Parameters:
///  * `index` - the index of the canvas element to get the bounds for
///
/// Returns:
///  * a rect table containing the smallest rectangle which can fully contain the canvas element.
///
/// Notes:
///  * For many elements, this will be the same as the element frame.  For items without a frame (e.g. `segments`, `circle`, etc.) this will be the smallest rectangle which can fully contain the canvas element as specified by it's attributes.
static int canvas_elementBoundsAtIndex(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TNUMBER | LS_TINTEGER,
                    LS_TBREAK] ;
    ASMCanvasWindow *canvasWindow = [skin luaObjectAtIndex:1 toClass:"ASMCanvasWindow"] ;
    ASMCanvasView   *canvasView   = (ASMCanvasView *)canvasWindow.contentView ;

    NSUInteger      elementCount  = [canvasView.elementList count] ;
    NSInteger       tablePosition = (lua_tointeger(L, 2) - 1) ;

    if (tablePosition < 0 || tablePosition > (NSInteger)elementCount - 1) {
        return luaL_argerror(L, 3, [[NSString stringWithFormat:@"index %ld out of bounds", tablePosition + 1] UTF8String]) ;
    }

    NSUInteger   idx         = (NSUInteger)tablePosition ;
    NSRect       boundingBox = NSZeroRect ;
    NSBezierPath *itemPath   = [canvasView pathForElementAtIndex:idx] ;
    if (itemPath) {
        boundingBox = [itemPath bounds] ;
    } else {
        NSString *itemType = canvasView.elementList[idx][@"type"] ;
        if ([itemType isEqualToString:@"image"] || [itemType isEqualToString:@"text"] || [itemType isEqualToString:@"canvas"]) {
            NSDictionary *frame = [canvasView getElementValueFor:@"frame"
                                                         atIndex:idx
                                              resolvePercentages:YES] ;
            boundingBox = NSMakeRect([frame[@"x"] doubleValue], [frame[@"y"] doubleValue],
                                     [frame[@"w"] doubleValue], [frame[@"h"] doubleValue]) ;
        } else {
            lua_pushnil(L) ;
            return 1 ;
        }
    }
    [skin pushNSRect:boundingBox] ;
    return 1 ;
}

/// hs._asm.canvas:assignElement(elementTable, [index]) -> canvasObject
/// Method
/// Assigns a new element to the canvas at the specified index.
///
/// Parameters:
///  * `elementTable` - a table containing key-value pairs that define the element to be added to the canvas.
///  * `index`        - an optional integer between 1 and the canvas element count + 1 specifying the index position to put the new element.  Any element currently at that index will be replaced.  Defaults to the canvas element count + 1 (i.e. after the end of the currently defined elements).
///
/// Returns:
///  * the canvasObject
///
/// Notes:
///  * When the index specified is the canvas element count + 1, the behavior of this method is the same as [hs._asm.canvas:insertElement](#insertElement); i.e. it adds the new element to the end of the currently defined element list.
static int canvas_assignElementAtIndex(lua_State *L) {
    LuaSkin *skin = [LuaSkin shared] ;
    [skin checkArgs:LS_TUSERDATA, USERDATA_TAG,
                    LS_TTABLE | LS_TNIL,
                    LS_TNUMBER | LS_TINTEGER | LS_TOPTIONAL,
                    LS_TBREAK] ;
    ASMCanvasWindow *canvasWindow = [skin luaObjectAtIndex:1 toClass:"ASMCanvasWindow"] ;
    ASMCanvasView   *canvasView   = (ASMCanvasView *)canvasWindow.contentView ;

    NSUInteger      elementCount  = [canvasView.elementList count] ;
    NSInteger       tablePosition = (lua_gettop(L) == 3) ? (lua_tointeger(L, 3) - 1) : (NSInteger)elementCount ;

    if (tablePosition < 0 || tablePosition > (NSInteger)elementCount) {
        return luaL_argerror(L, 3, [[NSString stringWithFormat:@"index %ld out of bounds", tablePosition + 1] UTF8String]) ;
    }

    if (lua_isnil(L, 2)) {
        if (tablePosition == (NSInteger)elementCount - 1) {
            [canvasView.elementList removeLastObject] ;
        } else {
            return luaL_argerror(L, 3, "nil only valid for final element") ;
        }
    } else {
        NSDictionary *element = [skin toNSObjectAtIndex:2 withOptions:LS_NSRawTables] ;
        if ([element isKindOfClass:[NSDictionary class]]) {
            NSString *elementType = element[@"type"] ;
            if (elementType && [ALL_TYPES containsObject:elementType]) {
                canvasView.elementList[tablePosition] = [[NSMutableDictionary alloc] init] ;
                [element enumerateKeysAndObjectsUsingBlock:^(NSString *keyName, id keyValue, __unused BOOL *stop) {
                    // skip type in here to minimize the need to copy in defaults just to be overwritten
                    if (![keyName isEqualTo:@"type"]) [canvasView setElementValueFor:keyName atIndex:(NSUInteger)tablePosition to:keyValue] ;
                }] ;
                [canvasView setElementValueFor:@"type" atIndex:(NSUInteger)tablePosition to:elementType] ;
            } else {
                return luaL_argerror(L, 2, [[NSString stringWithFormat:@"invalid type %@; must be one of %@", elementType, [ALL_TYPES componentsJoinedByString:@", "]] UTF8String]) ;
            }
        } else {
            return luaL_argerror(L, 2, "invalid element definition; must contain key-value pairs");
        }
    }

    canvasView.needsDisplay = true ;
    lua_pushvalue(L, 1) ;
    return 1 ;
}

#pragma mark - Module Constants

/// hs._asm.canvas.compositeTypes[]
/// Constant
/// A table containing the possible compositing rules for elements within the canvas.
///
/// Compositing rules specify how an element assigned to the canvas is combined with the earlier elements of the canvas. The default compositing rule for the canvas is `sourceOver`, but each element of the canvas can be assigned a composite type which overrides this default for the specific element.
///
/// The available types are as follows:
///  * `clear`           - Transparent. (R = 0)
///  * `copy`            - Source image. (R = S)
///  * `sourceOver`      - Source image wherever source image is opaque, and destination image elsewhere. (R = S + D*(1 - Sa))
///  * `sourceIn`        - Source image wherever both images are opaque, and transparent elsewhere. (R = S*Da)
///  * `sourceOut`       - Source image wherever source image is opaque but destination image is transparent, and transparent elsewhere. (R = S*(1 - Da))
///  * `sourceAtop`      - Source image wherever both images are opaque, destination image wherever destination image is opaque but source image is transparent, and transparent elsewhere. (R = S*Da + D*(1 - Sa))
///  * `destinationOver` - Destination image wherever destination image is opaque, and source image elsewhere. (R = S*(1 - Da) + D)
///  * `destinationIn`   - Destination image wherever both images are opaque, and transparent elsewhere. (R = D*Sa)
///  * `destinationOut`  - Destination image wherever destination image is opaque but source image is transparent, and transparent elsewhere. (R = D*(1 - Sa))
///  * `destinationAtop` - Destination image wherever both images are opaque, source image wherever source image is opaque but destination image is transparent, and transparent elsewhere. (R = S*(1 - Da) + D*Sa)
///  * `XOR`             - Exclusive OR of source and destination images. (R = S*(1 - Da) + D*(1 - Sa)). Works best with black and white images and is not recommended for color contexts.
///  * `plusDarker`      - Sum of source and destination images, with color values approaching 0 as a limit. (R = MAX(0, (1 - D) + (1 - S)))
///  * `plusLighter`     - Sum of source and destination images, with color values approaching 1 as a limit. (R = MIN(1, S + D))
///
/// In each equation, R is the resulting (premultiplied) color, S is the source color, D is the destination color, Sa is the alpha value of the source color, and Da is the alpha value of the destination color.
///
/// The `source` object is the individual element as it is rendered in order within the canvas, and the `destination` object is the combined state of the previous elements as they have been composited within the canvas.
static int pushCompositeTypes(lua_State *L) {
    lua_newtable(L) ;
      lua_pushstring(L, "clear") ;           lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
      lua_pushstring(L, "copy") ;            lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
      lua_pushstring(L, "sourceOver") ;      lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
      lua_pushstring(L, "sourceIn") ;        lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
      lua_pushstring(L, "sourceOut") ;       lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
      lua_pushstring(L, "sourceAtop") ;      lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
      lua_pushstring(L, "destinationOver") ; lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
      lua_pushstring(L, "destinationIn") ;   lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
      lua_pushstring(L, "destinationOut") ;  lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
      lua_pushstring(L, "destinationAtop") ; lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
      lua_pushstring(L, "XOR") ;             lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
      lua_pushstring(L, "plusDarker") ;      lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
//       lua_pushstring(L, "highlight") ;       lua_rawseti(L, -2, luaL_len(L, -2) + 1) ; // mapped to NSCompositeSourceOver
      lua_pushstring(L, "plusLighter") ;     lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
    return 1 ;
}

#pragma mark - Lua<->NSObject Conversion Functions
// These must not throw a lua error to ensure LuaSkin can safely be used from Objective-C
// delegates and blocks.

static int pushASMCanvasWindow(lua_State *L, id obj) {
    LuaSkin *skin = [LuaSkin shared] ;
    ASMCanvasWindow *value = obj;
    if (value.selfRef == LUA_NOREF) {
        void** valuePtr = lua_newuserdata(L, sizeof(ASMCanvasWindow *));
        *valuePtr = (__bridge_retained void *)value;
        luaL_getmetatable(L, USERDATA_TAG);
        lua_setmetatable(L, -2);
        value.selfRef = [skin luaRef:refTable] ;
    }
    [skin pushLuaRef:refTable ref:value.selfRef] ;
    return 1;
}

static id toASMCanvasWindowFromLua(lua_State *L, int idx) {
    LuaSkin *skin = [LuaSkin shared] ;
    ASMCanvasWindow *value ;
    if (luaL_testudata(L, idx, USERDATA_TAG)) {
        value = get_objectFromUserdata(__bridge ASMCanvasWindow, L, idx, USERDATA_TAG) ;
    } else {
        [skin logError:[NSString stringWithFormat:@"expected %s object, found %s", USERDATA_TAG,
                                                   lua_typename(L, lua_type(L, idx))]] ;
    }
    return value ;
}

#pragma mark - Hammerspoon/Lua Infrastructure

static int userdata_tostring(lua_State* L) {
    LuaSkin *skin = [LuaSkin shared] ;
    ASMCanvasWindow *obj = [skin luaObjectAtIndex:1 toClass:"ASMCanvasWindow"] ;
    NSString *title = NSStringFromRect(RectWithFlippedYCoordinate(obj.frame)) ;
    [skin pushNSObject:[NSString stringWithFormat:@"%s: %@ (%p)", USERDATA_TAG, title, lua_topointer(L, 1)]] ;
    return 1 ;
}

static int userdata_eq(lua_State* L) {
// can't get here if at least one of us isn't a userdata type, and we only care if both types are ours,
// so use luaL_testudata before the macro causes a lua error
    if (luaL_testudata(L, 1, USERDATA_TAG) && luaL_testudata(L, 2, USERDATA_TAG)) {
        LuaSkin *skin = [LuaSkin shared] ;
        ASMCanvasWindow *obj1 = [skin luaObjectAtIndex:1 toClass:"ASMCanvasWindow"] ;
        ASMCanvasWindow *obj2 = [skin luaObjectAtIndex:2 toClass:"ASMCanvasWindow"] ;
        lua_pushboolean(L, [obj1 isEqualTo:obj2]) ;
    } else {
        lua_pushboolean(L, NO) ;
    }
    return 1 ;
}

static int userdata_gc(lua_State* L) {
    LuaSkin *skin = [LuaSkin shared] ;
    ASMCanvasWindow *obj = get_objectFromUserdata(__bridge_transfer ASMCanvasWindow, L, 1, USERDATA_TAG) ;
    if (obj) {
        if (obj.contentView) {
            ASMCanvasView *theView   = (ASMCanvasView *)obj.contentView ;
            for (NSMutableDictionary *element in theView.elementList) {
                if ([element[@"type"] isEqualToString:@"canvas"]) {
                    ASMCanvasWindow *ourSubview = element[@"canvas"] ;
                    if (ourSubview && ![ourSubview isKindOfClass:[NSNull class]]) {
                        [ourSubview.contentView removeFromSuperview] ;
                        lua_pushcfunction(L, userdata_gc) ;
                        [skin pushNSObject:ourSubview] ;
                        [element removeObjectForKey:@"canvas"] ;
                        if (lua_pcall(L, 1, 0, 0) != LUA_OK) {
                            [LuaSkin logWarn:[NSString stringWithFormat:@"error releasing canvas subview: %s", lua_tostring(L, -1)]] ;
                            lua_pop(L, 1) ;
                        }
                    }
                }
            }
            theView.mouseCallbackRef = [skin luaUnref:refTable ref:theView.mouseCallbackRef] ;
        }
        [obj close];
        obj.selfRef = [skin luaUnref:refTable ref:obj.selfRef] ;
        obj = nil ;
    }

    // Remove the Metatable so future use of the variable in Lua won't think its valid
    lua_pushnil(L) ;
    lua_setmetatable(L, 1) ;
    return 0 ;
}

// static int meta_gc(lua_State* __unused L) {
//     return 0 ;
// }

// // Metatable for userdata objects
static const luaL_Reg userdata_metaLib[] = {
// affects drawing elements
    {"assignElement",       canvas_assignElementAtIndex},
    {"canvasElements",      canvas_canvasElements},
    {"canvasDefaults",      canvas_canvasDefaults},
    {"canvasMouseEvents",   canvas_canvasMouseEvents},
    {"canvasDefaultKeys",   canvas_canvasDefaultKeys},
    {"canvasDefaultFor",    canvas_canvasDefaultFor},
    {"elementAttribute",    canvas_elementAttributeAtIndex},
    {"elementBounds",       canvas_elementBoundsAtIndex},
    {"elementCount",        canvas_elementCount},
    {"elementKeys",         canvas_elementKeysAtIndex},
    {"imageFromCanvas",     canvas_canvasAsImage},
    {"insertElement",       canvas_insertElementAtIndex},
    {"removeElement",       canvas_removeElementAtIndex},
// affects whole canvas
    {"alpha",               canvas_alpha},
    {"behavior",            canvas_behavior},
    {"clickActivating",     canvas_clickActivating},
    {"delete",              canvas_delete},
    {"hide",                canvas_hide},
    {"isOccluded",          canvas_isOccluded},
    {"isShowing",           canvas_isShowing},
    {"level",               canvas_level},
    {"mouseCallback",       canvas_mouseCallback},
    {"orderAbove",          canvas_orderAbove},
    {"orderBelow",          canvas_orderBelow},
    {"show",                canvas_show},
    {"size",                canvas_size},
    {"topLeft",             canvas_topLeft},
    {"transformation",      canvas_canvasTransformation},
    {"wantsLayer",          canvas_wantsLayer},

    {"__tostring",          userdata_tostring},
    {"__eq",                userdata_eq},
    {"__gc",                userdata_gc},
    {NULL,                  NULL}
};

// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
    {"new",         canvas_new},
    {"elementSpec", dumpLanguageDictionary},

    {NULL,          NULL}
};

int luaopen_hs__asm_canvas_internal(lua_State* L) {
    LuaSkin *skin = [LuaSkin shared] ;
    refTable = [skin registerLibraryWithObject:USERDATA_TAG
                                     functions:moduleLib
                                 metaFunctions:nil    // or module_metaLib
                               objectFunctions:userdata_metaLib];

    languageDictionary = defineLanguageDictionary() ;

    [skin registerPushNSHelper:pushASMCanvasWindow         forClass:"ASMCanvasWindow"];
    [skin registerLuaObjectHelper:toASMCanvasWindowFromLua forClass:"ASMCanvasWindow"
                                                withUserdataMapping:USERDATA_TAG];

    pushCompositeTypes(L) ; lua_setfield(L, -2, "compositeTypes") ;

    return 1;
}
