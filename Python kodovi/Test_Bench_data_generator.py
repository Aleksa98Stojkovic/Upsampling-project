import random
import numpy as np


data_range = 100
weight_range = 50
bias_range = 50
data_width = 10
data_height = 10
relu = True
file_path = "dram_data.txt"
result_file_path = "result_python.txt"
sysc_weight_file_path = "weights_sysc.txt"
sysc_data_file_path = "data_sysc.txt"
sysc_result_file_path = "result_python_v1.txt"

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

def twos_comp(val, bits):
    """compute the 2's complement of int value val"""
    if (val & (1 << (bits - 1))) != 0: # if sign bit is set e.g., 8bit: 128-255
        val = val - (1 << bits)        # compute negative value
    return val 

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

def WriteTxt(data_s, weight_s, result_dim, file_path):
    
    l = data_s + weight_s
    for i in range(result_dim):
        
        s = bin(0).split('b')[-1].zfill(64)
        l.append(s + '\n')
    
    file = open(file_path, 'w')
    file.writelines(l)
    file.close()

def WriteResult(data, result_file_path):
    
    l = []
    
    for x in range(data.shape[0]):
        for y in range(data.shape[1]):            
            for z in range(data.shape[2]):
                
                if data[x, y, z] < 0:
                    
                    d = 2 ** 64 + data[x, y, z]
                    s = bin(d).split('b')[-1]
                else:
                    s = bin(data[x, y, z]).split('b')[-1].zfill(64)
                    
                l.append(s + '\n')
    
    file = open(result_file_path, 'w')
    file.writelines(l)
    file.close()
    
# Used for generating weights for SystemC model
def WriteWeightsSysC(weight, file_path):

    weight_l = []
    
    for k in range(weight.shape[3]): # packets
        for y in range(weight.shape[1]): # width
            for x in range(weight.shape[0]): # height
                for z in range(weight.shape[2]): # depth
                
                    weight_l.append(str(weight[x, y, z, k]) + '\n')
    
    
    
    file = open(file_path, 'w')
    file.writelines(weight_l)
    file.close()

def WriteDataSysC(data_s, file_path):
    
    data = []
    
    for s in data_s:
        
        val = 0
        base = 2 ** 63
        for i in range(len(s) - 1):
            
            if s[i] == '1':
                val += base
            base = base // 2 
            
        data.append(str(val) + '\n')
    
    file = open(file_path, 'w')
    file.writelines(data)
    file.close()
            
def WriteResultSysC(result, file_path):
    
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

WriteTxt(data_s, weight_s, result.shape[0] * result.shape[1] * result.shape[2], file_path)
WriteResult(result.astype('int'), result_file_path)

# Txt files for SystemC model
WriteWeightsSysC(weight.astype('int'), sysc_weight_file_path)
WriteDataSysC(data_s, sysc_data_file_path)
WriteResultSysC(result.astype('int'), sysc_result_file_path)





