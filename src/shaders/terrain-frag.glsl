#version 300 es
precision highp float;

uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane
uniform float u_SaltAmount;

in vec3 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_Col;
in vec4 fs_LightVec;

in float fs_Sine;
in float fs_Height;
in float fs_gradientScale;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.



float random1( vec2 p , vec2 seed) {
  return fract(sin(dot(p + seed, vec2(127.1, 311.7))) * 43758.5453);
}

float random1( vec3 p , vec3 seed) {
  return fract(sin(dot(p + seed, vec3(987.654, 123.456, 531.975))) * 85734.3545);
}

vec2 random2( vec2 p , vec2 seed) {
  return fract(sin(vec2(dot(p + seed, vec2(311.7, 127.1)), dot(p + seed, vec2(269.5, 183.3)))) * 85734.3545);
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

void main()
{
    float t = clamp(smoothstep(25.0, 55.0, length(fs_Pos)), 0.0, 1.0); // Distance fog
    // out_Col = vec4(mix(vec3(0.5 * (fs_Sine + 1.0)), vec3(164.0 / 255.0, 233.0 / 255.0, 1.0), t), 1.0);
        float heightNoise = pow(fbm(fs_Pos.x + u_PlanePos.x, fs_Pos.z + u_PlanePos.y, 1.0, 10.0, 10.0), 0.08);

        float redScale = 1.0 - clamp(pow(fbm(fs_Pos.x + u_PlanePos.x, fs_Pos.z + u_PlanePos.y, 0.6, 5.0, 5.0), 0.9), 0.2, 1.0);

        float greenScale = clamp(pow(fbm(fs_Pos.x + u_PlanePos.x, fs_Pos.z + u_PlanePos.y, 0.3, 0.1, 0.1), 0.4), 0.3, 0.8);
        float saltScale = 1.0 - clamp(pow(fbmWorley(fs_Pos.x + u_PlanePos.x, fs_Pos.z + u_PlanePos.y, 1.0, 0.005, 0.005), 10.0), 0.0, 1.0);

        float cracks = (1.0 - fs_gradientScale) * (1.0 - (0.75 * pow(1.0 - fbmWorley(fs_Pos.x + u_PlanePos.x, fs_Pos.z + u_PlanePos.y, 0.9, 0.03, 0.03), 0.03)
                + 0.25 * pow(1.0 - fbm(fs_Pos.x + u_PlanePos.x, fs_Pos.z + u_PlanePos.y, 1.0, 0.5, 0.5), 0.15)));

        float greenMap = clamp((1.3 - fs_gradientScale) * mix(heightNoise * mix(0.2, 0.9, 1.0 - 1.0/fs_Height) 
                         * pow(fbm(fs_Pos.x + u_PlanePos.x, fs_Pos.z + u_PlanePos.y, 2.0, 4.0, 4.0), 1.4), 0.0, 0.75), 0.0, 1.0);

        float saltMap = pow(saltScale * pow(fbm(fs_Pos.x + u_PlanePos.x, fs_Pos.z + u_PlanePos.y, 0.9, 5.0, 1.2), 2.0) * clamp((0.5 - fs_gradientScale) * mix(heightNoise * mix(0.0, 0.2, 1.0/fs_Height) 
                         * pow(fbm(fs_Pos.x + u_PlanePos.x, fs_Pos.z + u_PlanePos.y, 2.0, 4.0, 4.0), u_SaltAmount), 0.0, 0.5), 0.0, 1.0), 1.5);    


        // float greenScale = clamp(pow(fbm(fs_Pos.x + u_PlanePos.x, fs_Pos.z + u_PlanePos.y, 0.3, 0.1, 0.1), 0.4), 0.3, 0.8);

        vec4 redColor = (1.0 - redScale) * vec4(0.92, 0.33, 0.18, 1.0) + redScale * vec4(0.4, 0.14, 0.1, 1.0);
        redColor.y += 0.08 * (sin((fs_Height + fbm(fs_Pos.x + u_PlanePos.x, fs_Pos.z + u_PlanePos.y, 0.7, 1.5, 1.5)) * 45.0 )) * pow(fs_gradientScale, 2.2);
        redColor.x += 0.18 * (sin((fs_Height + fbm(fs_Pos.x + u_PlanePos.x, fs_Pos.z + u_PlanePos.y, 0.8, 1.5, 1.5)) * 80.0 )) * pow(fs_gradientScale, 2.2);
        redColor.z += 0.16 * (sin((fs_Height + fbm(fs_Pos.x + u_PlanePos.x, fs_Pos.z + u_PlanePos.y, 0.6, 1.5, 1.5)) * 65.0 )) * pow(fs_gradientScale, 2.2);

        vec4 cracksColor = vec4(0.0, 0.0, 0.0, 1.0);
        vec4 greenColor = vec4(42.0 / 255.0, 50.0 / 255.0, 35.0 / 255.0, 1.0);
        greenColor = (greenScale) * greenColor + 0.1 * greenScale * greenColor;

        vec4 saltColor = vec4(180.0 / 255.0, 210.0 / 255.0, 230.0 / 255.0, 1.0);
        saltColor = (saltScale) * saltColor + 0.1 * saltScale * saltColor;

        // vec4 diffuseColor = vec4(greenMap, greenMap, greenMap, 1.0);

        vec4 diffuseColor = (1.0 - saltMap) * ((1.0 - greenMap) * (((cracks * cracksColor) + (1.0 - cracks) * redColor)) + greenMap * greenColor) + saltMap * saltColor;
        diffuseColor.w = 1.0;
        // diffuseColor = vec4(saltMap, saltMap, saltMap, 1.0);

        // diffuseColor = redColor;
        // vec4 diffuseColor = vec4(0.0, fs_gradientScale, 0.0, 1.0);
        // vec4 diffuseColor = vec4(0.85 * red * cracks, green, 0.1, 1.0);

        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
        // diffuseTerm = clamp(diffuseTerm, 0, 1);

        float ambientTerm = 0.15;

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

        out_Col = vec4(mix(vec3(diffuseColor.rgb * lightIntensity), vec3(40.0 / 255.0, 10.0 / 255.0, 80.0 / 255.0), t), 1.0);
            // out_Col = vec4(mix(vec3(0.5 * (fs_Sine + 1.0)), vec3(164.0 / 255.0, 233.0 / 255.0, 1.0), t), 1.0);

        // out_Col = fs_Nor;
}
