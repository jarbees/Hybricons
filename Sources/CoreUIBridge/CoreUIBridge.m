#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "CoreUIBridge.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation CUICatalogFacade

- (instancetype _Nullable)initWithURL:(NSURL * _Nullable)url
                                error:(NSError * _Nullable * _Nullable)error {
    Class catalogClass = NSClassFromString(@"CUICatalog");

    CUICatalogFacade *catalog = (CUICatalogFacade *)[catalogClass alloc];

    return [catalog initWithURL:url error:error];
}

@end

#pragma clang diagnostic pop
