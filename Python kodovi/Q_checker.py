import cv2 as cv
import numpy as np
import matplotlib.pyplot as plt
import os
from math import log10, sqrt

# Ucitiva i transformise sliku it txt fajla u numpy niz
def ReadResulat(path, shape):
    
    # Ucitavanje rezultata iz c++ koda
    cpp_out = np.zeros(shape)
    file = open(path, 'r')
    lines = file.readlines()
    for i, line in enumerate(lines):
            line = line.split(',')
            del line[-1]
            val = [float(l) for l in line]
            val = np.array(val)
            cpp_out[:, :, i] = val.reshape((cpp_out.shape[0], cpp_out.shape[1]))
    
    file.close()
    
    return cpp_out

#  Prikazuje slike
def display_image(image, row, col, figsize):
        
    fig = plt.figure(figsize = figsize)
        
    for i, img in enumerate(image):
            
        fig.add_subplot(row, col, i + 1)
        plt.imshow(img)
        
# Ucitava sve slike iz nekog foldera
def Load_img_from_txt(path):
    
    file_list = os.listdir(path)
    l = []

    for file in file_list:
        
        f = path + '/' + file
        temp = ReadResulat(path = f, shape = (472, 496, 3))
        l.append(temp.clip(0, 255) / 255.0)
        
    return np.array(l)

# Racuna peak odnosa signala i sum, treba da bude sto vece
def PSNR(original, quantized):
    mse = np.mean((original - quantized) ** 2)
    if(mse == 0):
        return 100
    max_pixel = 255.0
    psnr = 20 * log10(max_pixel / sqrt(mse))
    return psnr

def WritePNSR(path, original, imgs):
    
    lines = []
    file = open(path, 'w')
    
    for i, img in enumerate(imgs):
        
        psnr = PSNR(original, img)
        string = 'Vrednsot PSNR-a je: ' + str(psnr) + '\n'
        lines.append(string)
        
    file.writelines(lines)
    file.close
        
# -------------------------------------------------------

path_Q = '../Upsampling-project/C++ bitska analiza - kod/Input1_Q_results'
img_q_input1 = Load_img_from_txt(path_Q)

display_image(img_q_input1, img_q_input1.shape[0], 1 , (5, 5))

path_original = '../Output data'
img_list = os.listdir(path_original)

# Ucitavanje originalnih slika
temp = []
for i in img_list:
    
    img = cv.imread(path_original + '/' + i)
    img = cv.cvtColor(img, cv.COLOR_BGR2RGB)
    temp.append(img)

img_original = np.array(temp)
WritePNSR('../Razni tekst fajlovi/input1_psnr.txt', img_original[0], img_q_input1)

# display_image(img_original, 6, 1, (7, 7))



    

    
    
