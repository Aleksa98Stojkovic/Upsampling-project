import random
import numpy as np


data_range = 100
weight_range = 50
bias_range = 50
data_width = 10
data_height = 10
relu = True
file_path = "dram_content.txt"
file_path_res = "result.txt"
result_dim = 8 * 8 * 64


# Generates input data
def GenerateData(data):
    
    for x in range(data.shape[0]):
        for y in range(data.shape[1]):
            for z in range(data.shape[2]):
                
                data[x, y, z] = random.randint(-data_range, data_range)
    
    return data

# Generates weight data
def GenerateWeight(weight):
    
    for x in range(weight.shape[0]):
        for y in range(weight.shape[1]):
            for z in range(weight.shape[2]):
                for d in range(weight.shape[3]):
                    weight[x, y, z, d] = random.randint(-weight_range, weight_range)
    
    return weight

# Generates bias data
def GenerateBias(bias):
    
    for i in range(bias.shape[0]):
        bias[i] = random.randint(-bias_range, bias_range)
        
    return bias

# Performs convolution
def Convolve(data, weight, bias, relu = True):
    
    result = np.zeros((data.shape[0] - 2, data.shape[1] - 2, 64))
    
    for x in range(data.shape[0] - 2):
        for y in range(data.shape[1] - 2):
            
            data_flat = data[x : x + weight.shape[0], y : y + weight.shape[1], :].flatten()
            
            for f in range(weight.shape[-1]):
                
                weight_flat = weight[:, :, :, f].flatten()
                result[x, y, f] = np.sum(data_flat * weight_flat) + bias[f]
    
    
    if relu:
        result[result < 0] = 0
                    
    return result


def FormatData(data):
    
    data_s = []
    
    for y in range(data.shape[1]):
        for x in range(data.shape[0]):
            
            temp = [] 
            
            for z in range(data.shape[2]):
                
                
                if data[x, y, z] < 0:
                    
                    d = 2 ** 16 + data[x, y, z]
                    s = bin(d).split('b')[-1]
                else:
                    s = bin(data[x, y, z]).split('b')[-1].zfill(16)
                    
                
                temp.append(s)
            
            for i in range(16):
                
                l = temp[i * 4 : (i + 1) * 4]
                l.reverse()
                data_s.append("".join(l) + '\n')
                
    
    return data_s

def FormatWeight(weight):

    weight_s = []
    l = []
    
    for k in range(weight.shape[3]):
        for y in range(weight.shape[1]): # width
            for x in range(weight.shape[0]): # height
                for z in range(weight.shape[2]): # depth
            
                
                    if weight[x, y, z, k] < 0:
                    
                        d = 2 ** 16 + weight[x, y, z, k]
                        s = bin(d).split('b')[-1]
                    else:
                        s = bin(weight[x, y, z, k]).split('b')[-1].zfill(16)
                    
                        
                    l.append(s)

    for i in range(16):
        
        p = 576 * 4 
        temp = l[i * p : (i + 1) * p]
        
        
        for j in range(576):
            l2 = []
            for k in range(4):
                
                l2.append(temp[k * 576 + j])
                
            l2.reverse()
            weight_s.append("".join(l2) + '\n')
            
    
    return weight_s

def WriteDRAM(data_s, weight_s, result_dim, file_path):
    
    data = []
    
    # Data
    for s in data_s:
        
        val = 0
        base = 2 ** 63
        for i in range(len(s) - 1):
            
            if s[i] == '1':
                val += base
            base = base // 2 
            
        data.append(str(val) + '\n')
    
    # Weight
    for s in weight_s:
        
        val = 0
        base = 2 ** 63
        for i in range(len(s) - 1):
            
            if s[i] == '1':
                val += base
            base = base // 2 
            
        data.append(str(val) + '\n')
    
    for _ in range(result_dim):
        data.append(str(0) + '\n')
    
    file = open(file_path, 'w')
    file.writelines(data)
    file.close()
    
    return data

def WriteResult(result, file_path):
    
    result_l = []
    
    for x in range(result.shape[0]):
        for y in range(result.shape[1]):            
            for z in range(result.shape[2]):
                
                result_l.append(str(result[x, y, z]) + '\n')
    
    file = open(file_path, 'w')
    file.writelines(result_l)
    file.close()    
            

data = np.zeros((data_height, data_width, 64))
weight = np.zeros((3, 3, 64, 64))
bias = np.zeros(64)
result = np.zeros((data_height - 2, data_width - 2, 64))

data = GenerateData(data)
weight = GenerateWeight(weight)
# bias = GenerateBias(bias)

result = Convolve(data, weight, bias, relu)

data_s = FormatData(data.astype('int'))
weight_s = FormatWeight(weight.astype('int'))

t = WriteDRAM(data_s, weight_s, result_dim, file_path)
WriteResult(result.astype('int'), file_path_res)

