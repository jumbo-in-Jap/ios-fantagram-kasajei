#import "GPUImageSelectiveColorFilter.h"

@implementation GPUImageSelectiveColorFilter

NSString *const kGPUImageSelectiveColorFragmentShaderString = SHADER_STRING
(
 precision highp float;
 
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;

 
 void main()
 {
     // Sample the input pixel
     highp vec4 color   = texture2D(inputImageTexture, textureCoordinate);
     
     // RGB to HSV
     highp float r = color.r / 255.0;
     highp float g = color.g / 255.0;
     highp float b = color.b / 255.0;
     
     highp float max;
     highp float min;
     
     highp float H = 0.0;
     highp float S = 0.0;
     highp float V = 0.0;
     
     // max(r,g,b)
     if (r >= g) {
         max = r;
     } else {
         max = g;
     }
     if (b >= max) {
         max = b;
     }
     // min(r,g,b)
     if (r <= g) {
         min = r;
     } else {
         min = g;
     }
     if (b <= min) {
         min = b;
     }
     
     V = max;
     highp float C = max - min;
     
     if (max == 0.0){
         S = 0.0;
     } else {
         S = C / max;
     }
     if (S != 0.0) {
         if (r == max) {
             H = 60.0 * (g - b) / C;
         } else if (g == max) {
             H = 60.0 * (b - r) / C + 120.0;
         } else if (b == max) {
             H = 60.0 * (r - g) / C + 240.0;
         }
         if (H < 0.0) {
             H = H + 360.0;
         }
     }
     

     // フィルターここから --------------------------------------
     highp float center = 0.0;
     highp float variance = 15.0;
     
     
     if ( center > 180.0) {
         center = center - 360.0;
     }
     highp float storeS1;
     storeS1 = S * exp(-0.5 * (((H - center) / variance ) * ((H - center) / variance)) );
     highp float storeS2;
     storeS2 = S * exp(-0.5 * (((H - (360.0 + center) ) / variance ) * ((H -  (360.0 + center) ) / variance) ));
     
     S = max(storeS1, storeS2);
     S = S * 2.0;
     
     
     // --------------------------------------------------------
     
     // HSV to RGB
     if ( H >= 360.0 ){
         H = floor( H / 360.0 );
     }
     if ( H < 0.0 ){
         H = H + 360.0;
     }
     
     if ( S > 1.0 ){
         S = 1.0;
     }else if ( S < 0.0 ){
         S = 0.0;
     }
     
     if ( V > 1.0 ){
         V = 1.0;
     }else if ( V < 0.0 ){
         V = 0.0;
     }
     
     highp float inn = floor(H / 60.0);
     if(inn < 0.0) {
         inn *= -1.0;
     }
     highp float fl = (H / 60.0) - inn;
     if (inn == 2.0) {
         fl = 1.0 - fl;
     }
     
     highp float p = V * (1.0 - S);
     highp float q = V * (1.0 - S * fl);
     highp float t = V * (1.0 - (1.0 - fl) * S);
     
     ////計算結果のR,G,Bは0.0～1.0なので255倍
     V = V * 255.0;
     p = p * 255.0;
     q = q * 255.0;
     t = t * 255.0;
     
     if (inn == 0.0) {
         r = V; g = t; b = p;
     } else if(inn == 1.0) {
         r = q; g = V; b = p;
     } else if(inn == 2.0) {
         r = p; g = V; b = q;
     } else if(inn == 3.0) {
         r = p; g = q; b = V;
     } else if(inn == 4.0) {
         r = t; g = p; b = V;
     } else if(inn == 5.0) {
         r = V; g = p; b = q;
     }
     
     color.r = r ;
     color.g = g ;
     color.b = b ;
     
     // Save the result
     gl_FragColor = color;
     

 }
 );

#pragma mark -
#pragma mark Initialization and teardown

- (id)init;
{
    if (!(self = [super initWithFragmentShaderFromString:kGPUImageSelectiveColorFragmentShaderString]))
    {
		return nil;
    }
    
    return self;
}


@end
