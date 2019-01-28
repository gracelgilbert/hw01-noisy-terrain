#version 300 es


uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj;
uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane

in vec4 vs_Pos;
in vec4 vs_Nor;
in vec4 vs_Col;

out vec3 fs_Pos;
out vec4 fs_Nor;
out vec4 fs_Col;
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.

out float fs_Sine;
out float fs_Height;
out float fs_gradientScale;

const vec4 lightPos = vec4(15, 15, -8, 1); //The position of our virtual light, which is used to compute the shading of


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
            vec2 currNoise = currGrid + random2(currGrid, vec2(2.18, 2.1));
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





float getHeight(vec4 pos) {
    float height = 0.0;
    float maxHeightValue = 1.9 * computeWorley(pos.x + u_PlanePos.x, pos.z + u_PlanePos.y, 1.0, 1.0);
    height += 3.0 * clamp(pow(fbmWorley((pos.x + u_PlanePos.x), (pos.z + u_PlanePos.y), 1.f, 2.8f, 2.8f), 5.7), 0.0, maxHeightValue);
    height +=  pow(fbm((pos.x + u_PlanePos.x), (pos.z + u_PlanePos.y), 0.75f, 10.0f, 10.0f), 8.5);
    // height += 3.0 * clamp(pow(fbmWorley((pos.x + u_PlanePos.x), (pos.z + u_PlanePos.y), 1.f, 60.0f, 60.0f), 5.7), 0.0, 3.0 * maxHeightValue);
    return height;
    // float x = fbmWorley((pos.x + u_PlanePos.x), (pos.z + u_PlanePos.y), 1.f, 2.8f, 2.8f);
    // return 2.0 * (pow(x - 0.8, 1.0/3.0) + 0.99);

  // return 0.5 * ((1.f - pow(fbm((pos.x + u_PlanePos.x), (pos.z + u_PlanePos.y), 1.f, 3.f, 3.f), 10.0)) + 
  //              pow(fbm((pos.x + u_PlanePos.x), (pos.z + u_PlanePos.y), 1.f, 8.f, 8.f), 8.0));
  // return 5.0 * computeWorley(pos.x + u_PlanePos.x, pos.z + u_PlanePos.y, 3.0, 3.0);
}

void main()
{
  fs_Pos = vs_Pos.xyz;
  // fs_Sine = (sin((vs_Pos.x + u_PlanePos.x) * 3.14159 * 0.1) + cos((vs_Pos.z + u_PlanePos.y) * 3.14159 * 0.1));

  float epsilon = 0.0001;    
    // newTime = u_Time;
    vec4 posxP = vs_Pos + vec4(epsilon, 0.0, 0.0, 0.0);
    vec4 posxN = vs_Pos - vec4(epsilon, 0.0, 0.0, 0.0);

    vec4 poszP = vs_Pos + vec4(0.0, 0.0, epsilon, 0.0);
    vec4 poszN = vs_Pos - vec4(0.0, 0.0, epsilon, 0.0);

    vec4 modelposition = vec4(vs_Pos.x, getHeight(vs_Pos), vs_Pos.z, 1.0);
    fs_Height = getHeight(vs_Pos);

    float right = getHeight(posxP);
    float left = getHeight(posxN);
    float up = getHeight(poszP);
    float down = getHeight(poszN);

    float nor1 = 0.5 * (right - left);
    float nor2 = 1.0;
    float nor3 = 0.5 * (down - up);

    float dx = left - fs_Height;
    float dy = up - fs_Height;
    fs_gradientScale = 500.0 * pow(dx * dx + dy * dy, 0.4);

    fs_Nor = vec4(nor1, nor2, nor3, 0.f);

  fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies
  // fs_Nor = vec4(1.0, 0.0, 0.0, 1.0);
  
  gl_Position = u_ViewProj * modelposition;
}
