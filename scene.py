#!/usr/bin/env python3

import math
import random
from dataclasses import dataclass


@dataclass
class AABB:
    min: ()
    max: ()


# bvh
# bvhNode: min(vec3),max(vec3), vec2i(left,right)
#
def createAABBFromSphere(center, radius):
    return AABB(
        (center[0] - radius, center[1] - radius, center[2] - radius),
        (center[0] + radius, center[1] + radius, center[2] + radius),
    )


def extendAABB(aabb0, aabb1):
    minv = (
        min(aabb0.min[0], aabb1.min[0]),
        min(aabb0.min[1], aabb1.min[1]),
        min(aabb0.min[2], aabb1.min[2]),
    )
    maxv = (
        max(aabb0.max[0], aabb1.max[0]),
        max(aabb0.max[1], aabb1.max[1]),
        max(aabb0.max[2], aabb1.max[2]),
    )
    return AABB(minv, maxv)


ItemIndex = 0


class Item:
    def __init__(self, pos0, pos1, radius, material):
        self.center0 = pos0[:3]
        self.center1 = pos1[:3]
        self.t0 = pos0[3]
        self.t1 = pos1[3]
        self.radius = radius
        self.material = material
        self.aabb = self.createAABB()

        global ItemIndex
        self.index = ItemIndex
        ItemIndex += 1

    def createAABB(self):
        aabb0 = createAABBFromSphere(self.center0, self.radius)
        if self.t0 == self.t1:
            return aabb0

        aabb1 = createAABBFromSphere(self.center1, self.radius)
        return extendAABB(aabb0, aabb1)

    def toString(self, endline=False):
        print(
            "Item(vec4({},{},{},{}), vec4({},{},{},{}), vec4({},{},{},{}), {} ){}".format(
                self.center0[0],
                self.center0[1],
                self.center0[2],
                self.t0,
                self.center1[0],
                self.center1[1],
                self.center1[2],
                self.t1,
                self.material[0],
                self.material[1],
                self.material[2],
                self.material[3],
                self.radius,
                "" if endline is True else ",",
            )
        )


NodeBVHList = []


class NodeBVH:
    def __init__(self, objectList, start, end, t0, t1):
        self.left = None
        self.right = None
        self.aabb = None
        self.items = []

        global NodeBVHList
        self.index = len(NodeBVHList)
        NodeBVHList.append(self)

        axis = random.randint(0, 2)
        numItems = end - start

        # https://docs.python.org/3/howto/sorting.html#sortinghowto
        comparator = lambda item: item.aabb.min[axis]

        if numItems == 1:
            self.items.append(objectList[start])
            self.aabb = objectList[start].aabb
        else:
            newList = sorted(objectList[start:end], key=comparator)
            mid = int(numItems / 2)
            self.left = NodeBVH(newList, 0, mid, t0, t1)
            self.right = NodeBVH(newList, mid, numItems, t0, t1)
            self.aabb = extendAABB(self.left.aabb, self.right.aabb)

    def dump(self):
        if self.left or self.right:
            print(
                "node: {} # left: {} right: {}".format(
                    self.index, self.left.index, self.right.index
                )
            )
        else:
            print("node: {} # item {}".format(self.index, self.items[0].index))

    def toString(self, endline=False):
        print(
            "BVH( vec3({},{},{}), vec3({},{},{}), ivec2({},{})){}".format(
                self.aabb.min[0],
                self.aabb.min[1],
                self.aabb.min[2],
                self.aabb.max[0],
                self.aabb.max[1],
                self.aabb.max[2],
                -1 if self.left == None else self.left.index,
                self.items[0].index if self.left == None else self.right.index,
                "" if endline is True else ",",
            )
        )

    def count(self):
        numNodes = 1
        if self.left:
            numNodes += self.left.count()
        if self.right:
            numNodes += self.right.count()
        return numNodes


def createBVH(objectList):
    bvh = NodeBVH(objectList, 0, len(objectList), 0, 1)
    # bvh.dump()
    # print("numNodes {}".format(bvh.count()))


def createItem(pos0, pos1, radius, material):
    return Item(pos0, pos1, radius, material)


def length(pos0, pos1):
    a = pos1[0] - pos0[0]
    b = pos1[1] - pos0[1]
    c = pos1[2] - pos0[2]
    return math.sqrt(a * a + b * b + c * c)


MaterialLambert = 0.0
MaterialLambertCheckboard = MaterialLambert + 1.0
MaterialLambertPerlin = MaterialLambert + 2.0
MaterialMetal = 10.0
MaterialRefrac = 20.0 + 1.5


def printArray(array):
    for item in array[:-1]:
        item.toString()
    array[-1].toString(True)


def createMainScene():
    global NodeBVHList
    NodeBVHList = []
    global ItemIndex
    ItemIndex = 0

    objectList = []
    # ground
    objectList.append(
        createItem(
            [0.0, -1000, -1.0, 0.0],
            [0.0, -1000, -1.0, 0.0],
            1000.0,
            (0.5, 0.5, 0.5, MaterialLambertCheckboard),
        )
    )

    objectList.append(
        createItem(
            [0.0, 1.0, 0.0, 0.0],
            [0.0, 1.0, 0.0, 0.0],
            1.0,
            (0.0, 0.0, 0.0, MaterialRefrac),
        )
    )
    objectList.append(
        createItem(
            [-4.0, 1.0, 0.0, 0.0],
            [-4.0, 1.0, 0.0, 0.0],
            1.0,
            (0.4, 0.2, 0.1, MaterialLambert),
        )
    )
    objectList.append(
        createItem(
            [4.0, 1.0, 0.0, 0.0],
            [4.0, 1.0, 0.0, 0.0],
            1.0,
            (0.7, 0.6, 0.5, MaterialMetal),
        )
    )

    random.seed(1)
    step = 2
    for a in range(-11, 11, step):
        for b in range(-11, 11, step):
            random0 = random.random()
            random1 = random.random()
            random2 = random.random()

            center = [float(a) + 0.9 * random0, 0.2, float(b) + 0.9 * random1]
            d = length([4, 0.2, 0], center)
            if d > 0.9:
                center0 = [center[0], center[1], center[2], 0.0]
                center1 = center0
                radius = 0.2

                if random0 < 0.8:
                    material = (
                        random0 * random0,
                        random1 * random1,
                        random2 * random2,
                        MaterialLambert,
                    )
                    center1 = [center0[0], center[1] + random0, center[2], 1.0]
                elif random0 < 0.95:
                    material = (
                        random0 * 0.5 + 0.5,
                        random1 * 0.5 + 0.5,
                        random2 * 0.5 + 0.5,
                        random1 * 0.49 + MaterialMetal,
                    )
                else:
                    material = (1.5, 1.5, 1.5, MaterialRefrac)

                objectList.append(createItem(center0, center1, radius, material))

    #
    print("#define NumItems {}".format(len(objectList)))
    print("Item Items[NumItems] = Item[NumItems](")
    printArray(objectList)
    print(");")

    createBVH(objectList)

    print("#define NumNodes {}".format(len(NodeBVHList)))
    print("BVH Nodes[NumNodes] = BVH[NumNodes](")
    printArray(NodeBVHList)
    print(");")


def simpleScene():
    global NodeBVHList
    NodeBVHList = []
    global ItemIndex
    ItemIndex = 0

    objectList = []
    objectList.append(
        createItem(
            [0.0, -10.0, 0.0, 0.0],
            [0.0, -10.0, 0.0, 0.0],
            10.0,
            (0.4, 0.2, 0.1, MaterialLambertCheckboard),
        )
    )

    objectList.append(
        createItem(
            [0.0, 10.0, 0.0, 0.0],
            [0.0, 10.0, 0.0, 0.0],
            10.0,
            (0.4, 0.2, 0.1, MaterialLambertCheckboard),
        )
    )

    print("#define NumItems {}".format(len(objectList)))
    print("Item Items[NumItems] = Item[NumItems](")
    printArray(objectList)
    print(");")

    createBVH(objectList)

    print("#define NumNodes {}".format(len(NodeBVHList)))
    print("BVH Nodes[NumNodes] = BVH[NumNodes](")
    printArray(NodeBVHList)
    print(");")


def simpleTwoSphereScene():
    global NodeBVHList
    NodeBVHList = []
    global ItemIndex
    ItemIndex = 0

    objectList = []
    objectList.append(
        createItem(
            [0.0, -1000.0, 0.0, 0.0],
            [0.0, -1000.0, 0.0, 0.0],
            1000.0,
            (0.4, 0.2, 0.1, MaterialLambertPerlin),
        )
    )

    objectList.append(
        createItem(
            [0.0, 2.0, 0.0, 0.0],
            [0.0, 2.0, 0.0, 0.0],
            2.0,
            (0.4, 0.2, 0.1, MaterialLambertPerlin),
        )
    )

    print("#define NumItems {}".format(len(objectList)))
    print("Item Items[NumItems] = Item[NumItems](")
    printArray(objectList)
    print(");")

    createBVH(objectList)

    print("#define NumNodes {}".format(len(NodeBVHList)))
    print("BVH Nodes[NumNodes] = BVH[NumNodes](")
    printArray(NodeBVHList)
    print(");")


def main():
    print("#define MainScene")
    print("//#define SimpleScene")
    print("//#define TwoSpherePerlin")
    print("#ifdef MainScene")
    createMainScene()
    print("#endif")
    print("#ifdef SimpleScene")
    simpleScene()
    print("#endif")
    print("#ifdef TwoSpherePerlin")
    simpleTwoSphereScene()
    print("#endif")


if __name__ == "__main__":
    main()
