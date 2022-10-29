/**
 * This file was written by some friends in our development groups.
 */

#version 150

#moj_import <fog.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;
uniform float GameTime;

in float vertexDistance;
in vec4 vertexColor;
in vec2 texCoord0;

out vec4 fragColor;
const vec2 textureSize = vec2(256, 256);
const vec2 oneTexel = 1./textureSize;

#define SHADOW 0.248

#define ONE_MINUS_EPS 0.999

ivec3 getData(int x, int y) {
    return ivec3(texture(Sampler0, vec2(1) - vec2(x, y) * oneTexel).rgb * 255.);
}

void main() {
    ivec3 data0 = getData(1, 1);

    vec2 frameSize = vec2(data0.xy);
    bool isAnimated = data0.z == 253;

    // Position to read texture at
    vec2 uv = texCoord0;

    if (isAnimated) {
        vec2 texelFrame = frameSize * oneTexel;
        
        ivec3 data1 = getData(2, 1);

        float frameDuration = float(data1.x) * 0.1;
        float frameCount = float(data1.y);
        bool showShadow = bool(data1.z & 1);

        // Remove shadows following dragonmaster's method
        if (!showShadow && all(lessThan(
            vertexColor.rgb, 
            vec3(SHADOW)
        ))) {
            discard;
        }

        // Scale down uv to be on first frame
        uv *= texelFrame;

        /* Squish uv to fit frame ratio.
         * The uv is moved to the top-left so that positioning can be corrected by
         * changing ascent or adding negative space afterwards.
         */
        float tfRatio = texelFrame.y/texelFrame.x;
        if (tfRatio > 1.0) {
            uv.x *= tfRatio;
        } else {
            uv.y /= tfRatio;
        }

        // Check if uv ends up outside of current frame
        if (
            uv.x > texelFrame.x || uv.y > texelFrame.y
        ) {
            discard;
        }

        // Shift uv to correct frame
        float frameID = mod(floor(GameTime * 24000. / frameDuration), frameCount);
        vec2 offsetAmount = texelFrame * vec2(
            fract((frameID + ONE_MINUS_EPS) * texelFrame.x)/texelFrame.x - ONE_MINUS_EPS, 
            floor((frameID + ONE_MINUS_EPS) * texelFrame.x)
        );
        uv += offsetAmount;
    }

    // Continue to read texture as normal, but with potentially changed uv
    vec4 color = texture(Sampler0, uv) * vertexColor * ColorModulator;
    if (color.a < 0.1) {
        discard;
    }
    fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
}
