//#version 300 es

//#define USE_BVH

#ifdef DEBUG
precision mediump float;
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

#define PI 3.14159265359

#define SHAPE_SPHERE 0 
#define SHAPE_RECT_XY 1
#define SHAPE_RECT_XZ 2
#define SHAPE_RECT_YZ 3
#define SHAPE_BOX 4

#define MaterialLambert 0.0
#define MaterialMetal 10.0
#define MaterialDielectric 20.0
#define MaterialLight 30.0

struct Item
{
    vec3 position; // position
    int type;      // shape_type
    vec4 size;     // size.x    = radius
                   // size.xyzw = rect position
                   // size.xyz  = box size
    vec4 material; // xyz color
                   // w > 30 light emit
                   // w > 20 = glass, ior = w - 20.0
                   // w 10 > 20 = metal, roughness = fract(w)
                   // w = 0 > 10.0 = lambert, texture type = floor(w - 10)
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
    vec2 time;
    float lensRadius;
};


//=======================================================

//#define MainScene
//#define SimpleScene
//#define TwoSpherePerlin
//#define SimpleLight
#define CornelBox
#ifdef MainScene
#define NumItems 125
Item Items[NumItems] = Item[NumItems](
Item(vec3(0.0,-1000,-1.0), int(SHAPE_SPHERE), vec4(1000.0,0.0,0.0,0.0), vec4(0.5,0.5,0.5,1.0)),
Item(vec3(0.0,1.0,0.0), int(SHAPE_SPHERE), vec4(1.0,0.0,0.0,0.0), vec4(0.0,0.0,0.0,21.5)),
Item(vec3(-4.0,1.0,0.0), int(SHAPE_SPHERE), vec4(1.0,0.0,0.0,0.0), vec4(0.4,0.2,0.1,0.0)),
Item(vec3(4.0,1.0,0.0), int(SHAPE_SPHERE), vec4(1.0,0.0,0.0,0.0), vec4(0.7,0.6,0.5,10.0)),
Item(vec3(-10.87907218029884,0.2,-10.23730963675649), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.018053750095896947,0.7181439384994028,0.5833516685928719,0.0)),
Item(vec3(-10.77043787683452,0.2,-8.554108421617252), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.06506020789165777,0.24545592552179912,0.20204221732491356,0.0)),
Item(vec3(-10.413566324549514,0.2,-6.290148983978038), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.4245734021016873,0.622084524626434,0.00880962202943013,0.0)),
Item(vec3(-10.974487271130194,0.2,-4.247811406472117), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.000803579425165699,0.6985033089301906,0.18728733506313708,0.0)),
Item(vec3(-10.313947925787852,0.2,-2.9981045519840004), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.5810709241120868,4.435460717724579e-06,0.19836975262800935,0.0)),
Item(vec3(-10.350613970893296,0.2,-0.7941140008565926), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.5206200182703375,0.052332153880591536,0.893536687872996,0.0)),
Item(vec3(-10.188715288149664,0.2,1.027530984730198), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.9507137288057418,0.5152949915167768,0.5127229304967305,10.014989091686441)),
Item(vec3(-10.512728774485852,0.2,3.8452342465006595), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.29312746569636866,0.8820011499475774,0.14531667083145117,0.0)),
Item(vec3(-10.805060542582448,0.2,5.379904918024446), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.04691529883734517,0.1781824033816799,0.0008433673429686043,0.0)),
Item(vec3(-10.800477500354269,0.2,7.394098834285515), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.049147194894914745,0.19174554467308852,0.24582977870409453,0.0)),
Item(vec3(-10.790223994768185,0.2,9.207779887386886), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.05432836095187485,0.05329936000309503,0.0478651422985551,0.0)),
Item(vec3(-8.586356880836039,0.2,-10.739196546868563), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.21123534571813604,0.08397338415466872,0.0004618074324156317,0.0)),
Item(vec3(-8.246179821903684,0.2,-8.49919110961281), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.9187889878312865,0.7782271613262167,0.8211471814662228,10.272662618099693)),
Item(vec3(-8.832684360694754,0.2,-6.106710929041541), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.03456113969891748,0.9851424250541063,0.7395080323870683,0.0)),
Item(vec3(-8.891199036174774,0.2,-4.700574333175884), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.01461438238184949,0.11068608636181065,0.5205397503857797,0.0)),
Item(vec3(-8.359927407274249,0.2,-2.1572034718804862), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.5057937332823037,0.8769209726053163,0.17817431941642617,0.0)),
Item(vec3(-8.252967876053106,0.2,-0.3967249902273361), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.9150178466371635,0.8351527832070356,0.6516842554664588,10.328449727542894)),
Item(vec3(-8.471177454470796,0.2,1.794231100748672), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.3452509687160327,0.778769186909194,0.716050070954741,0.0)),
Item(vec3(-8.54524456147836,0.2,3.5301020321842964), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.25531173933951784,0.34692365990854435,0.0011920329476392878,0.0)),
Item(vec3(-8.78153402381124,0.2,5.7176638227988725), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.05892269475568918,0.6358535340176439,0.17165609001660198,0.0)),
Item(vec3(-8.844293338578854,0.2,7.493918885249338), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.02993156100113499,0.30118008050117084,0.49426631312582386,0.0)),
Item(vec3(-8.392962752547906,0.2,9.337232718451476), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.45493113554841413,0.14040235357305267,0.1926873126513799,0.0)),
Item(vec3(-6.542416160575017,0.2,-10.299401646499868), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.2584974939542089,0.6059729048482652,0.27137683494528764,0.0)),
Item(vec3(-6.646070414532197,0.2,-8.559275831583967), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.15464956971532245,0.2397997439827201,0.0008746784936438512,0.0)),
Item(vec3(-6.960861438679125,0.2,-6.366956120256548), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.0018911444225529236,0.4947463625686946,0.9666580874686073,0.0)),
Item(vec3(-6.4661346426579485,0.2,-4.645760282259878), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.3518669379876008,0.15492071311679226,0.029018848869375655,0.0)),
Item(vec3(-6.547985297409865,0.2,-2.116131026215319), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.25224356957734323,0.9644745219989935,0.5937059090147154,0.0)),
Item(vec3(-6.514344296395199,0.2,-0.2257391989715054), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.29118699067144965,0.740098503715168,0.053905754442333344,0.0)),
Item(vec3(-6.537605503131127,0.2,1.8572206494414427), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.2639613218945907,0.9071941257145785,0.3338468399220292,0.0)),
Item(vec3(-6.586781441280398,0.2,3.242351529697279), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.21080194724728984,0.07251143697112489,0.30029995518862884,0.0)),
Item(vec3(-6.138595346685796,0.2,5.005138216505354), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(1.5,1.5,1.5,21.5)),
Item(vec3(-6.261562679267066,0.2,7.797561622743407), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.910242955962741,0.9430897904130041,0.8702517059165982,10.434227994604743)),
Item(vec3(-6.271774089214769,0.2,9.466810455170702), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.9045699504362398,0.759339141761501,0.7806789323891895,10.254152358926271)),
Item(vec3(-4.616518388280665,0.2,-10.949489032231334), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.1815532673171098,0.003149824524601547,0.756917670110481,0.0)),
Item(vec3(-4.487000599511258,0.2,-8.820144521840572), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.3248992406195172,0.039935793856736734,0.2547427502416103,0.0)),
Item(vec3(-4.56356739899504,0.2,-6.67888903190954), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.23515236446908055,0.12729907879999075,0.11976992603193656,0.0)),
Item(vec3(-4.51536908383594,0.2,-4.438859492482245), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.28995941345927906,0.38873909774973237,0.3750980216184358,0.0)),
Item(vec3(-4.587667879910248,0.2,-2.9748225143245417), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.20989849044161685,0.0007825997344912333,0.052718470387723135,0.0)),
Item(vec3(-4.8405098669552755,0.2,-0.4739852162994028), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.0314038302945974,0.3415945094710939,0.74133625846794,0.0)),
Item(vec3(-4.281404953480316,0.2,1.7173878063719465), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.6375047418304025,0.6353645243594489,0.6665699800480549,0.0)),
Item(vec3(-4.770235363921425,0.2,3.7575703490466865), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.06517504690409898,0.708534362660146,0.45308181812852494,0.0)),
Item(vec3(-4.925089275976492,0.2,5.015021567104004), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.006927921695958262,0.0002785771336544251,0.00021199286981116332,0.0)),
Item(vec3(-4.319971902273021,0.2,7.224603303088081), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.5709113749360158,0.062279807108736006,0.011987759506803137,0.0)),
Item(vec3(-4.437678124262772,0.2,9.309980577686845), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.3903776443612781,0.1186271093124326,0.00483238785228699,0.0)),
Item(vec3(-2.8563370277755373,0.2,-10.525357640856788), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.025480308133786118,0.27813008530004124,0.028272722940143293,0.0)),
Item(vec3(-2.754377006863188,0.2,-8.359569065533254), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.07448228982405733,0.506360224471542,0.20675357236618377,0.0)),
Item(vec3(-2.7101984102514067,0.2,-6.573606087246749), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.10368513755655802,0.2244589738679346,0.0005585932598424232,0.0)),
Item(vec3(-2.652098605714677,0.2,-4.621173188711832), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.14942639524157,0.17717253450711293,0.03535878013135713,0.0)),
Item(vec3(-2.902114476799128,0.2,-2.190163349679582), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.011829105743590682,0.8096733335829571,0.2602183139988257,0.0)),
Item(vec3(-2.8118181067034067,0.2,-0.45491622396938514), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.04371904316628438,0.3668102751750537,0.6675538197030474,0.0)),
Item(vec3(-2.9812637023416415,0.2,1.0160780687450157), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.0004333936419044618,0.00031914110440673304,0.021451041400805424,0.0)),
Item(vec3(-2.353048074514389,0.2,3.144204833366734), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.5167244369006659,0.025672881439910585,0.4964690908007147,0.0)),
Item(vec3(-2.389641784250747,0.2,5.490231947221014), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.4599224092995202,0.29670044700753956,0.04866424882766839,0.0)),
Item(vec3(-2.121964933963905,0.2,7.7180297719355355), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(1.5,1.5,1.5,21.5)),
Item(vec3(-2.7991237977779964,0.2,9.58365577628933), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.04981635631992014,0.42056057431592747,0.1559444381900457,0.0)),
Item(vec3(-0.48173863349074897,0.2,-10.710878771589387), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.33159857285930394,0.10319887002180457,0.39809520364288686,0.0)),
Item(vec3(-0.9470933954141578,0.2,-8.731254645339288), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.0034556898874106854,0.08916551315026158,0.9368368178010483,0.0)),
Item(vec3(-0.21201918018835664,0.2,-6.724252041700079), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.9377671221175796,0.653193310166623,0.9292572031782796,10.15012944396329)),
Item(vec3(-0.7206727353821794,0.2,-4.154640411078246), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.09632558118379506,0.8822627587431571,0.5533010975031916,0.0)),
Item(vec3(-0.625444963511477,0.2,-2.7728777079481484), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.17319935229496145,0.06368461178627983,7.191485145271074e-05,0.0)),
Item(vec3(-0.209153891612038,0.2,-0.9658751224612775), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.9393589491044233,0.5189582652992903,0.9097070553063986,10.018579099993305)),
Item(vec3(-0.1340189873372638,0.2,1.5132525132206622), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(1.5,1.5,1.5,21.5)),
Item(vec3(-0.218997042008506,0.2,3.8763977125437226), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.9338905322174966,0.9868876180798458,0.8520115711650357,10.47714986571825)),
Item(vec3(-0.5420136285298985,0.2,5.340171950909247), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.2589524894473454,0.14286043973506582,0.12036103866340311,0.0)),
Item(vec3(-0.8148144184347658,0.2,7.606737712822178), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.04233790076500496,0.4544822866181326,0.18744580736077854,0.0)),
Item(vec3(-0.8252932195133293,0.2,9.093981800557364), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.03768204833088608,0.010904418316054449,0.4434994294710523,0.0)),
Item(vec3(1.2664654057748364,0.2,-10.550180069986878), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.08765902774660274,0.2497999622679129,0.1058497951466909,0.0)),
Item(vec3(1.7844593566811997,0.2,-8.190289557328697), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.9358107537117776,0.9498391348173906,0.5090464918202359,10.440842352121043)),
Item(vec3(1.1807677102966834,0.2,-6.705033365413359), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.04034193220482182,0.10741396977699859,0.9742671456617958,0.0)),
Item(vec3(1.704430338156438,0.2,-4.69481391693416), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.6126198781669057,0.11498585839144444,0.04538169414605097,0.0)),
Item(vec3(1.607009562751387,0.2,-2.246069036861432), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.4548896410760863,0.7017430829370971,0.8689734827554322,0.0)),
Item(vec3(1.3094648333117378,0.2,-0.2058461177801828), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.11823269513168107,0.7786177637590214,0.4721204024192322,0.0)),
Item(vec3(1.4360488503512445,0.2,1.886957406843218), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.23473901221313845,0.9712264710543774,0.05505613367647005,0.0)),
Item(vec3(1.6529186676171452,0.2,3.076212207374836), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.5262997364480841,0.0071707414233888565,0.028796101759333715,0.0)),
Item(vec3(1.8198890051572612,0.2,5.191671375492282), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.9554938917540339,0.6064840974957121,0.8795580913582202,10.104354415545798)),
Item(vec3(1.5401879471190245,0.2,7.75701897613527), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.3602506397687236,0.7075033706529529,0.13550349922642935,0.0)),
Item(vec3(1.3062567115017893,0.2,9.262093758670021), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.11579404116035823,0.08480634362194978,0.7524171503515334,0.0)),
Item(vec3(3.54358427600254,0.2,-10.141123288545028), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.3647948952064268,0.9107027228144511,0.7872393660484028,0.0)),
Item(vec3(3.1218113796559077,0.2,-8.503946573337705), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.01831853359713046,0.30378889148568483,0.010873275210947669,0.0)),
Item(vec3(3.0352240187372197,0.2,-6.934125923050886), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.0015317672790123357,0.005357276560367593,0.7502476233031057,0.0)),
Item(vec3(3.709304803852704,0.2,-4.254344625677798), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.6211275367512623,0.6864221447599795,0.11621108104111726,0.0)),
Item(vec3(3.553667429303133,0.2,-2.2962867585305204), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.378453854655728,0.6113732422462737,0.1429139609722657,0.0)),
Item(vec3(3.513703373039121,0.2,-0.7986573345261077), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.3257915499651485,0.0500479863458416,0.006681960940012267,0.0)),
Item(vec3(3.2400512786835627,0.2,1.8016913150697749), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.07114150172544875,0.7934678576028457,0.3186002275548872,0.0)),
Item(vec3(3.8325604818976258,0.2,3.4119923331371207), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.9625336010542367,0.7288846295206226,0.6385913830538492,10.22430693693021)),
Item(vec3(3.708313197204296,0.2,5.744991340981157), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.6193920806589776,0.6852001211566693,0.00015330759653309933,0.0)),
Item(vec3(3.6033704751215376,0.2,7.082514810354866), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.4494517657387535,0.008405794972715435,0.013248585144351007,0.0)),
Item(vec3(3.796554063341695,0.2,9.036021183201148), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.9425300351898305,0.5200117684450823,0.6198166824337547,10.01961153307618)),
Item(vec3(5.88934264874543,0.2,-10.621087771312759), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(1.5,1.5,1.5,21.5)),
Item(vec3(5.150645093715198,0.2,-8.78272174341194), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.028017215136371565,0.058283754056723834,0.5535455478482404,0.0)),
Item(vec3(5.0925507313876786,0.2,-6.1803120235486), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.010574861580733676,0.8294918256036924,0.14309369341038963,0.0)),
Item(vec3(5.87323763287539,0.2,-4.18169954466436), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(1.5,1.5,1.5,21.5)),
Item(vec3(5.228069122437014,0.2,-2.5706909136249587), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.06421669704838236,0.2275386316594722,0.010025845468250343,0.0)),
Item(vec3(5.586845179540475,0.2,-0.964341807927666), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.4251694626541888,0.001569761310947488,0.00011037921973330009,0.0)),
Item(vec3(5.884325263895417,0.2,1.265994874044026), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(1.5,1.5,1.5,21.5)),
Item(vec3(5.404860081167088,0.2,3.281952774962035), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.20236010533656923,0.09814489791208893,0.003964564785744056,0.0)),
Item(vec3(5.8220528154493465,0.2,5.872831949154304), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.9566960085829702,0.9849066384190578,0.984898252248235,10.475208505650677)),
Item(vec3(5.1002260791142024,0.2,7.193673943032489), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.01240156411679805,0.04630814346882919,0.38168534098961276,0.0)),
Item(vec3(5.881957597301069,0.2,9.488621877736245), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(1.5,1.5,1.5,21.5)),
Item(vec3(7.595650985987814,0.2,-10.76682260733172), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.4380248112447597,0.06712555117478701,0.29333301119244504,0.0)),
Item(vec3(7.276589006031262,0.2,-8.778256923523417), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.0944462694535328,0.06070369378432067,0.006620875980081902,0.0)),
Item(vec3(7.252708051208208,0.2,-6.114960954502537), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.0788411841301855,0.9670297679692086,0.20061641707474612,0.0)),
Item(vec3(7.586809481061404,0.2,-4.420880527757142), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.42511773711549833,0.4140485964578343,0.8849814413510543,0.0)),
Item(vec3(7.351430696025031,0.2,-2.7238941346336376), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.15247349889955264,0.09411660356754042,0.10708694348643627,0.0)),
Item(vec3(7.285061632197042,0.2,-0.23757871075640646), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.10032115327264395,0.7176373114714362,0.7983426887471613,0.0)),
Item(vec3(7.2725283967052645,0.2,1.3009000650856857), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.09169349013671865,0.11177882613403688,0.2961813014417699,0.0)),
Item(vec3(7.521086892685376,0.2,3.536366286000904), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.33522413546728397,0.3551713490844487,0.0600730315134353,0.0)),
Item(vec3(7.018336625601627,0.2,5.219383369845124), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.0004151010351287002,0.05941859625259574,0.005231272155920089,0.0)),
Item(vec3(7.496084279423956,0.2,7.063824730785581), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.30382668184146305,0.0050291311850023356,0.005644485684207782,0.0)),
Item(vec3(7.571843884206752,0.2,9.261739395377456), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.4037104048205736,0.08457717418834107,0.6275566906210261,0.0)),
Item(vec3(9.443934938475124,0.2,-10.223615919998261), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.2433064562949534,0.7441632588643775,0.023771347872937675,0.0)),
Item(vec3(9.451286627352024,0.2,-8.28451485562858), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.2514316296626723,0.6319987553286345,0.005945487330703746,0.0)),
Item(vec3(9.854305154075643,0.2,-6.844082102465557), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.9746139744864681,0.5866210541858018,0.8881044914929678,10.084888633102086)),
Item(vec3(9.886406284029665,0.2,-4.260604869730837), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(1.5,1.5,1.5,21.5)),
Item(vec3(9.096189961123404,0.2,-2.537077574050276), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.011422850149286344,0.2645644104286148,0.8452171816748446,0.0)),
Item(vec3(9.264140544933602,0.2,-0.19561708207378914), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.08613608330595021,0.7988047884586237,0.020073405741902917,0.0)),
Item(vec3(9.81943350695346,0.2,1.028583951307603), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.955240837196367,0.5158799729486683,0.6580343388804415,10.015562373489695)),
Item(vec3(9.812779455342701,0.2,3.7234706528855748), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.9515441418570563,0.9019281404919859,0.9535768834983986,10.393889577682145)),
Item(vec3(9.756646670022064,0.2,5.67156639686407), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.9203592611233689,0.873092442702261,0.8447975896501323,10.365630593848216)),
Item(vec3(9.160339379079891,0.2,7.389374200878613), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.03173915615274699,0.1871756398887144,0.02493144484627296,0.0)),
Item(vec3(9.643342006771931,0.2,9.601000865716987), int(SHAPE_SPHERE), vec4(0.2,0.0,0.0,0.0), vec4(0.5109739971325113,0.4459284451760109,0.06379989340221796,0.0))
);
#endif
#ifdef SimpleScene
#define NumItems 2
Item Items[NumItems] = Item[NumItems](
Item(vec3(0.0,-10.0,0.0), int(SHAPE_SPHERE), vec4(10.0,0.0,0.0,0.0), vec4(0.4,0.2,0.1,1.0)),
Item(vec3(0.0,10.0,0.0), int(SHAPE_SPHERE), vec4(10.0,0.0,0.0,0.0), vec4(0.4,0.2,0.1,1.0))
);
#endif
#ifdef TwoSpherePerlin
#define NumItems 2
Item Items[NumItems] = Item[NumItems](
Item(vec3(0.0,-1000.0,0.0), int(SHAPE_SPHERE), vec4(1000.0,0.0,0.0,0.0), vec4(0.4,0.2,0.1,2.0)),
Item(vec3(0.0,2.0,0.0), int(SHAPE_SPHERE), vec4(2.0,0.0,0.0,0.0), vec4(0.4,0.2,0.1,2.0))
);
#endif
#ifdef SimpleLight
#define NumItems 3
Item Items[NumItems] = Item[NumItems](
Item(vec3(0.0,-1000.0,0.0), int(SHAPE_SPHERE), vec4(1000.0,0.0,0.0,0.0), vec4(0.4,0.2,0.1,2.0)),
Item(vec3(0.0,2.0,0.0), int(SHAPE_SPHERE), vec4(2.0,0.0,0.0,0.0), vec4(0.4,0.2,0.1,2.0)),
Item(vec3(3.0,1.0,0.0), int(SHAPE_RECT_XY), vec4(5.0,3.0,-2.0,0.0), vec4(4.0,4.0,4.0,30.5))
);
#endif
#ifdef CornelBox
#define NumItems 18
Item Items[NumItems] = Item[NumItems](
Item(vec3(0.0,0.0,0.0), int(SHAPE_RECT_YZ), vec4(555.0,555.0,555.0,0.0), vec4(0.12,0.45,0.15,0.0)),
Item(vec3(0.0,0.0,0.0), int(SHAPE_RECT_YZ), vec4(555.0,555.0,0.0,0.0), vec4(0.65,0.05,0.05,0.0)),
Item(vec3(113.0,127.0,0.0), int(SHAPE_RECT_XZ), vec4(443.0,432.0,554.0,0.0), vec4(15.0,15.0,15.0,30.5)),
Item(vec3(0.0,0.0,0.0), int(SHAPE_RECT_XZ), vec4(555.0,555.0,0.0,0.0), vec4(0.73,0.73,0.73,0.0)),
Item(vec3(0.0,0.0,0.0), int(SHAPE_RECT_XZ), vec4(555.0,555.0,555.0,0.0), vec4(0.73,0.73,0.73,0.0)),
Item(vec3(0.0,0.0,0.0), int(SHAPE_RECT_XY), vec4(555.0,555.0,555.0,0.0), vec4(0.73,0.73,0.73,0.0)),
Item(vec3(130.0,0.0,0.0), int(SHAPE_RECT_XY), vec4(295.0,165.0,230.0,0.0), vec4(0.73,0.73,0.73,0.0)),
Item(vec3(130.0,0.0,0.0), int(SHAPE_RECT_XY), vec4(295.0,165.0,65.0,0.0), vec4(0.73,0.73,0.73,0.0)),
Item(vec3(130.0,65.0,0.0), int(SHAPE_RECT_XZ), vec4(295.0,230.0,165.0,0.0), vec4(0.73,0.73,0.73,0.0)),
Item(vec3(130.0,65.0,0.0), int(SHAPE_RECT_XZ), vec4(295.0,230.0,0.0,0.0), vec4(0.73,0.73,0.73,0.0)),
Item(vec3(0.0,65.0,0.0), int(SHAPE_RECT_YZ), vec4(165.0,230.0,130.0,0.0), vec4(0.73,0.73,0.73,0.0)),
Item(vec3(0.0,65.0,0.0), int(SHAPE_RECT_YZ), vec4(165.0,230.0,295.0,0.0), vec4(0.73,0.73,0.73,0.0)),
Item(vec3(265.0,0.0,0.0), int(SHAPE_RECT_XY), vec4(430.0,330.0,460.0,0.0), vec4(0.73,0.73,0.73,0.0)),
Item(vec3(265.0,0.0,0.0), int(SHAPE_RECT_XY), vec4(430.0,330.0,295.0,0.0), vec4(0.73,0.73,0.73,0.0)),
Item(vec3(265.0,295.0,0.0), int(SHAPE_RECT_XZ), vec4(430.0,460.0,330.0,0.0), vec4(0.73,0.73,0.73,0.0)),
Item(vec3(265.0,295.0,0.0), int(SHAPE_RECT_XZ), vec4(430.0,460.0,0.0,0.0), vec4(0.73,0.73,0.73,0.0)),
Item(vec3(0.0,295.0,0.0), int(SHAPE_RECT_YZ), vec4(330.0,460.0,265.0,0.0), vec4(0.73,0.73,0.73,0.0)),
Item(vec3(0.0,295.0,0.0), int(SHAPE_RECT_YZ), vec4(330.0,460.0,430.0,0.0), vec4(0.73,0.73,0.73,0.0))
);
// 113, 443, 127, 432
#endif

//=====================================================

struct Ray {
    vec4 origin; // origin xyz + time as w
    vec3 direction;
};

struct Hit {
    Item item;
    vec3 position;
    vec3 normal;
    vec2 uv;
    float t;
    bool frontFace;
};

vec3 rayAt(const Ray ray, const float t) {
    return ray.origin.xyz + t * ray.direction;
}

vec3 getItemCenter(const Item item, const float time)
{
    return item.position;
    // float ratio = (time-item.center0.w)/(item.center1.w-item.center0.w);
    // return mix(item.center0.xyz, item.center1.xyz, ratio);
}

#define OddCheckboard vec3(0.2, 0.3, 0.1)
#define EvenCheckboard vec3(0.9, 0.9, 0.9)


// different noise ready to use
// https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83

//	Simplex 3D Noise 
//	by Ian McEwan, Ashima Arts
//
vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
vec4 taylorInvSqrt(vec4 r){return 1.79284291400159 - 0.85373472095314 * r;}

float simplex(vec3 v){ 
  const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
  const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);

// First corner
  vec3 i  = floor(v + dot(v, C.yyy) );
  vec3 x0 =   v - i + dot(i, C.xxx) ;

// Other corners
  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min( g.xyz, l.zxy );
  vec3 i2 = max( g.xyz, l.zxy );

  //  x0 = x0 - 0. + 0.0 * C 
  vec3 x1 = x0 - i1 + 1.0 * C.xxx;
  vec3 x2 = x0 - i2 + 2.0 * C.xxx;
  vec3 x3 = x0 - 1. + 3.0 * C.xxx;

// Permutations
  i = mod(i, 289.0 ); 
  vec4 p = permute( permute( permute( 
             i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
           + i.y + vec4(0.0, i1.y, i2.y, 1.0 )) 
           + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

// Gradients
// ( N*N points uniformly over a square, mapped onto an octahedron.)
  float n_ = 1.0/7.0; // N=7
  vec3  ns = n_ * D.wyz - D.xzx;

  vec4 j = p - 49.0 * floor(p * ns.z *ns.z);  //  mod(p,N*N)

  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

  vec4 x = x_ *ns.x + ns.yyyy;
  vec4 y = y_ *ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);

  vec4 b0 = vec4( x.xy, y.xy );
  vec4 b1 = vec4( x.zw, y.zw );

  vec4 s0 = floor(b0)*2.0 + 1.0;
  vec4 s1 = floor(b1)*2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));

  vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
  vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

  vec3 p0 = vec3(a0.xy,h.x);
  vec3 p1 = vec3(a0.zw,h.y);
  vec3 p2 = vec3(a1.xy,h.z);
  vec3 p3 = vec3(a1.zw,h.w);

//Normalise gradients
  vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;

// Mix final noise value
  vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m;
  return 42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1), 
                                dot(p2,x2), dot(p3,x3) ) );
}

float smoothNoise(const vec3 p) {
//    return ((0.5 + 0.5*simplex(p))*0.5 + 0.5*(0.5 + 0.5*simplex(p*5.0)));
//    return (0.5 + 0.5*simplex(p*2.0));
//
    float accum = 0.0;
    vec3 temp_p = p;
    float weight = 1.0;
    int i;
    for (i = 0; i < 7; i++) {
        accum += weight*simplex(temp_p);
        weight *= 0.5;
        temp_p *= 2.0;
    }
    return abs(accum);
}


vec3 getCheckerBoardTexture(const vec2 uv, const vec3 p) {
    float sines = sin(10.0*p[0])*sin(10.0*p[1])*sin(10.0*p[2]);
    if (sines < 0.0)
        return OddCheckboard;
    else
        return EvenCheckboard;
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

vec2 getSphereUV(const vec3 pos)
{
    // p: a given point on the sphere of radius one, centered at the origin.
    // u: returned value [0,1] of angle around the Y axis from X=-1.
    // v: returned value [0,1] of angle from Y=-1 to Y=+1.
    //     <1 0 0> yields <0.50 0.50>       <-1  0  0> yields <0.00 0.50>
    //     <0 1 0> yields <0.50 1.00>       < 0 -1  0> yields <0.50 0.00>
    //     <0 0 1> yields <0.25 0.50>       < 0  0 -1> yields <0.75 0.50>

    float theta = acos(-pos[1]);
//    float phi = atan2(-pos[2], pos[0]) + PI;
//    atan2(x,y) == GLSL atan(y,x)
    float phi = atan(pos[0], -pos[2]) + PI;
    return vec2(phi / (2.0*PI), theta / PI);    
}

bool _intersectRectXY(const Ray r, float t_min, float t_max, const vec2 p0, const vec2 p1, const float k, inout Hit hit)  {
    float t = (k-r.origin.z) / r.direction.z;
    if (t < t_min || t > t_max) {
        return false;
    }
    float x = r.origin.x + t*r.direction.x;
    float y = r.origin.y + t*r.direction.y;
    if (x < p0.x || x > p1.x || y < p0.y || y > p1.y) {
        return false;
    }
    hit.uv = vec2( (x-p0.x)/(p1.x-p0.x) ,(y-p0.y)/(p1.y-p0.y)); 
    hit.t = t;
    vec3 normal = vec3(0.0, 0.0, 1.0);
    bool front_face = dot(r.direction, normal) < 0.0;
    hit.normal = front_face ? normal :-normal;
    hit.position = rayAt(r, t);
    return true;
}

bool _intersectRectXZ(const Ray r, float t_min, float t_max, const vec2 p0, const vec2 p1, const float k, inout Hit hit)  {
    float t = (k-r.origin.y) / r.direction.y;
    if (t < t_min || t > t_max) {
        return false;
    }
    float x = r.origin.x + t*r.direction.x;
    float z = r.origin.z + t*r.direction.z;
    if (x < p0.x || x > p1.x || z < p0.y || z > p1.y) {
        return false;
    }
    hit.uv = vec2( (x-p0.x)/(p1.x-p0.x) ,(z-p0.y)/(p1.y-p0.y)); 
    hit.t = t;
    vec3 normal = vec3(0.0, 1.0, 0.0);
    bool front_face = dot(r.direction, normal) < 0.0;
    hit.normal = front_face ? normal :-normal;
    hit.position = rayAt(r, t);
    return true;
}

bool _intersectRectYZ(const Ray r, float t_min, float t_max, const vec2 p0, const vec2 p1, const float k, inout Hit hit)  {
    float t = (k-r.origin.x) / r.direction.x;
    if (t < t_min || t > t_max) {
        return false;
    }
    float y = r.origin.y + t*r.direction.y;
    float z = r.origin.z + t*r.direction.z;
    if (y < p0.x || y > p1.x || z < p0.y || z > p1.y) {
        return false;
    }
    hit.uv = vec2( (y-p0.x)/(p1.x-p0.x) ,(z-p0.y)/(p1.y-p0.y)); 
    hit.t = t;
    vec3 normal = vec3(1.0, 0.0, 0.0);
    bool front_face = dot(r.direction, normal) < 0.0;
    hit.normal = front_face ? normal :-normal;
    hit.position = rayAt(r, t);
    return true;
}

bool intersectRectXY(const Ray ray, const float t_min, const float t_max, const Item item, inout Hit hit) {
    return _intersectRectXY(ray, t_min, t_max, item.position.xy, item.size.xy, item.size.z, hit);
}

bool intersectRectXZ(const Ray ray, const float t_min, const float t_max, const Item item, inout Hit hit) {
    return _intersectRectXZ(ray, t_min, t_max, item.position.xy, item.size.xy, item.size.z, hit);
}

bool intersectRectYZ(const Ray ray, const float t_min, const float t_max, const Item item, inout Hit hit) {
    return _intersectRectYZ(ray, t_min, t_max, item.position.xy, item.size.xy, item.size.z, hit);
}

bool _intersectSphere(const Ray ray, const float t_min, const float t_max, const vec4 sphere, inout Hit hit) {
    vec3 oc = ray.origin.xyz - sphere.xyz;
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
    hit.uv = getSphereUV(hit.normal);
    return true;
}

bool intersectSphere(const Ray ray, const float t_min, const float t_max, const Item item, inout Hit hit) {
    float time = ray.origin.w;
    vec4 sphere = vec4(getItemCenter(item, time), item.size.x);
    return _intersectSphere(ray, t_min, t_max, sphere, hit);
}

bool intersectWorld(const Ray ray, float min_t, float max_t, out Hit hit)
{
    bool rayHit = false;

    int i;
    for ( i = 0 ; i < NumItems; i++) {
        bool intersect;
        if (Items[i].type == SHAPE_RECT_XY) {
            intersect = intersectRectXY(ray, min_t, max_t, Items[i], hit);
        } else if (Items[i].type == SHAPE_RECT_XZ) {
            intersect = intersectRectXZ(ray, min_t, max_t, Items[i], hit);
        } else if (Items[i].type == SHAPE_RECT_YZ) {
            intersect = intersectRectYZ(ray, min_t, max_t, Items[i], hit);
        } else if (Items[i].type == SHAPE_SPHERE) {
            intersect = intersectSphere(ray, min_t, max_t, Items[i], hit);
        } else {
            intersect = false;
        }
        if (intersect) {
            hit.item = Items[i];
            max_t = hit.t;
            rayHit = true;
        }
    }
    return rayHit;
}

vec3 getLambertColor(const Hit hit, const vec4 material)
{
    int type = int(floor(material.w) - MaterialLambert); 
    if (type == 0) {
        return material.rgb;
    } else if (type == 1) {
        return getCheckerBoardTexture(hit.uv, hit.position);
    } else if (type == 2) {
        return material.rgb * smoothNoise(hit.position);
    }

    return vec3(1.0);
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
    scattered.origin.xyz = hit.position;
    scattered.origin.w = ray.origin.w; // time

    attenuation = getLambertColor(hit, hit.item.material);
    return 1.0;
}

// Metal material scattering
float scatterMetal(const Ray ray, const Hit hit, out vec3 attenuation, out Ray scattered) {
    float roughness = fract(hit.item.material.w);
    vec3 reflected = reflect(normalize(ray.direction), hit.normal) + roughness * randomUnitSphere();
    scattered.direction = normalize(reflected);
    scattered.origin.xyz = hit.position;
    scattered.origin.w = ray.origin.w; // time
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


    scattered.direction = direction;
    scattered.origin.xyz = hit.position;
    scattered.origin.w = ray.origin.w; // time
    return 1.0;
}

// Lambert material scattering
float materialLightEmit(const Ray ray, const Hit hit, out vec3 attenuation, out Ray scattered) {
    attenuation = getLambertColor(hit, hit.item.material);
    return 0.0;
}

float rayInner(const Ray ray, const vec3 background,out Ray nextRay, inout vec3 color)
{
    Hit hit;
    if (intersectWorld(ray, 0.001, 1e8, hit)) {

        float result;
        vec3 attenuation = vec3(0.0);
        vec3 emit = vec3(0.0);
        float type = hit.item.material.w;
        if (type >= MaterialLight) {
            materialLightEmit(ray, hit, emit, nextRay);
            color *= emit;
            return 0.0;
        } else if (type >= MaterialDielectric) {
            result = scatterDieletric(ray, hit, attenuation, nextRay);
        } else if (type >= MaterialMetal) {
            result = scatterMetal(ray, hit, attenuation, nextRay);
        } else {
            result = scatterLambert(ray, hit, attenuation, nextRay);
        }
        color *= emit + result * attenuation;
        return result;
    }

    color *= background; //rayBackgroundColor(ray);
    return 0.0;
}

vec3 rayColor(const Ray ray, const vec3 background)
{
    vec3 color = vec3(1.0);
    const int maxNumRay = 10;
    int i = 0;
    Ray currentRay = ray;
    for (i = 0; i < maxNumRay; i++) {
        Ray nextRay;
        float hit = rayInner(currentRay, background, nextRay, color);
        if (hit == 0.0) {
            //i = maxNumRay;
            break;
        }
        currentRay = nextRay;
    }

    if (i==maxNumRay) {
        return vec3(0.0);
    }

    return color;
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
    ray.origin.xyz = camera.position + diskOffset;
    ray.direction=normalize(startPosition + pixel - diskOffset);
    // time
    ray.origin.w = random(camera.time[0], camera.time[1]);
    return ray;
}

Camera computeCameraLookAt(const vec3 eye, const vec3 target, const float aspectRatio, const float fovy, const float aperture, const float focusDist, const float t0, const float t1)
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
    camera.time[0] = t0;
    camera.time[1] = t1;
    camera.lensRadius = aperture/2.0;
    return camera;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    randomSeed = int(fragCoord.x) + int(fragCoord.y) * int(iResolution.x);

//    const float aperture = 2.0;
//    const vec3 eye = vec3(3.0, 3.0, 2.0);
//    const vec3 target = vec3(0.0,0.0,-1.0);
//    const float distToFocus = length(eye-target);
//
    int numSamples = 10; 
#ifdef MainScene
    const vec3 eye = vec3(13.0,2.0,3.0);
    const vec3 target = vec3(0.0,0.0,0.0);
    const vec3 background = vec3(0.70, 0.80, 1.00);
    const float distToFocus = 10.0;
    const float aperture = 0.1;
    float fovy =  20.0;  // + 100.0 * iMouse.y/iResolution.y;
#endif
#ifdef SimpleLight
    const vec3 eye = vec3(26.0,3.0,6.0);
    const vec3 target = vec3(0.0,2.0,0.0);
    const vec3 background = vec3(0.0, 0.0, 0.0);
//    const vec3 background = vec3(0.01, 0.01, 0.01);
//    const vec3 background = vec3(0.70, 0.80, 1.00);
    const float distToFocus = 10.0;
    const float aperture = 0.0;
    float fovy =  20.0;  // + 100.0 * iMouse.y/iResolution.y;
#endif                         //
#ifdef CornelBox
    const vec3 eye = vec3(278.0, 278.0, -800.0);
    const vec3 target = vec3(278.0, 278.0, 0.0);
    const vec3 background = vec3(0.0, 0.0, 0.0);
//    const vec3 background = vec3(0.01, 0.01, 0.01);
//    const vec3 background = vec3(0.70, 0.80, 1.00);
    const float distToFocus = 10.0;
    const float aperture = 0.0;
    float fovy =  40.0;
    numSamples = 200;
#else
    const vec3 eye = vec3(13.0,2.0,3.0);
    const vec3 target = vec3(0.0,0.0,0.0);
    const vec3 background = vec3(0.70, 0.80, 1.00);
    const float distToFocus = 10.0;
    const float aperture = 0.0;
    float fovy =  20.0;  // + 100.0 * iMouse.y/iResolution.y;
#endif
    
    Camera camera = computeCameraLookAt(eye, target, iResolution.x/iResolution.y, fovy, aperture, distToFocus, 0.0, 0.0);

    float invNumSamples = 1.0/float(numSamples);
    int i;
    vec3 col= vec3(0.0);
    for (i = 0; i < numSamples; i++) {
        vec2 offset = vec2(random(),random());
        Ray ray = getCameraRay(offset, camera);
        col += rayColor(ray, background);
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
