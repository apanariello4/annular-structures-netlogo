import glob
import os
import re
from math import sqrt
import statistics

rule = re.compile(r'[-+]?[0-9]*\.?[0-9]+\s+[-+]?[0-9]*\.?[0-9]+\n')
rule_name = re.compile(r'\d+')
file_list = sorted(glob.glob('./cci_coords/cci*.txt'))


def euclidean(x, y):
    return sqrt(x**2 + y**2)


def mean_distance(coordinates):
    distances = []
    for c in coordinates:
        distances.append(euclidean(c[0], c[1]))
    return statistics.mean(distances)


coord = []
for file in file_list:
    mean = 0
    name = os.path.basename(file)
    number = re.findall(rule_name, name)[0]

    with open(file, 'r') as f:
        data = list(map(str.rstrip, re.findall(rule, f.read())))

        for t in data:
            coord.append(tuple(map(float, (re.split(r'\s+', t)))))
        mean = mean_distance(coord)
    print(f'file: {name}, mean: {mean}')
    with open(f'./mean/{number}.txt', 'w') as w:
        w.write(str(mean))
