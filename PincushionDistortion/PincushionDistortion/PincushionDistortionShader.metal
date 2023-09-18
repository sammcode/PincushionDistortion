//
//  PincushionDistortionShader.metal
//  PincushionDistortion
//
//  Created by Samuel McGarry on 9/17/23.
//

#include <metal_stdlib>
using namespace metal;

#include <SwiftUI/SwiftUI_Metal.h>

float mapRange(float value, float inMin, float inMax, float outMin, float outMax) {
    return ((value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin);
}

/// Calculates the `zoomOffset` using a damped sin wave function.
/// The `distanceProgress` represents the progress of the pixel's distance to the maximum possible distance (the radius of the distortion effect).
/// https://en.wikipedia.org/wiki/Damping#Damped_sine_wave
float zoomOffset(float distanceProgress) {
    // The constant for pi in the Metal shading language.
    float pi = M_PI_F;
    
    // The amplitude represents the maximum zoom offset.
    float amplitude = -0.5;
    
    // The decay indicates how quickly the dampening fades out on the sine wave.
    float decay = 10;
    
    // The angularFrequency (period) indicates the displacement of the sine wave for one period.
    float angularFrequency = 2 * pi;
    
    // Normally t would represent time, but in this case it represents how far the pixel is from the center of the distortion, normalized to the scale of the damped sine wave.
    // The maximum value we're allowing is a quarter of the total period, because we only care about the initial "drop" of the wave (otherwise we would get a ripple effect, with multiple "dips").
    float maxT = angularFrequency / 4;
    float t = distanceProgress * maxT;
    
    // Calculate the new zoomOffset
    float zoomOffset = ((amplitude * exp(-t * decay)) * sin(angularFrequency * t));
    
    return zoomOffset;
}

[[ stitchable ]] half4 pincushionDistortion(float2 position, SwiftUI::Layer layer, float4 bounds, float2 distortionCenter, float distortionSize) {
    // The overall size/resolution of the shader view's bounds
    float2 size = float2(bounds[2], bounds[3]);

    // Normalize `position` into unit coordinates (i.e. [0, 1])
    float2 p = position / size;
    float px = p[0];
    float py = p[1];

    // Sample the original color of the pixel
    half4 color = layer.sample(position);

    // Calculate how far the current pixel is from the distortion's center.
    float d = distance(distortionCenter, p);
    float r = distortionSize;
    float distanceProgress = d / r;

    if (d <= r) {
        // To create the pincushion distortion effect, we'll calculate the zoom offset using a damped sine wave function.
        float offset = zoomOffset(distanceProgress);
        
        // Kinda hacky, but keep the magnification radius constant even as the loupe's bounds change.
        r = 0.18;

        // Calculate the bounds of the loupe given its center and radius:
        float distortionMinX = distortionCenter[0] - r;
        float distortionMaxX = distortionCenter[0] + r;
        float distortionMinY = distortionCenter[1] - r;
        float distortionMaxY = distortionCenter[1] + r;

        // The pixels within the loupe need to sample across a smaller range from the underlying texture.
        // This is what gives that "magnification" effect.
        float zoomRangeMinX = distortionMinX + offset;
        float zoomRangeMaxX = distortionMaxX - offset;

        float zoomRangeMinY = distortionMinY + offset;
        float zoomRangeMaxY = distortionMaxY - offset;

        // Calculate the new coordinates to sample.
        // For example, when `px` == `loupeMinX`, it'll be converted to `zoomRangeMinX`.
        float zoomPosX = mapRange(px, distortionMinX, distortionMaxX, zoomRangeMinX, zoomRangeMaxX);
        float zoomPosY = mapRange(py, distortionMinY, distortionMaxY, zoomRangeMinY, zoomRangeMaxY);

        // un-normalize position back to user-space
        // We've been working with normalized unit values, but we need convert those values back to "user-space".
        // These values are considered "denormalized", and we can use them to sample the SwiftUI::Layer texture.
        float2 normalizedSamplePosition = float2(zoomPosX, zoomPosY);
        float2 denormalizedSamplePosition = float2(
            normalizedSamplePosition[0] * size[0],
            normalizedSamplePosition[1] * size[1]
        );

        // Finally, sample the layer with the new, "magnified" coordinate.
        color = layer.sample(denormalizedSamplePosition);
    }
    
    return color;
}
