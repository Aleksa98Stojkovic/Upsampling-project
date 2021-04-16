from tensorflow.keras.layers import Add, Conv2D, Input, Lambda, SeparableConv2D
from tensorflow.keras.models import Model
from tensorflow.nn import depth_to_space
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.optimizers.schedules import PiecewiseConstantDecay
import matplotlib.pyplot as plt
import numpy as np
import os

class EDSR:
    
    # srednja vrednost za ceo dataset, ali treba dodati metodu koja to dinamicki radi
    mean = np.array([0.4488, 0.4371, 0.4040]) * 255
    
    # konstruktor
    def __init__(self, batch, num_filters, num_res_block, res_block_scaling = None,
                 use_bias = False, separable_conv = False, scale = 2, input_shape = 32):
        
        self.batch = batch
        self.num_filters = num_filters
        self.num_res_block = num_res_block
        self.res_block_scaling = res_block_scaling
        self.use_bias = use_bias
        self.separable_conv = separable_conv
        self.scale = scale
        self.model = self.create_edsr(input_shape)
        
    
    def res_block(self, x_in, scaling):
        
        # Stvara residual blokove
        
        if self.separable_conv:        
            x = SeparableConv2D(self.num_filters, 3, padding = 'same', activation = 'relu',
                                use_bias = self.use_bias)(x_in)
            x = SeparableConv2D(self.num_filters, 3, padding = 'same',
                                use_bias = self.use_bias)(x)
        else:
            x = Conv2D(self.num_filters, 3, padding = 'same', activation = 'relu',
                       use_bias = self.use_bias)(x_in)
            x = Conv2D(self.num_filters, 3, padding = 'same',
                       use_bias = self.use_bias)(x)
        
        if scaling:
            x = Lambda(lambda t : t * scaling)(x)
            
        x = Add()([x_in, x])
            
        return x
    
    
    def upsample(self, x):
        
        def upsample_1(x, factor, **kwargs):
            
            # Sub-pixel convolution
            if self.separable_conv:
                x = SeparableConv2D(self.num_filters * (factor ** 2), 3,
                                    padding = 'same', use_bias = self.use_bias)(x)
            else:
                x = Conv2D(self.num_filters * (factor ** 2), 3,
                           padding = 'same', use_bias = self.use_bias)(x)
            
            return Lambda(self.pixel_shuffle(factor))(x)

        if self.scale == 2:
            x = upsample_1(x, 2, name = 'conv2d_1_scale_2')
        elif self.scale == 3:
                x = upsample_1(x, 3, name = 'conv2d_1_scale_3')
        elif self.scale == 4:
            x = upsample_1(x, 2, name = 'conv2d_1_scale_2')
            x = upsample_1(x, 2, name = 'conv2d_2_scale_2')

        return x
    
    def pixel_shuffle(self, factor):
        return lambda x: depth_to_space(x, factor)

    def normalize(self, x):
        return (x - self.mean) / 127.5

    def denormalize(self, x):
        return x * 127.5 + self.mean
    
    def create_edsr(self, input_shape):
    
        # Kreira model sa zadatim parametrima
        
        x_in = Input(shape = (input_shape[0], input_shape[1], 3))
        x = Lambda(self.normalize)(x_in)

        # polazna Conv2D
        if self.separable_conv:
            x = b = SeparableConv2D(self.num_filters, 3, padding = 'same',
                                    use_bias = self.use_bias)(x)
        else:
            x = b = Conv2D(self.num_filters, 3, padding = 'same',
                                    use_bias = self.use_bias)(x)
        
        # ResBlock
        for i in range(self.num_res_block):
            b = self.res_block(b, self.res_block_scaling)
        
        # Pretposlednja Conv2D
        if self.separable_conv:
            b = SeparableConv2D(self.num_filters, 3, padding = 'same', 
                                use_bias = self.use_bias)(b)
        else:
            b = Conv2D(self.num_filters, 3, padding = 'same', 
                       use_bias = self.use_bias)(b)
        
        # Krajnji Add
        x = Add()([x, b])

        # Conv2D + Pixel_Shuffle        
        x = self.upsample(x) # posebno pravljen sub-pixel conv
        
        # Zavrsna Conv2D
        if self.separable_conv:
            x = SeparableConv2D(3, 3, padding = 'same', use_bias = self.use_bias)(x)
        else:
            x = Conv2D(3, 3, padding = 'same', use_bias = self.use_bias)(x)

        x = Lambda(self.denormalize)(x)
        return Model(x_in, x, name = "edsr")
    
    
    def train(self, train_data, train_target, epochs, steps_per_epoch, val_split, boundries, values):
        
        optim_edsr = Adam(learning_rate = PiecewiseConstantDecay(boundaries = boundries,
                                                                 values = values))
        self.model.compile(optimizer = optim_edsr, loss = 'mean_absolute_error')
        self.model.fit(x = train_data, y = train_target, epochs = epochs, steps_per_epoch = steps_per_epoch,
               batch_size = self.batch, validation_split = val_split)
        
    def create_dir(self, path):
        
        weights_dir = path
        os.makedirs(weights_dir, exist_ok = True)
        
    def save_model(self, folder):
        
        self.model.save_weights(folder)
        
    def shuffle(self, data, target):
        
        n = data.shape[0]
        index = np.random.permutation(n)
        return data[index], target[index]
    
    def display_image(self, image, row, col, figsize):
        
        fig = plt.figure(figsize = figsize)
        
        for i, img in enumerate(image):
            
            fig.add_subplot(row, col, i + 1)
            plt.imshow(img)
        
    
    
    # Treba dodati treniranje
    # Videti kako da se ne ucitavaju svi podaci odjednom, 
    # vec samo batch koji treba za datu turu
    # Treba dodati funkcije za prikaz slika
    # Treba dodati funkciju za racunanje pnsr
    # Proveriti kako funkcionise inaj planer za opadanje tezina
    # Mozda bismo mogli da particionisemo da se deo konvolucije izvrsava na procesoru,
    # a deo na akceleratoru
    
    