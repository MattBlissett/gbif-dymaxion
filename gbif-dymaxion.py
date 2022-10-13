#!/usr/bin/env python3
#-*- coding: utf-8 -*-
'''
GBIF Occurrences in Dymaxion Projection

Mostly copied from https://github.com/Teque5/pydymax/blob/master/dymax/examples.py

CC-BY-NC-SA license: https://github.com/Teque5/pydymax/blob/master/LICENSE
'''
import time
from sys import stdout
from sys import argv
import sys
import numpy as np
import matplotlib.pyplot as plt
from PIL import Image, ImageOps

from dymax import convert
from dymax import constants
from dymax import io

def convert_rectimage_2_dymaximage(input_img_path, output_img_path, verbose=True, scale=300, unfolding=constants.Unfolding.NET, speedup=1, save=False, show=True):
    '''
    Convert rectilinear image to dymax projection image.

    scale is number of pixels per dymax xy unit.
    How to calculate output scale:
        width = 160 # in cm
        resolution = 30 # in px/cm
        scale = (width * resolution) / 5.5
        __OR__
        final_size_in_pixels = (scale * 5.5, scale * 2.6)

    speedup gives a sparse preview of the output image and is specified as a
    time divisor.
    '''
    start = time.time()
    im = Image.open(input_img_path) #Can be many different formats. #15 vertical and horizontal pixels per degree
    pix = im.load()
    if verbose: print(':: input image resolution =', im.size) # Get the width and hight of the image for iterating over

    ### LongLat2Dymax returns x = (0,5.5) and y=(0,2.6)
    dymax_xsize, dymax_ysize = int(5.5*scale), int(2.6*scale)
    dymaximg = Image.new('RGBA', (dymax_xsize, dymax_ysize), (255, 0, 0, 0)) # create a new transparent
    if verbose: print(':: output image resolution =', (dymax_xsize, dymax_ysize)) # Get the width and hight of the image for iterating over

    ### X and Y are indexed from topleft to bottom right
    if verbose: print(':: sweeping over Longitudes:')
    xsize, ysize = im.size
    for i, lon in enumerate(np.linspace(-180, 180, xsize/speedup, endpoint=True)):
        i *= speedup
        if i % 20 == 0:
            print('{:+07.2f} '.format(lon), end='')
            stdout.flush() # I would add flush=True to print, but thats only in python3.3+
        for j, lat in enumerate(np.linspace(90, -90, ysize/speedup, endpoint=True)):
            j *= speedup
            newx, newy = convert.lonlat2dymax(lon, lat, unfolding=unfolding)
            newx = int(newx*scale) - 1
            newy = int(newy*scale)
            try: dymaximg.putpixel((newx, newy), pix[i, j])
            # Sometimes a point won't map to an edge properly
            except IndexError: print('{{{:d}, {:d}}}'.format(newx, newy), end='')
    if verbose: print()
    dymaximg = ImageOps.flip(dymaximg) #it's upside down since putpixel flips too

    numpoints = im.size[0] * im.size[1] // speedup
    if verbose: print(':: mapped {:d} points to dymax projection @ {:.1f} pts/sec [{:.1f} secs total]'.format(numpoints, numpoints/(time.time()-start), time.time()-start))
    plt.figure(figsize=(20, 12), frameon=False)
    plt.gca().axis('off')
    if save: dymaximg.save(output_img_path, format='PNG')
    if show:
        plt.tight_layout()
        plt.imshow(dymaximg)
        plt.show()
    else: plt.close()

def run_examples(unfolding=constants.Unfolding.NET):
    '''
    Generate a Dymaxion image.
    '''
    if len(sys.argv) != 3:
        print('Usage: ', sys.argv[0], ' source dest')
        exit(1)

    print('>> Generating Dymax Projection from ', sys.argv[1], ' to ', sys.argv[2])
    convert_rectimage_2_dymaximage(sys.argv[1], sys.argv[2], save=True, unfolding=unfolding)

if __name__ == '__main__':
    run_examples()
