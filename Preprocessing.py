import cv2 as cv
import numpy as np
import os
from imagedegrade import np as degrade

# Ucitava slike iz odredjenog direktorijuma
def Load_img(path, num):
    
    image = []
    count = 0
    
    for file in os.listdir(path):
        
        if num is not None:
            count += 1
        
        temp = cv.imread(path + '/' + file)
        temp = cv.cvtColor(temp, cv.COLOR_BGR2RGB)
        image.append(temp)
        
        if count == num:
            return np.asarray(image)
        
    return np.asarray(image)

# Pronalazi najmanju dimenziju od svih slika
def minSize(image):
    
    min_size = 3000
    
    for img in image:
        
        shp = img.shape
        shp = shp[: -1]
        
        min_size = min(shp[0], shp[1], min_size)
                
    return min_size                
                
# izbacuje slike cija je manja dimenzija manja od specificirane
def filterSize(image, t_size):
    
    temp = []
    
    for img in image:
    
        min_size = min(img.shape[0], img.shape[1])
        if(min_size >=  t_size):
            temp.append(img)
    
    return np.asarray(temp)

# Odseca visak slike tako da obe dimenzije budu iste
def squareImage(image, size):
    
    temp = []
    
    for img in image:
        
        center = (int(img.shape[0]/2), int(img.shape[1]/2))
        
        cut_img = img[center[0] - int(size/2) : center[0] + int(size/2), 
                      center[1] - int(size/2) : center[1] + int(size/2),
                      :]
        temp.append(cut_img)
    
    return np.asarray(temp)
        
# Sece sve slike na delove velicine size*size
def chopImage(image, size):
    
    temp = []

    n = int(image.shape[1]/size)
    
    for img in image:
        
        for x in range(0, n):
            for y in range(0, n):
                
                xc = x * size + size // 2
                yc = y * size + size // 2
                
                
                chop_img = img[xc - size // 2 : xc + size // 2,
                               yc - size // 2 : yc + size // 2,
                               :]
                
                temp.append(chop_img)
    
    return np.asarray(temp)

# Vrsi promenu dimenzija slike sa naznacenim skaliranjem i interpolacijom(metodom sklairanja)
def resizeImage(image, scale, amount, interpolation):
        
    
    w = int(image[0].shape[0]*scale)
    h = int(image[0].shape[1]*scale)
    dim = (w, h)
    temp = []
    
    for i in range(amount):
        temp.append(cv.resize(image[i], dim, interpolation = interpolation))
    
    return np.asarray(temp, 'uint8')
    
# Radi Gausov blur za svaku sliku
def Gaussian(image, kernle_size, sigmaX):
    
    temp = []
    size = (kernle_size, kernle_size)
    
    for img in image:
        
        temp.append(cv.GaussianBlur(src = img, ksize = size, sigmaX = sigmaX))
        
    return np.asarray(temp)

# Dodaje svakoj slici Gausov sum
def gaussNoise(image, mean, std):
    
    temp = []
    
    for img in image:
        
        gauss = np.random.normal(mean, std, img.shape)
        gauss = gauss.reshape(img.shape[0],img.shape[1],img.shape[2]).astype('uint8')
        gauss = gauss + img
        temp.append(gauss)
    
    return np.asarray(temp)

# Dodaje svakoj slici speckle sum
def speckleNoise(image, mean, std):
    
    temp = []
    
    for img in image:
    
        gauss = np.random.normal(mean, std, img.size)
        gauss = gauss.reshape(img.shape[0],img.shape[1],img.shape[2]).astype('uint8')
        noise = img + img * gauss
        
        temp.append(noise)
    
    return np.asarray(temp)

# Degradira svaku sliku pomocu jpeg degradacije
def jpegDegrade(image, jpeg_quality, subsampling):
    
    temp = []
    
    for img in image:
        
        temp.append(degrade.jpeg(img, jpeg_quality = jpeg_quality, subsampling = subsampling))
        
    return np.asarray(temp)

def calcMean(image):
    
    r = 0 
    g = 0
    b = 0
    n = image.shape[0]
    s = image.shape[1]
    
    for img in image:
        
        r += img[ :, :, 0].sum()
        g += img[ :, :, 1].sum()
        b += img[ :, :, 2].sum()
        
    return np.asarray([r, g, b]) / ((s ** 2) * n)