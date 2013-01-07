#import "GPUImageFilter.h"

extern NSString *const kGPUImageSelectiveColorFragmentShaderString;

@interface GPUImageSelectiveColorFilter : GPUImageFilter{
    CGFloat hueCenterUniform;
}
@property(nonatomic, readwrite) CGFloat hueCenter;
@end
