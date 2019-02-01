#version 300 es
precision highp float;

// The fragment shader used to render the background of the scene
// Modify this to make your background more interesting

in vec4 fs_Pos;
uniform ivec2 u_Dimensions; // Screen dimensions
uniform mat4 u_ViewProj; // Should be the inverse of the view projection matrix
uniform vec3 u_CameraPos;


const float PI = 3.14159265359;
const float TWO_PI = 6.28318530718;

out vec4 out_Col;

  // vec4 color1 = vec4(40.0 / 255.0, 10.0 / 255.0, 80.0 / 255.0, 1.0);
  // vec4 color2 = vec4(190.0 / 245.0, 255.0 / 255.0, 255.0 / 255.0, 1.0);
// Sunset palette
const vec3 sunset[5] = vec3[](vec3(40, 10, 80) / 255.0,
                               vec3(80, 50, 120) / 255.0,
                               vec3(200, 170, 150) / 255.0,
                               vec3(160, 180, 220) / 255.0,
                               vec3(190, 255, 255) / 255.0);
// Dusk palette
const vec3 dusk[5] = vec3[](vec3(144, 96, 144) / 255.0,
                            vec3(96, 72, 120) / 255.0,
                            vec3(72, 48, 120) / 255.0,
                            vec3(48, 24, 96) / 255.0,
                            vec3(0, 24, 72) / 255.0);

const vec3 sunColor = vec3(255, 255, 190) / 255.0;
const vec3 cloudColor = sunset[3];





float random1( vec2 p , vec2 seed) {
  return fract(sin(dot(p + seed, vec2(127.1, 311.7))) * 43758.5453);
}

float random1( vec3 p , vec3 seed) {
  return fract(sin(dot(p + seed, vec3(987.654, 123.456, 531.975))) * 85734.3545);
}

vec2 random2( vec2 p , vec2 seed) {
  return fract(sin(vec2(dot(p + seed, vec2(311.7, 127.1)), dot(p + seed, vec2(269.5, 183.3)))) * 85734.3545);
}

vec3 random3( vec3 p ) {
    return fract(sin(vec3(dot(p,vec3(127.1, 311.7, 191.999)),
                          dot(p,vec3(269.5, 183.3, 765.54)),
                          dot(p, vec3(420.69, 631.2,109.21))))
                 *43758.5453);
}

float interpNoise2d(float x, float y) {
  float intX = floor(x);
  float fractX = fract(x);
  float intY = floor(y);
  float fractY = fract(y);

  float v1 = random1(vec2(intX, intY), vec2(1.f, 1.f));
  float v2 = random1(vec2(intX + 1.f, intY), vec2(1.f, 1.f));
  float v3 = random1(vec2(intX, intY + 1.f), vec2(1.f, 1.f));
  float v4 = random1(vec2(intX + 1.f, intY + 1.f), vec2(1.f, 1.f));

  float i1 = mix(v1, v2, fractX);
  float i2 = mix(v3, v4, fractX);
  return mix(i1, i2, fractY);
  return 2.0;

}

float computeWorley(float x, float y, float numRows, float numCols) {
    float xPos = x * float(numCols) / 20.f;
    float yPos = y * float(numRows) / 20.f;

    float minDist = 60.f;
    vec2 minVec = vec2(0.f, 0.f);

    for (int i = -1; i < 2; i++) {
        for (int j = -1; j < 2; j++) {
            vec2 currGrid = vec2(floor(float(xPos)) + float(i), floor(float(yPos)) + float(j));
            vec2 currNoise = currGrid + random2(currGrid, vec2(2.0, 1.0));
            float currDist = distance(vec2(xPos, yPos), currNoise);
            if (currDist <= minDist) {
                minDist = currDist;
                minVec = currNoise;
            }
        }
    }
    return minDist;
    // return 2.0;
}

float fbmWorley(float x, float y, float height, float xScale, float yScale) {
  float total = 0.f;
  float persistence = 0.5f;
  int octaves = 8;
  for (int i = 0; i < octaves; i++) {
    float freq = pow(2.0, float(i));
    float amp = pow(persistence, float(i));
    // total += interpNoise2d( (x / xScale) * freq, (y / yScale) * freq) * amp;
    total += computeWorley( (x / xScale) * freq, (y / yScale) * freq, 2.0, 2.0) * amp;
  }
  return height * total;
}

float fbm(float x, float y, float height, float xScale, float yScale) {
  float total = 0.f;
  float persistence = 0.5f;
  int octaves = 8;
  for (int i = 0; i < octaves; i++) {
    float freq = pow(2.0, float(i));
    float amp = pow(persistence, float(i));
    // total += interpNoise2d( (x / xScale) * freq, (y / yScale) * freq) * amp;
    total += interpNoise2d( (x / xScale) * freq, (y / yScale) * freq) * amp;
  }
  return height * total;
}


vec2 sphereToUV(vec3 p) {
    float phi = atan(p.z, p.x);
    if(phi < 0.0) {
        phi += TWO_PI;
    }
    float theta = acos(p.y);
    return vec2(1.0 - phi / TWO_PI, 1.0 - theta / PI);
}


vec3 uvToSunset(vec2 uv) {
    if(uv.y < 0.45) {
        return sunset[0];
    }
    else if(uv.y < 0.5) {
        return mix(sunset[0], sunset[1], (uv.y - 0.45) / 0.05);
    }
    else if(uv.y < 0.55) {
        return mix(sunset[1], sunset[2], (uv.y - 0.5) / 0.05);
    }
    else if(uv.y < 0.6) {
        return mix(sunset[2], sunset[3], (uv.y - 0.55) / 0.05);
    }
    else if(uv.y < 0.7) {
        return mix(sunset[3], sunset[4], (uv.y - 0.6) / 0.1);
    }
    return sunset[4];
}

vec3 uvToDusk(vec2 uv) {
    if(uv.y < 0.5) {
        return dusk[0];
    }
    else if(uv.y < 0.55) {
        return mix(dusk[0], dusk[1], (uv.y - 0.5) / 0.05);
    }
    else if(uv.y < 0.6) {
        return mix(dusk[1], dusk[2], (uv.y - 0.55) / 0.05);
    }
    else if(uv.y < 0.65) {
        return mix(dusk[2], dusk[3], (uv.y - 0.6) / 0.05);
    }
    else if(uv.y < 0.75) {
        return mix(dusk[3], dusk[4], (uv.y - 0.65) / 0.1);
    }
    return dusk[4];
}

float WorleyNoise3D(vec3 p)
{
    // Tile the space
    vec3 pointInt = floor(p);
    vec3 pointFract = fract(p);

    float minDist = 1.0; // Minimum distance initialized to max.

    // Search all neighboring cells and this cell for their point
    for(int z = -1; z <= 1; z++)
    {
        for(int y = -1; y <= 1; y++)
        {
            for(int x = -1; x <= 1; x++)
            {
                vec3 neighbor = vec3(float(x), float(y), float(z));

                // Random point inside current neighboring cell
                vec3 point = random3(pointInt + neighbor);

    //             // Animate the point
    //             point = 0.5 + 0.5 * sin(u_Time * 0.01 + 6.2831 * point); // 0 to 1 range

                // Compute the distance b/t the point and the fragment
                // Store the min dist thus far
                vec3 diff = neighbor + point - pointFract;
                float dist = length(diff);
                minDist = min(minDist, dist);
            }
        }
    }
    return minDist;
}

float worleyFBM3D(vec3 uv) {
    float sum = 0.0;
    float freq = 4.0;
    float amp = 0.5;
    for(int i = 0; i < 8; i++) {
        sum += WorleyNoise3D(uv * freq) * amp;
        freq *= 2.0;
        amp *= 0.5;
    }
    return sum;
}



void main() {

  // vec4 color1 = vec4(40.0 / 255.0, 10.0 / 255.0, 80.0 / 255.0, 1.0);
  // vec4 color2 = vec4(190.0 / 245.0, 255.0 / 255.0, 255.0 / 255.0, 1.0);

  // float x = 0.5 * (fs_Pos.x + 1.0);
  // float y = 0.3 * (fs_Pos.y + 1.0);
  float x = fs_Pos.x;
  float y = fs_Pos.y;

  // float scale = 0.8 * ((0.3 *fbm(x + 0.5, y, 0.6, 1.8, 2.0)) + 0.8);
  // float t = 0.5 * (fs_Pos.y + 1.0);
  // t = smoothstep(scale, 1.0, t);

  

  // vec2 moonCenter = vec2(0.7, 0.48);

  // vec4 skyColor = mix(color1, color2, t);

  vec4 moonColor = vec4(0.97, 0.99, 1.13, 1.0);
  vec4 moonMid = vec4(0.52, 0.55, 0.6, 1.0);
  vec4 moonDark = vec4(0.12, 0.15, 0.17, 1.0);
  float moonMidMap = 0.9 * pow(fbmWorley(x, y, 0.8, 0.01, 0.008), 0.4);
  float darkMapWorley = 0.6 * (1.0 - computeWorley(x + fbm(x, y, 0.1, 0.1, 0.1), y + fbm(x, y, 0.1, 0.1, 0.1), 165.0, 140.0));
  darkMapWorley *= (1.4 - abs(smoothstep(0.0, 1.0, darkMapWorley) - 0.5));
  // float darkMapWorley = 0.7 * floor((1.0 - computeWorley(x + fbm(x, y, 0.1, 0.1, 0.1), y + fbm(x, y, 0.1, 0.1, 0.1), 130.0, 140.0)) * 3.0) / 3.0;
  // darkMapWorley += 0.2 * floor((1.0 - computeWorley(x + fbm(x, y, 0.1, 0.1, 0.1), y + fbm(x, y, 0.1, 0.07, 0.07), 130.0, 140.0)) * 2.0) / 2.0;
  float moonDarkMap = smoothstep(0.2, 1.0, darkMapWorley) + pow((fbmWorley(x, y, 0.5, 0.01, 0.01)), 2.0);
  moonDarkMap += pow(1.0 - fbmWorley(x, y, 0.5, 0.01, 0.01), 2.0) - fbmWorley(x, y, 0.7, 0.09, 0.09);

  moonColor = (1.0 - moonDarkMap) * (moonMidMap * moonColor + (1.0 - moonMidMap) * moonMid) + moonDarkMap * moonDark;



  // vec2 ndc = (gl_FragCoord.xy / vec2(u_Dimensions)) * 2.0 - 1.0; // -1 to 1 NDC
  vec2 ndc = vec2(x, y * 4.0 - 2.0); // -1 to 1 NDC
  vec2 ndcNonTransformed = vec2(x, y); // -1 to 1 NDC


  vec4 p = vec4(ndc.xy, 1, 1); // Pixel at the far clip plane
  vec4 pNonTransformed = vec4(ndcNonTransformed.xy, 1, 1); // Pixel at the far clip plane

  p *= 1000.0; // Times far clip plane value
  p = /*Inverse of*/ u_ViewProj * p; // Convert from unhomogenized screen to world

  pNonTransformed *= 1000.0; // Times far clip plane value
  pNonTransformed = /*Inverse of*/ u_ViewProj * pNonTransformed; // Convert from unhomogenized screen to world

  vec3 rayDir = normalize(p.xyz - u_CameraPos);
  vec2 uv = sphereToUV(rayDir);

  vec3 rayDirNonTransformed = normalize(pNonTransformed.xyz - u_CameraPos);
  vec2 uvNonTransformed = sphereToUV(rayDirNonTransformed);


  vec2 worleySlope = vec2(worleyFBM3D(rayDir * 1.0));
  worleySlope *= 2.0;
  worleySlope -= vec2(1.0);

  vec3 sunsetColor = uvToSunset(uv + worleySlope * 0.1);
  vec3 duskColor = uvToDusk(uv + worleySlope * 0.1);

  vec3 sunDir = normalize(vec3(0.0, -0.142, 1.0));
  float sunSize = 31.0;
  float angle = acos(dot(rayDirNonTransformed, sunDir)) * 360.0 / PI;

  out_Col = 0.9 * vec4(sunsetColor, 1.0);
  out_Col += 0.1 * mix(moonColor, vec4(sunsetColor, 1.0), (angle - 5.0) / 10.0);


  if(angle < sunSize) {
    if(angle < 31.0) {
        float moonScale = mix(0.3, 2.2, 1.0 - 0.5 * (fs_Pos.y + 1.0));
        out_Col = moonScale * vec4(sunsetColor, 1.0) + (1.3 - moonScale) * moonColor;
    }
    // else {
    //     out_Col = mix(moonColor, vec4(sunsetColor, 1.0), (angle - 5.0) / 10.0);
    // }
  }

  // out_Col = skyColor;

  // if (length(vec2(x, y) - moonCenter) < 0.1) {
  //   out_Col = moonColor;
  // }

  // out_Col = vec4(float(u_Dimensions.x), float(u_Dimensions.y), 1.0, 1.0);
  // out_Col = vec4(1000.0 * u_CameraPos, 1.0);


  // out_Col = vec4(y, y, y, 1.0);

  // float heightScale = pow(fs_Pos.y, 7.5);



  // out_Col = heightScale * color2 + (1.0 - heightScale) * color1;
}
