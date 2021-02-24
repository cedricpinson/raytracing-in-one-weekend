#!/usr/bin/env python3

import math
import random
import sys
from dataclasses import dataclass

dump_bvh = True


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


def createAABBFromBox(center, size):
    return AABB(
        (
            center[0] - size[0] * 0.5,
            center[1] - size[1] * 0.5,
            center[2] - size[2] * 0.5,
        ),
        (
            center[0] + size[0] * 0.5,
            center[1] + size[1] * 0.5,
            center[2] + size[2] * 0.5,
        ),
    )


def createAABBFromRectXY(pos0, pos1, k):
    return AABB(
        (pos0[0], pos0[1], k - 0.001),
        (pos1[0], pos1[1], k + 0.001),
    )


def createAABBFromRectXZ(pos0, pos1, k):
    return AABB(
        (pos0[0], k - 0.001, pos0[1]),
        (pos1[0], k + 0.001, pos1[1]),
    )


def createAABBFromRectYZ(pos0, pos1, k):
    return AABB(
        (k - 0.001, pos0[0], pos0[1]),
        (k + 0.001, pos1[0], pos1[1]),
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
    def __init__(self):
        pass

    def register(self):
        global ItemIndex
        self.index = ItemIndex
        ItemIndex += 1

    def createSphere(self, pos, radius, material):
        self.position = pos[:]
        self.radius = radius
        self.material = material
        self.shape_type = "SHAPE_SPHERE"

        self.aabb = createAABBFromSphere(pos, radius)
        self.register()

    def createRectXY(self, pos0, pos1, k, material):
        self.position0 = pos0[:]
        self.position1 = pos1[:]
        self.k = k
        self.material = material
        self.shape_type = "SHAPE_RECT_XY"

        self.aabb = createAABBFromRectXY(pos0, pos1, k)
        self.register()

    def createRectXZ(self, pos0, pos1, k, material):
        self.createRectXY(pos0, pos1, k, material)
        self.aabb = createAABBFromRectXZ(pos0, pos1, k)
        self.shape_type = "SHAPE_RECT_XZ"

    def createRectYZ(self, pos0, pos1, k, material):
        self.createRectXY(pos0, pos1, k, material)
        self.aabb = createAABBFromRectYZ(pos0, pos1, k)
        self.shape_type = "SHAPE_RECT_YZ"

    def createBox(self, pos, size, material):
        self.position = pos[:]
        self.size = size[:]
        self.material = material
        self.shape_type = "SHAPE_BOX"

        self.aabb = createAABBFromBox(pos, size)
        self.register()

    def toString(self, endline=False):
        if self.shape_type == "SHAPE_SPHERE":
            print(
                "Item(vec3({},{},{}), int({}), vec4({},{},{},{}), vec4({},{},{},{})){}".format(
                    self.position[0],
                    self.position[1],
                    self.position[2],
                    self.shape_type,
                    self.radius,
                    0.0,
                    0.0,
                    0.0,
                    self.material[0],
                    self.material[1],
                    self.material[2],
                    self.material[3],
                    "" if endline is True else ",",
                )
            )
        elif (
            self.shape_type == "SHAPE_RECT_XY"
            or self.shape_type == "SHAPE_RECT_XZ"
            or self.shape_type == "SHAPE_RECT_YZ"
        ):
            print(
                "Item(vec3({},{},{}), int({}), vec4({},{},{},{}), vec4({},{},{},{})){}".format(
                    self.position0[0],
                    self.position0[1],
                    0.0,
                    self.shape_type,
                    self.position1[0],
                    self.position1[1],
                    self.k,
                    0.0,
                    self.material[0],
                    self.material[1],
                    self.material[2],
                    self.material[3],
                    "" if endline is True else ",",
                )
            )
        elif self.shape_type == "SHAPE_BOX":
            print(
                "Item(vec3({},{},{}), int({}), vec4({},{},{},{}), vec4({},{},{},{})){}".format(
                    self.position[0],
                    self.position[1],
                    self.position[2],
                    self.shape_type,
                    self.size[0],
                    self.size[1],
                    self.size[2],
                    0.0,
                    self.material[0],
                    self.material[1],
                    self.material[2],
                    self.material[3],
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


def createRectXY(pos0, pos1, k, material):
    item = Item()
    item.createRectXY(pos0, pos1, k, material)
    return item


def createRectXZ(pos0, pos1, k, material):
    item = Item()
    item.createRectXZ(pos0, pos1, k, material)
    return item


def createRectYZ(pos0, pos1, k, material):
    item = Item()
    item.createRectYZ(pos0, pos1, k, material)
    return item


def createSphere(pos, radius, material):
    item = Item()
    item.createSphere(pos, radius, material)
    return item


def createBox(pos, size, material):
    item = Item()
    item.createBox(pos, size, material)
    return item


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
MaterialLight = 30.0 + 0.5


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
        createSphere(
            [0.0, -1000, -1.0],
            1000.0,
            (0.5, 0.5, 0.5, MaterialLambertCheckboard),
        )
    )

    objectList.append(
        createSphere(
            [0.0, 1.0, 0.0],
            1.0,
            (0.0, 0.0, 0.0, MaterialRefrac),
        )
    )
    objectList.append(
        createSphere(
            [-4.0, 1.0, 0.0],
            1.0,
            (0.4, 0.2, 0.1, MaterialLambert),
        )
    )
    objectList.append(
        createSphere(
            [4.0, 1.0, 0.0],
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
                radius = 0.2

                if random0 < 0.8:
                    material = (
                        random0 * random0,
                        random1 * random1,
                        random2 * random2,
                        MaterialLambert,
                    )
                elif random0 < 0.95:
                    material = (
                        random0 * 0.5 + 0.5,
                        random1 * 0.5 + 0.5,
                        random2 * 0.5 + 0.5,
                        random1 * 0.49 + MaterialMetal,
                    )
                else:
                    material = (1.5, 1.5, 1.5, MaterialRefrac)

                objectList.append(createSphere(center, radius, material))

    #
    print("#define NumItems {}".format(len(objectList)))
    print("Item Items[NumItems] = Item[NumItems](")
    printArray(objectList)
    print(");")

    createBVH(objectList)

    global dump_bvh
    if dump_bvh:
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
        createSphere(
            [0.0, -10.0, 0.0],
            10.0,
            (0.4, 0.2, 0.1, MaterialLambertCheckboard),
        )
    )

    objectList.append(
        createSphere(
            [0.0, 10.0, 0.0],
            10.0,
            (0.4, 0.2, 0.1, MaterialLambertCheckboard),
        )
    )

    print("#define NumItems {}".format(len(objectList)))
    print("Item Items[NumItems] = Item[NumItems](")
    printArray(objectList)
    print(");")

    createBVH(objectList)

    global dump_bvh
    if dump_bvh:
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
        createSphere(
            [0.0, -1000.0, 0.0],
            1000.0,
            (0.4, 0.2, 0.1, MaterialLambertPerlin),
        )
    )

    objectList.append(
        createSphere(
            [0.0, 2.0, 0.0],
            2.0,
            (0.4, 0.2, 0.1, MaterialLambertPerlin),
        )
    )

    print("#define NumItems {}".format(len(objectList)))
    print("Item Items[NumItems] = Item[NumItems](")
    printArray(objectList)
    print(");")

    createBVH(objectList)

    global dump_bvh
    if dump_bvh:
        print("#define NumNodes {}".format(len(NodeBVHList)))
        print("BVH Nodes[NumNodes] = BVH[NumNodes](")
        printArray(NodeBVHList)
        print(");")


def simpleLightScene():
    global NodeBVHList
    NodeBVHList = []
    global ItemIndex
    ItemIndex = 0

    objectList = []
    objectList.append(
        createSphere(
            [0.0, -1000.0, 0.0],
            1000.0,
            (0.4, 0.2, 0.1, MaterialLambertPerlin),
        )
    )

    objectList.append(
        createSphere(
            [0.0, 2.0, 0.0],
            2.0,
            (0.4, 0.2, 0.1, MaterialLambertPerlin),
        )
    )

    objectList.append(
        createRectXY(
            [3.0, 1.0],
            [5.0, 3.0],
            -2.0,
            (4.0, 4.0, 4.0, MaterialLight),
        )
    )

    print("#define NumItems {}".format(len(objectList)))
    print("Item Items[NumItems] = Item[NumItems](")
    printArray(objectList)
    print(");")

    createBVH(objectList)

    global dump_bvh
    if dump_bvh:
        print("#define NumNodes {}".format(len(NodeBVHList)))
        print("BVH Nodes[NumNodes] = BVH[NumNodes](")
        printArray(NodeBVHList)
        print(");")


def createBox(pos0, pos1, material):
    objectList = []

    objectList.append(
        createRectXY(
            [pos0[0], pos0[1]],
            [pos1[0], pos1[1]],
            pos1[2],
            material,
        )
    )

    objectList.append(
        createRectXY(
            [pos0[0], pos0[1]],
            [pos1[0], pos1[1]],
            pos0[2],
            material,
        )
    )

    objectList.append(
        createRectXZ(
            [pos0[0], pos0[2]],
            [pos1[0], pos1[2]],
            pos1[1],
            material,
        )
    )

    objectList.append(
        createRectXZ(
            [pos0[0], pos0[2]],
            [pos1[0], pos1[2]],
            pos0[1],
            material,
        )
    )

    objectList.append(
        createRectYZ(
            [pos0[1], pos0[2]],
            [pos1[1], pos1[2]],
            pos0[0],
            material,
        )
    )

    objectList.append(
        createRectYZ(
            [pos0[1], pos0[2]],
            [pos1[1], pos1[2]],
            pos1[0],
            material,
        )
    )

    return objectList


def cornelBoxScene():
    global NodeBVHList
    NodeBVHList = []
    global ItemIndex
    ItemIndex = 0

    red = (0.65, 0.05, 0.05, MaterialLambert)
    green = (0.12, 0.45, 0.15, MaterialLambert)
    white = (0.73, 0.73, 0.73, MaterialLambert)

    objectList = []
    objectList.append(
        createRectYZ(
            [0.0, 0.0],
            [555.0, 555.0],
            555.0,
            green,
        )
    )

    objectList.append(
        createRectYZ(
            [0.0, 0.0],
            [555.0, 555.0],
            0.0,
            red,
        )
    )

    objectList.append(
        createRectXZ(
            [213.0, 227.0],
            [343.0, 332.0],
            554.0,
            (15.0, 15.0, 15.0, MaterialLight),
        )
    )

    objectList.append(
        createRectXZ(
            [0.0, 0.0],
            [555.0, 555.0],
            0.0,
            white,
        )
    )

    objectList.append(
        createRectXZ(
            [0.0, 0.0],
            [555.0, 555.0],
            555.0,
            white,
        )
    )

    objectList.append(
        createRectXY(
            [0.0, 0.0],
            [555.0, 555.0],
            555.0,
            white,
        )
    )

    objectList.extend(createBox([130.0, 0.0, 65.0], [295.0, 165.0, 230.0], white))
    objectList.extend(createBox([265.0, 0.0, 295.0], [430.0, 330.0, 460.0], white))

    print("#define NumItems {}".format(len(objectList)))
    print("Item Items[NumItems] = Item[NumItems](")
    printArray(objectList)
    print(");")

    createBVH(objectList)

    global dump_bvh
    if dump_bvh:
        print("#define NumNodes {}".format(len(NodeBVHList)))
        print("BVH Nodes[NumNodes] = BVH[NumNodes](")
        printArray(NodeBVHList)
        print(");")


def main():
    global dump_bvh
    if len(sys.argv) > 0:
        dump_bvh = False if sys.argv[1] == "--no-bvh" else True

    print("//#define MainScene")
    print("//#define SimpleScene")
    print("//#define TwoSpherePerlin")
    print("//#define SimpleLight")
    print("#define CornelBox")
    print("#ifdef MainScene")
    createMainScene()
    print("#endif")
    print("#ifdef SimpleScene")
    simpleScene()
    print("#endif")
    print("#ifdef TwoSpherePerlin")
    simpleTwoSphereScene()
    print("#endif")
    print("#ifdef SimpleLight")
    simpleLightScene()
    print("#endif")
    print("#ifdef CornelBox")
    cornelBoxScene()
    print("#endif")


if __name__ == "__main__":
    main()
