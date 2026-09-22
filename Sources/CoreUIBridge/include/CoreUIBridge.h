#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

// Nullability is conservative because CoreUI is private API.

@class CUINamedMultisizeImageFacade;

@interface CUICatalogFacade : NSObject

- (instancetype _Nullable)initWithURL:(NSURL * _Nullable)url
                                error:(NSError * _Nullable * _Nullable)error;

- (CUINamedMultisizeImageFacade * _Nullable)
    iconImageWithName:(NSString * _Nullable)name
          scaleFactor:(double)scaleFactor
          deviceIdiom:(NSInteger)deviceIdiom
        deviceSubtype:(NSInteger)deviceSubtype
         displayGamut:(NSInteger)displayGamut
      layoutDirection:(NSInteger)layoutDirection
  sizeClassHorizontal:(NSInteger)sizeClassHorizontal
    sizeClassVertical:(NSInteger)sizeClassVertical
          desiredSize:(CGSize)desiredSize
       appearanceName:(NSString * _Nullable)appearanceName;

@end

@interface CUINamedMultisizeImageFacade : NSObject

- (CGImageRef _Nullable)image CF_RETURNS_NOT_RETAINED;

@end
