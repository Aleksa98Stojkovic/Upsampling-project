from tensorflow.keras.layers import Conv2D, Input
import numpy as np
from tensorflow.keras.models import Model

test = np.random.rand(118, 124, 64)

x_in = Input(shape = (test.shape[0], test.shape[1], 64))
x_out = Conv2D(64, 3, padding = 'same', use_bias = False)(x_in)
model = Model(x_in, x_out)

W = model.layers[1].weights[0].numpy()


# Upisivanje ulaza u txt fajl
file = open('../EDSR_CPP/test_input.txt', 'w')
v = np.zeros((test.shape[0] * test.shape[1] * test.shape[2])).astype('float32')
for c in range(test.shape[-1]):
    step = v.shape[0] // test.shape[2]
    v[c * step : c * step + step] = test[:, :, c].reshape(-1)
    
s = ''
for val in v:
    s += str(val) + ','
s += '\n'

file.writelines(s)
file.close()

# Upisivanje tezina u txt fajl
file = open('../EDSR_CPP/test_weights.txt', 'w')
lines = []
for n in range(model.layers[1].weights[0].shape[-1]):
    f = model.layers[1].weights[0][:, :, :, n].numpy()
    fn = np.zeros((f.shape[0] * f.shape[1] * f.shape[2]))
            
    step = f.shape[0] * f.shape[1]
    for d in range(f.shape[-1]):
        fn[d * step : d * step + step] = f[:, :, d].reshape(-1)
    
    s = ''
    for val in fn:
        s += str(val) + ','
    s += '\n'
    lines.append(s)
file.writelines(lines)
file.close()    

# output = model.predict(test)

# # Ucitavanje rezultata iz c++ koda
# file = open('../EDSR_CPP/Conv2D_result.txt', 'r')
# line = file.readline()
# val = line.split(',')
# del val[-1]
# num = []
# for v in val:
#     num.append(float(v))
# num = np.array(num)
# cpp_out = np.zeros(output.shape)
# for c in range(output.shape[-1]):
#     step = output.shape[0] * output.shape[1]
#     cpp_out[:, :, c] = num[c * step : c * step + step].reshape((output.shape[0], output.shape[1]))
    
# file.close()

# # provera da li su rezultati isti
# if np.count_nonzero((cpp_out - output) == 0) == output.shape[0] * output.shape[1] * output.shape[2]:
#     print('Rezultati su isti')