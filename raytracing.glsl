//#version 300 es
#ifdef DEBUG
precision highp float;
out vec4 frag_color;

uniform vec4 iMouse;
uniform vec3 iResolution;
uniform float iTime;
uniform float iTimeDelta;
uniform int iFrame;
uniform float iFrameRate;

#endif

// random numbers utilities from https://www.shadertoy.com/view/tsf3Dn
#define MIN -2147483648
#define MAX 2147483647

int xorshift(in int value) {
    // Xorshift*32
    // Based on George Marsaglia's work: http://www.jstatsoft.org/v08/i14/paper
    value ^= value << 13;
    value ^= value >> 17;
    value ^= value << 5;
    return value;
}

int nextInt(in int seed) {
    return xorshift(seed);
}

float nextFloat(inout int seed) {
    seed = xorshift(seed);
    // FIXME: This should have been a seed mapped from MIN..MAX to 0..1 instead
    return abs(fract(float(seed) / 3141.592653));
}

float nextFloat(inout int seed, in float max) {
    return nextFloat(seed) * max;
}

float random(inout int rngSeed)
{
    return nextFloat(rngSeed);
}

float random(inout int seed, float minValue, float maxValue)
{
    return minValue + (maxValue-minValue)*random(seed);
}

int randomSeed;
float random()
{
    return nextFloat(randomSeed);
}
float random(float minValue, float maxValue)
{
    return minValue + (maxValue-minValue)*random(randomSeed);
}


//==================================================================


// vec4 vec3 shape position + index properties
// properties
struct Item
{
    vec4 position;
    vec4 material; // xyz color
                   // w > 1 = glass (ior)
                   // w < 0.5 = metal (roughness)
                   // w = 0 = lambert
};

struct Camera
{
    vec3 position;
    vec3 lookAt;
    vec3 u;
    vec3 v;
    vec3 w;
    vec3 vecX;
    vec3 vecY;
    float lensRadius;
};

#define MaterialLambert 0.0
#define MaterialMetal 0.5
#define MaterialDielectric 1.0

#define MaxElements 150
struct Scene
{
    Item items[MaxElements];
    int numItems;

} gScene;

struct Ray {
    vec3 origin;
    vec3 direction;
};

struct Hit {
    Item item;
    vec3 position;
    vec3 normal;
    float t;
    bool frontFace;
};

vec3 rayAt(const Ray ray, const float t) {
    return ray.origin + t * ray.direction;
}

vec3 randomUnitSphere() {
    vec3 p = vec3(
        random(-1.0,1.0),
        random(-1.0,1.0),
        random(-1.0,1.0));
    float l = dot(p,p);
    if ( l <= 1.0) {
        return p;
    }
    return p*(1.0/l);
}

vec3 randomUnitDisk() {
    vec3 p = vec3(random(-1.0,1.0), random(-1.0,1.0), 0.0);
    float l = dot(p,p);
    if ( l <= 1.0) {
        return p;
    }
    return p*(1.0/l);
}

vec3 rayBackgroundColor(const Ray r) {
    const vec3 sky = vec3(0.5, 0.7, 1.0);
    const vec3 ground = vec3(1.0, 1.0, 1.0);
    float t = 0.5*(r.direction.y + 1.0);
    return mix(ground, sky, t);
}

bool intersectSphere(const Ray ray, const float t_min, const float t_max, const Item item, inout Hit hit) {
    vec4 sphere = item.position;
    vec3 oc = ray.origin - sphere.xyz;
    float a = dot(ray.direction, ray.direction);
    float b = 2.0 * dot(oc, ray.direction);
    float c = dot(oc, oc) - sphere.w*sphere.w;
    float discriminant = b*b - 4.0*a*c;
    if (discriminant < 0.0) {
        return false;
    }

    float sqrtd = sqrt(discriminant);

    float root = (-b - sqrtd ) / (2.0*a);
    if ( root < t_min || t_max < root ) {
        root = (-b + sqrtd ) / (2.0*a);
        if (root < t_min || t_max < root)
            return false;
    }

    hit.t = root;
    hit.position = rayAt(ray, hit.t);
    hit.normal = (hit.position - sphere.xyz) / sphere.w;

    bool front_face = dot(ray.direction, hit.normal) < 0.0;
    hit.normal = front_face ? hit.normal :-hit.normal;
    hit.frontFace = front_face;
    return true;
}

bool intersectWorld(const Ray ray, float min_t, float max_t, out Hit hit)
{
    int i;
    bool rayHit = false;
    for ( i = 0 ; i < gScene.numItems; i++) {
        bool intersect = intersectSphere(ray, min_t, max_t, gScene.items[i], hit);
        if (intersect) {
            hit.item = gScene.items[i];
            max_t = hit.t;
            rayHit = true;
        }
    }

    return rayHit;
}

// Lambert material scattering
float scatterLambert(const Ray ray, const Hit hit, out vec3 attenuation, out Ray scattered) {
    vec3 direction = hit.normal + randomUnitSphere();
    float l = dot(direction, direction);
    if ( l < 1e-8) {
        scattered.direction = hit.normal;
    } else {
        scattered.direction = direction * (1.0/sqrt(l));
    }
    scattered.origin = hit.position;
    attenuation = hit.item.material.xyz;
    return 1.0;
}

// Metal material scattering
float scatterMetal(const Ray ray, const Hit hit, out vec3 attenuation, out Ray scattered) {
    float roughness = hit.item.material.w;
    vec3 reflected = reflect(normalize(ray.direction), hit.normal) + roughness * randomUnitSphere();
    scattered.direction = normalize(reflected);
    scattered.origin = hit.position;
    attenuation = hit.item.material.xyz;
    return (dot(scattered.direction, hit.normal) > 0.0 ? 1.0 : 0.0);
}

// Schlick reflectance
float schlickReflectance(const float cosine, const float refractionRatio) {
    // Use Schlick's approximation for reflectance.
    float r0 = (1.0-refractionRatio) / (1.0+refractionRatio);
    r0 = r0*r0;
    return r0 + (1.0-r0)*pow((1.0 - cosine),5.0);
}

// Dielectric material scattering
float scatterDieletric(const Ray ray, const Hit hit, out vec3 attenuation, out Ray scattered) {
    float ior = hit.item.material.w;
    attenuation = vec3(1.0);
    float refractionRatio = hit.frontFace ? (1.0/ior) : ior;

    vec3 direction = normalize(ray.direction);
    vec3 refracted = refract(direction, hit.normal, refractionRatio);

    float cosTheta = min(dot(-direction, hit.normal), 1.0);
    float sinTheta = sqrt(1.0 - cosTheta*cosTheta);

    bool cannotRefract = refractionRatio * sinTheta > 1.0;

    if (cannotRefract || schlickReflectance(cosTheta, refractionRatio) > random(0.0, 1.0) )
        direction = reflect(direction, hit.normal);
    else
        direction = refract(direction, hit.normal, refractionRatio);


    scattered = Ray(hit.position, direction);
    return 1.0;
}

float rayInner(const Ray ray, out Ray nextRay, inout vec3 color)
{
    Hit hit;
    if (intersectWorld(ray, 0.001, 1e8, hit)) {

        float result;
        vec3 attenuation;
        float type = hit.item.material.w;
        if (type < MaterialLambert+0.001) {
            result = scatterLambert(ray, hit, attenuation, nextRay);
        } else if (type <= MaterialMetal) {
            result = scatterMetal(ray, hit, attenuation, nextRay);
        } else {
            // MaterialDielectric
            result = scatterDieletric(ray, hit, attenuation, nextRay);
        }
        color *= result * attenuation;
        return result;
    }

    color *= rayBackgroundColor(ray);
    return 0.0;
}

vec3 rayColor(const Ray ray)
{
    vec3 color = vec3(1.0);
    const int maxNumRay = 10;
    int i = 0;
    Ray currentRay = ray;
    for (i = 0; i < maxNumRay; i++) {
        Ray nextRay;
        float hit = rayInner(currentRay, nextRay, color);
        if (hit == 0.0) {
            break;
        }
        currentRay = nextRay;
    }

    if (i==maxNumRay) {
        return vec3(0.0);
    }

    return color;
}

void setupScene(out Scene scene)
{
    int itemIndex = 0;
    int seed = 10;

    scene.items[itemIndex].position = vec4(0.0,-1000,-1.0, 1000.0);
    scene.items[itemIndex].material = vec4(0.5,0.5,0.5, MaterialLambert);
    itemIndex++;

    int a,b;
    for (a = -11; a < 11; a+=2) {
        for (b = -11; b < 11; b+=2) {
            float random0 = random(seed);
            float random1 = random(seed);
            float random2 = random(seed);

            vec3 center = vec3(float(a) + 0.9*random0, 0.2, float(b) + 0.9*random1);

            if ( length(center - vec3(4, 0.2, 0)) > 0.9) {

                scene.items[itemIndex].position = vec4(center.xyz, 0.2);
                if (random0 < 0.8) {
                    // diffuse
                    vec3 albedo = vec3(random0*random0, random1*random1, random2*random2);
                    //scene.items[itemIndex].material = vec4(random(seed)*random(seed), random(seed)*random(seed), random(seed)*random(seed), MaterialLambert);
                    scene.items[itemIndex].material = vec4(albedo.xyz, MaterialLambert);
                } else if (random0 < 0.95) {
                    // metal
                    vec3 albedo = vec3(random0*0.5+0.5, random1*0.5+0.5, random2*0.5+0.5);
                    //scene.items[itemIndex].material = vec4(random(seed, 0.5, 1.0), random(seed, 0.5, 1.0), random(seed, 0.5, 1.0), random(seed,0.01, 0.5));
                    scene.items[itemIndex].material = vec4(albedo.xyz, random1*0.49 + 0.01);
                } else {
                   // glass
                    scene.items[itemIndex].material = vec4(1.5);
                }
                itemIndex++;
            }
        }
    }
    
    scene.items[itemIndex].position = vec4(0.0, 1.0, 0.0, 1.0);
    scene.items[itemIndex].material = vec4(1.5);
    itemIndex++;

    scene.items[itemIndex].position = vec4(-4.0, 1.0, 0.0, 1.0);
    scene.items[itemIndex].material = vec4(0.4, 0.2, 0.1, 0.0);
    itemIndex++;

    scene.items[itemIndex].position = vec4(4.0, 1.0, 0.0, 1.0);
    scene.items[itemIndex].material = vec4(0.7, 0.6, 0.5, 0.001);
    itemIndex++;
    
    scene.numItems = itemIndex;
}

Ray getCameraRay(const vec2 sampleOffset, const in Camera camera)
{
    vec4 fragCoord = gl_FragCoord;

    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (fragCoord.xy+sampleOffset)/iResolution.xy;

    // compute offset with disk to generate the blur
    vec3 rd = camera.lensRadius * randomUnitDisk();
    vec3 diskOffset = camera.u * rd.x + camera.v * rd.y;
    
    vec3 startPosition =  -camera.vecX*0.5 - camera.vecY*0.5 - camera.w;
    vec3 pixel = camera.vecX*uv.x + camera.vecY*uv.y;

    Ray ray;
    ray.origin=camera.position + diskOffset;
    ray.direction=normalize(startPosition + pixel - diskOffset);
    return ray;
}

Camera computeCameraLookAt(const vec3 eye, const vec3 target, const float aspectRatio, const float fovy, const float aperture, const float focusDist)
{
    const vec3 vup = vec3(0.0, 1.0, 0.0);
    
    Camera camera;
    float h = tan(radians(fovy)/2.0);
    float height = h * 2.0;
    float width = height * aspectRatio;

    camera.position = eye;
    
    vec3 w = normalize(eye-target);
    vec3 u = cross(vup, w);
    vec3 v = cross(w, u);

    camera.u = u;
    camera.v = v;
    camera.w = w * focusDist;
    camera.vecX = camera.u * width * focusDist;
    camera.vecY = camera.v * height * focusDist;
    
    camera.lensRadius = aperture/2.0;
    return camera;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    randomSeed = int(fragCoord.x) + int(fragCoord.y) * int(iResolution.x);
    setupScene(gScene);

//    const float aperture = 2.0;
//    const vec3 eye = vec3(3.0, 3.0, 2.0);
//    const vec3 target = vec3(0.0,0.0,-1.0);
//    const float distToFocus = length(eye-target);
    const vec3 eye = vec3(13.0,2.0,3.0);
    const vec3 target = vec3(0.0,0.0,0.0);
    const float distToFocus = 10.0;
    const float aperture = 0.1;
    
    float fovy =  20.0;  // + 100.0 * iMouse.y/iResolution.y;
    
    Camera camera = computeCameraLookAt(eye, target, iResolution.x/iResolution.y, fovy, aperture, distToFocus);

    const int numSamples = 10;
    const float invNumSamples = 1.0/float(numSamples);
    int i;
    vec3 col= vec3(0.0);
    for (i = 0; i < numSamples; i++) {
        vec2 offset = vec2(random(),random());
        Ray ray = getCameraRay(offset, camera);
        col += rayColor(ray);
    }

    // Output to screen
    fragColor = vec4(sqrt(col * invNumSamples),1.0);
}

#ifdef DEBUG
void main() {

  vec4 color;
  mainImage(color, gl_FragCoord.xy);
  frag_color = color;
}
#endif
