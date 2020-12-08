
#define RANDOM1
#ifdef RANDOM1

// random numbers utilities from https://www.shadertoy.com/view/tsf3Dn
int MIN = -2147483648;
int MAX = 2147483647;

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
#else

float random(){
    vec2 co = gl_FragCoord.xy/iResolution.xy;
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}
#endif

//==================================================================

const float pi = 3.1415926535897932385;


// vec4 vec3 shape position + index properties
// properties
const int ShapeSphere = 0;
struct Item
{
    vec3 position;
    int material;  // material index
    int shapeType; // 0 sphere
    float radius;
};

const int MaterialLambert = 0;
const int MaterialMetal = 1;
struct Material
{
    // 0  = Lambert material
    // 1  = Metal material
    int type;
    vec3 albedo;
};

struct Scene
{
    Item items[10];
    Material materials[10];
    int numItems;

} gScene;

struct Ray {
    vec3 origin;
    vec3 direction;
};

struct Hit {
    vec3 position;
    float t;
    vec3 normal;
    int material;
};

vec3 rayAt(Ray ray, float t) {
    return ray.origin + t * ray.direction;
}

vec3 randomUnitSphere(inout int seed) {
    int i = 0;
    vec3 p;
    for (i =0; i < 100; i++) {
        p = vec3(
                 random(seed, -1.0,1.0),
                 random(seed, -1.0,1.0),
                 random(seed, -1.0,1.0));
        if ( dot(p,p) <= 1.0)
            return p;
    }
    return normalize(p);
}

vec3 randomUnitHemiSphere(inout int seed, const vec3 normal) {
    vec3 p;
    int i;
    for (i =0; i < 10; i++) {
        p = vec3(
                 random(seed, -1.0,1.0),
                 random(seed, -1.0,1.0),
                 random(seed, -1.0,1.0));
        if (length(p) == 0.0) {
            continue;
        }
        break;
    }
    if (dot(normal, p) > 0.0 ) {
        return normalize(p);
    }
    return normalize(-p);
}

bool intersectSphere(const Ray ray, float t_min, float t_max, const Item item, out Hit hit) {
    vec4 sphere = vec4(item.position.xyz, item.radius);
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
    return true;
}

const vec3 camera = vec3(0.0);
const float planez= -1.0;

Ray getCameraRay(const vec2 sampleOffset)
{
    vec4 fragCoord = gl_FragCoord;

    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (fragCoord.xy+sampleOffset)/iResolution.xy;
    float aspectRatio = iResolution.y * 1.0 / iResolution.x;
    // compute from -2 to 2
    uv.x = (uv.x-0.5)*4.0;
    uv.y = (uv.y-0.5)*4.0* aspectRatio;

    vec3 rayDirection = normalize(vec3(uv.x,uv.y,planez)-camera);
    Ray ray;
    ray.origin=camera;
    ray.direction=rayDirection;
    return ray;
}

vec3 rayBackgroundColor(const Ray r) {
    const vec3 sky = vec3(0.5, 0.7, 1.0);
    const vec3 ground = vec3(1.0, 1.0, 1.0);
    float t = 0.5*(r.direction.y + 1.0);
    return mix(ground, sky, t);
}


bool intersectWorld(const Ray ray, float min_t, float max_t, out Hit hit)
{
    int i;
    bool rayHit = false;
    for ( i = 0 ; i < gScene.numItems; i++) {
        if (gScene.items[i].shapeType == ShapeSphere) {
            Item sphere = gScene.items[i];
            bool intersect = intersectSphere(ray, min_t, max_t, sphere, hit);
            if (intersect) {
                max_t = hit.t;
                rayHit = true;
            }
        }
    }

    return rayHit;
}

int raySeed = 0;

// Lambert material scattering
bool scatterLambert(const Ray ray, const Hit hit, out vec3 attenuation, out Ray scattered) {
    scattered.direction = hit.normal + randomUnitSphere(raySeed);
    if (abs(scattered.direction.x) < 1e-8 && abs(scattered.direction.y) < 1e-8 && abs(scattered.direction.z) < 1e-8) {
        scattered.direction = hit.normal;
    }
    scattered.origin = hit.position;
    attenuation = gScene.materials[hit.material].albedo;
    return true;
}
// Metal material scattering
bool scatterMetal(const Ray ray, const Hit hit, out vec3 attenuation, out Ray scattered) {
    vec3 reflected = reflect(normalize(ray.direction), hit.normal);
    scattered.direction = reflected;
    scattered.origin = hit.position;
    attenuation = gScene.materials[hit.material].albedo;
    return (dot(scattered.direction, hit.normal) > 0.0);
}

bool rayInner(const Ray ray, out Ray nextRay, inout vec3 color)
{
    Hit hit;
    if (intersectWorld(ray, 0.001, 1e8, hit)) {

        bool result = false;
        vec3 attenuation;
        switch (hit.material) {
        case MaterialLambert:
            result = scatterLambert(ray, hit, attenuation, nextRay);
            break;
        case MaterialMetal:
            result = scatterMetal(ray, hit, attenuation, nextRay);
            break;
        }

        if (result) {
            color *= attenuation;
        } else {
            color *= vec3(0.0);
        }
        //nextRay = Ray(hit.position, randomUnitHemiSphere(raySeed, hit.normal));
        return result;
    }

    color *= rayBackgroundColor(ray);
    return false;
}

vec3 rayColor(const Ray ray)
{
    vec3 color = vec3(1.0);
    const int maxNumRay = 10;
    int i = 0;
    Ray currentRay = ray;
    Ray nextRay;
    for (i = 0; i < maxNumRay; i++) {
        bool hit = rayInner(currentRay, nextRay, color);
        if (!hit) {
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
    scene.materials[0].type = MaterialLambert;
    scene.materials[0].albedo = vec3(0.5,0.5,0.5);

    scene.materials[1].type = MaterialMetal;


    int itemIndex = 0;
    scene.items[itemIndex].position = vec3(0.0, 0.0, -1.0);
    scene.items[itemIndex].radius = 0.5;
    scene.items[itemIndex].shapeType = ShapeSphere;
    scene.items[itemIndex].material = 0;
    itemIndex++;

    scene.items[itemIndex].position = vec3(0.0,-100.5,-1.0);
    scene.items[itemIndex].radius = 100.0;
    scene.items[itemIndex].shapeType = ShapeSphere;
    scene.items[itemIndex].material = 0;
    itemIndex++;

    scene.numItems = itemIndex;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    int rngSeed = int(fragCoord.x) + int(fragCoord.y) * int(iResolution.x);
    raySeed = rngSeed;

    setupScene(gScene);

    const int numSamples = 10;
    int i;
    vec3 col= vec3(0.0);
    for (i = 0; i < numSamples; i++) {
        vec2 offset = vec2(random(rngSeed),random(rngSeed));
        Ray ray = getCameraRay(offset);
        col += rayColor(ray);
    }

    // Output to screen
    fragColor = vec4(sqrt(col * 1.0/float(numSamples)),1.0);
}
