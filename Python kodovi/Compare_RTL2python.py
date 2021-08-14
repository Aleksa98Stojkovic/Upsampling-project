def OpenFile(file_path):
    
    lines = []
    file = open(file_path, 'r')
    lines = file.readlines()
    file.close()
    
    return lines

def CompareValues(res1, res2):
    
    counter = 0
    l = []
    
    for i in range(len(res1)):
        
        if res1[i] != res2[i]:
            counter += 1
            l.append(i)
        
    return counter, l

python_file_path = "result_python.txt"
pres = OpenFile(python_file_path)
file_path = "result_rtl.txt"
rres = OpenFile(file_path)
val, l = CompareValues(pres, rres)
print('Broj nepodudarnih vrednosti je: ', val)
print('Linije: ', l)