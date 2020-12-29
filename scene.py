#!/usr/bin/env python3

import math
import random

def createItem(pos0, pos1, radius, material):
    print("Item( vec4({},{},{},{}), vec4({},{},{},{}), vec4({},{},{},{}), {} ),".format(
          pos0[0],pos0[1],pos0[2], pos0[3],
          pos1[0],pos1[1],pos1[2], pos1[3],
          material[0],material[1],material[2], material[3],
          radius))

def length(pos0, pos1):
    a = pos1[0]-pos0[0];
    b = pos1[1]-pos0[1];
    c = pos1[2]-pos0[2];
    return math.sqrt(a*a + b*b + c*c)
    
def main():
    maxSphere = 50
    currentIndex = 0

    materialLambert = 0.0
    materialMetal = 0.001
    materialRefrac = 1.5

    # ground
    createItem([0.0,-1000,-1.0, 0.0], [0.0,-1000,-1.0, 0.0], 1000.0, [0.5,0.5,0.5, materialLambert]);
    currentIndex+=1

    random.seed(1)
    step = 2
    for a in range(-11,11, step):
        for b in range(-11,11, step):
            random0 = random.random();
            random1 = random.random();
            random2 = random.random();

            center = [ float(a) + 0.9*random0, 0.2, float(b) + 0.9*random1]
            d = length([4, 0.2, 0], center)
            if d > 0.9 :
                center0 = [center[0], center[1], center[2], 0.0]
                center1 = center0
                radius = 0.2

                if random0 < 0.8:
                    material = [random0*random0, random1*random1, random2*random2, materialLambert]
                    center1 = [center0[0], center[1] + random0, center[2], 1.0]
                elif random0 < 0.95:
                    material = [random0*0.5+0.5, random1*0.5+0.5, random2*0.5+0.5, random1*0.49 + 0.01]
                else:
                    material = [1.5, 1.5, 1.5, 1.5]

                createItem(center0, center1, radius, material)
                currentIndex += 1

    createItem([0.0, 1.0, 0.0, 0.0], [0.0, 1.0, 0.0, 0.0], 1.0, [0.0, 0.0, 0.0, materialRefrac])
    currentIndex += 1

    createItem([-4.0, 1.0, 0.0, 0.0], [-4.0, 1.0, 0.0, 0.0], 1.0, [0.4, 0.2, 0.1, materialLambert])
    currentIndex += 1

    createItem([4.0, 1.0, 0.0, 0.0], [4.0, 1.0, 0.0, 0.0], 1.0, [0.7, 0.6, 0.5, materialMetal])
    currentIndex += 1
                
    print("#define MaxElement {}".format(currentIndex))

if __name__ == "__main__":
    main()
