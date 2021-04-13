import EDSR
# import Preprocessing
import numpy as np
import matplotlib.pyplot as plt
import cv2 as cv
import tensorflow as tf
from tensorflow.keras import backend as K

# Daje procenat nula u matrici
def ZeroRate(M):
    
    return np.count_nonzero(M == 0) / (M.shape[0] * M.shape[1]) * 100.0


# Funkcija za prikaz i odredjivanje nula unutar matrice
def ZeroMarking(matrix, size = 8):
    
    nx = matrix.shape[0] // size
    ny = matrix.shape[1] // size
    O = np.ones((nx, ny)) * 255
    # O = np.ones((size, size)) * 255
    # Z = np.zeros((size, size))
    M = np.copy(matrix)
    print(M.shape)
    
    # print(nx, ny)
    
    for i in range(nx):
        for j in range(ny):
            
            x = i * size
            y = j * size
            
            if np.all(M[x : x + size, y : y + size] == 0):
                O[i, j] = 0
                # print(x, y)
                # M[x : x + size, y : y + size] = Z
            # else:
                # M[x : x + size, y : y + size] = O
    
    return O

batch = 32
epochs = 3
steps_per_epoch = 500
val_split = 0.2
boundries = [400, 800, 1000]
values = [1e-2, 7e-3, 1e-3, 5e-4]
num_filters = 64
num_res_block = 16
res_block_scaling = None
use_bias = True
separable_conv = False
scale = 4
input_shape = tuple([118, 124])

# put do tezina
wpath = '../weights/weights-edsr-16-x4-fine-tuned.h5'

# Kreira model
model = EDSR.EDSR(batch, num_filters, num_res_block, res_block_scaling,
            use_bias, separable_conv, scale, input_shape)

# ispisuje broj parametara po slojevima i ukupno
model.model.summary()

# Ucitava tezine u model
model.model.load_weights(wpath)

# testiranje modela sa slikama sa repozitorijuma
test_img_path1 = '../Koriscene slike za testove/test_image1.png'
test_img_path2 = '../Koriscene slike za testove/test_image2.png'
test_img_path3 = '../Koriscene slike za testove/test_image3.png'


# ucitavanje tih slika
test1 = cv.imread(test_img_path1)
test1 = cv.cvtColor(test1, cv.COLOR_BGR2RGB)
test2 = cv.imread(test_img_path2)
test2 = cv.cvtColor(test2, cv.COLOR_BGR2RGB)
test3 = cv.imread(test_img_path3)
test3 = cv.cvtColor(test3, cv.COLOR_BGR2RGB)

# prikaz na krupno samo jedne slike
model.display_image(test1.reshape(1, 118, 124, 3), 1, 1, (10, 10))

test_img = np.array([test1, test2, test3])


fig_size = (15, 15)
model.display_image(image = test_img, row = 3, col = 1, figsize = fig_size)

# rezultat koji daje model
result = model.model.predict(test_img)
# Podešavam da sve vrednosti budu u opsegu od 0 do 1,
# ali pre toga ogranicavam ih na 0 do 255
result[result > 255.0] = 255
result[result < 0] = 0
result /= 255.0

# prikaz rezultata rada modela
model.display_image(image = result, row = 3, col = 1, figsize = fig_size)

# proba sa nekim drugim slikama iz seta
new_img = []
for i in range(1, 4):
    path = '../DIV2K_valid_HR/DIV2K_valid_HR/0' + str(800 + i) + '.png'
    # print(path)
    temp = cv.imread(path)
    # print(type(temp))
    temp = cv.cvtColor(temp, cv.COLOR_BGR2RGB)
    new_img.append(cv.resize(temp, (temp.shape[1] // scale, temp.shape[0] // scale),
                              interpolation = cv.INTER_CUBIC))

new_img = np.asarray(new_img)
print(new_img.shape) # provera velicine

# prikaz slike
model.display_image(new_img, 3, 1, (10, 10))

temp = []
for img in new_img:
    cx, cy = img.shape[0] // 2, img.shape[1] // 2
    width = input_shape[0]
    height = input_shape[1]
    temp.append(img[cx - width // 2 : cx + width // 2,
                      cy - height // 2 : cy + height // 2,
                      :])
    
new_img = np.asarray(temp)    
print(new_img.shape) # provera velicine

# prikaz slike posle podesavanja velicine
model.display_image(new_img, 3, 1, (10, 10))

new_result = model.model.predict(new_img)
new_result[new_result > 255.0] = 255
new_result[new_result < 0] = 0
new_result /= 255.0
print(new_result.shape) # provera velicine

# prikaz rezultata modela
model.display_image(new_result, 3, 1, (10, 10)) # uspesno je istestiran model

# test modela na moju sliku
my_img = cv.imread('../Koriscene slike za testove/Moja_slika.jpg')
my_img = cv.cvtColor(my_img, cv.COLOR_BGR2RGB)
print(my_img.shape) # velicina slike
cx, cy = my_img.shape[0] // 2, my_img.shape[1] // 2
my_img = my_img[cx - width // 2 : cx + width // 2,
                cy - height // 2 : cy + height // 2,
                :]
print(my_img.shape)   
my_img = my_img.reshape(1, my_img.shape[0], my_img.shape[1], my_img.shape[2])
model.display_image(my_img, 1, 1, (5, 5))

new_result = model.model.predict(my_img)
new_result[new_result > 255.0] = 255
new_result[new_result < 0] = 0
new_result /= 255.0

model.display_image(new_result, 1, 1, (5, 5))

# vizualizacija tezina unutar mreze
weights = model.model.layers[2].weights
print(len(weights))

# Prikaz raspodele parametara
weights = model.model.layers[2].weights[0]
bias = model.model.layers[2].weights[1].numpy()
weights = tf.reshape(weights, [-1]).numpy()
param = np.concatenate((weights, bias), axis = 0)

n_bins = 100
fig, axs = plt.subplots(1, 1, sharey = True, tight_layout = True)
axs.hist(param, n_bins)


# test sa celom slikom
img = cv.imread('../Koriscene slike za testove/Proba.jpg')
img = cv.cvtColor(img, cv.COLOR_BGR2RGB)
img = cv.resize(img, (img.shape[1] // scale, img.shape[0] // scale),
                interpolation = cv.INTER_CUBIC)
rimg = img.reshape(1, img.shape[0], img.shape[1], img.shape[2])
model.display_image(rimg, 1, 1, (7, 7)) # prikaz nase slike


def chopImage(image, size):
    
    temp = []
    sx, sy = size[0], size[1]
    
    i, j = int(np.floor(image.shape[0] / sx)), int(np.floor(image.shape[1] / sy))
    print(i, j)
    
    for x in range(0, i):
        for y in range(0, j):
                
            xc = x * sx + sx // 2
            yc = y * sy + sy // 2
                
                
            chop_img = img[xc - sx // 2 : xc + sx // 2,
                           yc - sy // 2 : yc + sy // 2,
                               :]
                
            temp.append(chop_img)
    
    return np.asarray(temp)

test = chopImage(image = img, size = (118, 124))
model.display_image(test[0 : 8], 4, 2, (5, 5))

new_result = model.model.predict(test)
new_result[new_result > 255.0] = 255
new_result[new_result < 0] = 0
new_result /= 255.0

print(new_result.shape)
model.display_image(new_result[0 : 8], 4, 2, (5, 5))


# Dobijanje vrednosti OFM-ova razlicitih slojeva
# ovo je placeholder, njena vrednost ce biti odredjena kasnije,
# ali se moze koristiti i pre nego sto dobije tu vrenost 
# inp = tf.keras.Input
# uzecu samo vrednosti za 9. sloj
output_conv2D = model.model.layers[10].output
# outputs = [layer.output for layer in model.model.layers] # vrednosti svih slojeva     
functor = K.function([model.model.layers[0].input], [output_conv2D]) # ovo pravi funkciju 

# Testing
test = test_img[2].reshape(1, 118, 124, 3)
ofm = functor([test])[0]

# Stvaranje D matrice
ofm = ofm.reshape(118, 124, 64)
temp = np.zeros((ofm.shape[0] + 2, ofm.shape[1] + 2, ofm.shape[2]))
temp[1 : ofm.shape[0] + 1, 1 : ofm.shape[1] + 1, :] = ofm
D = np.zeros((ofm.shape[0] * ofm.shape[1], 3 * 3 * ofm.shape[2]))

i = 0
for y in range(1, ofm.shape[1] + 1):
    for x in range(1, ofm.shape[0] + 1):
        d = temp[x - 1 : x + 2, y - 1 : y + 2, :]
        d = d.reshape(-1)
        D[i, :] = d
        i += 1
            
# Provera koliko nula ima
D_marked = ZeroMarking(D, 4)
plt.imshow(D_marked, cmap = 'gray')
rate = ZeroRate(D)
rate_marked = ZeroRate(D_marked)
print('Procenat nula u D matrici je {}%'.format(rate))
print('Procenat nula u D_marked matrici je {}%'.format(rate_marked))

# Zakljucak: Slojevi sa neparnim indeksom imaju veliki procenat nula

# Provera udela nula u F matrici
Fp = model.model.layers[10].weights[0].numpy()
F = np.zeros((Fp.shape[3], Fp.shape[0] * Fp.shape[1] * Fp.shape[2]))

for i in range(Fp.shape[-1]):
    F[i, :] = Fp[:, :, :, i].reshape(-1)
    
F_marked = ZeroMarking(F)
rate = ZeroRate(F)
rate_marked = ZeroRate(F_marked)
print('Procenat nula u F matrici je {}%'.format(rate))
print('Procenat nula u F_marked matrici je {}%'.format(rate_marked))

# Prikaz raspodele
f = F.reshape(-1)
n_bins = 1000
fig, axs = plt.subplots(1, 1, sharey = True, tight_layout = True)
axs.hist(f, n_bins)

# Funkcija koja radi statistiku udela
# nula ulaza u svakom Conv2D sloju
def CalcZero(model, img):
    
    zero_rate = []
    
    outputs = []
    for layer in model.layers:
        keras_function = K.function([model.input], [layer.output])
        outputs.append(keras_function([img.reshape(1, 118, 124, 3), 1]))
    
    
    for i in range(len(outputs)):
        if str(model.layers[i]).find('Conv2D') != -1:
            zr = np.count_nonzero(outputs[i][0] == 0)
            total = outputs[i][0].shape[0] * outputs[i][0].shape[1] * outputs[i][0].shape[2] * outputs[i][0].shape[3]
            zr = zr / total * 100.0
            zero_rate.append((zr, 'layer ' + str(i)))

    return zero_rate


stat_my_img = CalcZero(model.model, my_img)
stat_test1 = CalcZero(model.model, test1)
stat_test2 = CalcZero(model.model, test2)
stat_test3 = CalcZero(model.model, test3)

# kn, kd, kw, kh
# upisvacu sve kernele

i = 0

for layer in model.model.layers:
    if str(layer).find('Conv2D') != -1:
        file = open('../Tezine/weights' + str(i) + '.txt', 'w') # treba 'w'
        lines = []
        for n in range(layer.weights[0].shape[-1]):
            f = layer.weights[0][:, :, :, n].numpy()
            fn = np.zeros((f.shape[0] * f.shape[1] * f.shape[2]))
            
            step = f.shape[0] * f.shape[1]
            for d in range(f.shape[-1]):
                fn[d * step : d * step + step] = f[:, :, d].reshape(-1)
                
            s = ''
            for val in fn:
                s += str(val) + ','
            s += '\n'
            lines.append(s)
            
        # print(len(lines))
        file.writelines(lines)
        i += 1
        file.close()
        

# file_name = 'EDSR_CPP\weights10.txt'
# file = open(file_name, 'r')
# lines = file.readlines()
# file.close()


# W = np.zeros((3, 3, 64, 64))
# for kn in range(64):
#     i = 0
#     # svaka linija je jedan filtar
#     val = lines[kn].split(',')
    
#     for kw in range(3):
#         for kh in range(3):
#             for kd in range(64):
                
#                 W[kw][kh][kd][kn] = float(val[i])
#                 i += 1
                
                