#include "Add.h"
#include "Conv2D.h"
#include "load_store.h"
#include "Normalization.h"
#include "Pixel_Shuffle.h"
#include "common.h"

// OpenCV biblioteka
#include <opencv2/core.hpp> 		// Osnove same biblioteke
#include <opencv2/imgcodecs.hpp>	// Citanje i pisanje slika
#include <opencv2/highgui.hpp>		// Prikaz slike
// Napomena: treba dodati u makefile opencv biblioteku

using namespace cv;

typedef struct layer_block
{
    int layer_id;
    int x;
    int y;
    int c;
    bool save;
    bool relu;
    std :: string path;
    std :: string bias_path;
    int conv_num;

} layer_block;

// Funkcija za ucitavanje opisa modela
void LoadModelDescription(std :: string path, std :: vector <layer_block> &desc)
{
    std :: ifstream file;
    std :: string line;
    std :: vector <std :: string> line_seg;
    layer_block lb;

    file.open(path);
    while(getline(file, line))
    {
        std :: stringstream sline(line);

        while(sline.good())
        {
            std :: string str;
            std :: getline(sline, str, ',');
            line_seg.push_back(str);
        }

        // linija ima formu: tip, x, y, c, da li sacuvati izlaz
        lb.layer_id = stoi(line_seg[0]);
        lb.x = stoi(line_seg[1]);
        lb.y = stoi(line_seg[2]);
        lb.c = stoi(line_seg[3]);
        lb.path = line_seg[5];
        lb.bias_path = line_seg[6];
        lb.conv_num = stoi(line_seg[8]);
        if(line_seg[4] == "True")
            lb.save = true;
        else
            lb.save = false;
        if(line_seg[7] == "True")
            lb.relu = true;
        else
            lb.relu = false;

        line_seg.clear();
        desc.push_back(lb);
    }
    file.close();
}

// Glavna funkcija
int main()
{

    std :: vector <layer_block> desc;
    std :: stack <float3D> output_stack;
    int counter = 0;
    bool use_bias = true;

    LoadModelDescription("model_desc.txt", desc);// Ucitavanje opisa modela
    std :: cout << "Ucitan opis modela" << std :: endl;

    float3D IFM(desc[0].x, std :: vector <std :: vector <t>> (desc[0].y, std :: vector <t> (desc[0].c)));

    LoadInput(desc[0].path, IFM); // Ucitaj ulaz
    std :: cout << "Ucitan je ulaz iz datoteke " << desc[0].path << std :: endl;
    desc.erase(desc.begin());
    
    // Dodajemo nule kako bi bio odgovarajucih dimenzija za prvu konvoluciju
    zero_padding_input(IFM);
    std :: cout << "Dodate su nule na ulaz " <<  std :: endl;
   

    // prikaz opisa svakog sloja
    for(int i = 0; i < (int)desc.size(); i++)
    {
        std :: cout << desc[i].layer_id << " ";
        std :: cout << desc[i].x << " ";
        std :: cout << desc[i].y << " ";
        std :: cout << desc[i].c << " ";
        std :: cout << desc[i].save << " ";
        std :: cout << desc[i].path << " ";
        std :: cout << desc[i].bias_path << " ";
        std :: cout << desc[i].conv_num << " ";
        std :: cout << std :: endl;
    }

    std :: cout << std :: endl << std :: endl;

    // izvrsavanje modela
    for(int i = 0; i < (int)desc.size(); i++)
    {
        // Samo Pixel_Shuffle i Conv2D menjaju dimenzije ulaza
        switch(desc[i].layer_id)
        {
            case 4:

                std :: cout << "Normalizacija! ";
                Normalize(IFM);

                break;

            case 5:

                std :: cout << "Denormalizacija! ";
                Denormalize(IFM);

                break;

            case 2:

                std :: cout << "Sabiranje! ";
                Add(IFM, output_stack.top());
                output_stack.pop();

                if(desc[i].save)
                    output_stack.push(IFM);

                break;

            case 3:

                std :: cout << "Pixel Shuffle! ";
                Pixel_Shuffle(IFM, 2);

                break;

            case 1:

                std :: cout << "Konvolucija! ";
                {

                    if(desc[i].conv_num == 34 || desc[i].conv_num == 35)
                    {

						int bias_address = 0;
						
						if(desc[i].conv_num == 35)
							bias_address += 3;
							
						
						
                        float3D IFM_new(desc[0].x, std :: vector <std :: vector <t>> (desc[0].y, std :: vector <t> (256)));
                        float3D IFM_temp(desc[0].x, std :: vector <std :: vector <t>> (desc[0].y, std :: vector <t> (64)));
                        std::string temp;
						bias_address += desc[i].conv_num;
						
                        temp = desc[i].path;
                        temp.erase(temp.lenght() - 4);
                        temp += "_1.txt"; 
                        IFM_temp = IFM; // cuvamo originalni ulaz
                        convlove(IFM, temp, bias_address, desc[i].relu); // treba putanju da podesim
                        // Upisemo deo rezultata ovde
                        // IFM je uvek istih dimenzija
                        for(int x = 0; x < (int)(IFM.size()); x++)
                        {
                            for(int y = 0; y < (int)(IFM[0].size()); y++)
                            {
                                for(int c = 0; c < (int)IFM[0][0].size(); c++)
                                {
                                    IFM_new[x][y][c] = IFM[x][y][z];
                                }
                            }
                        }

                        temp = desc[i].path;
                        temp.erase(temp.lenght() - 4);
                        temp += "_2.txt";
                        IFM = IFM_temp;
                        convlove(IFM, temp, bias_address + 1, desc[i].relu); // treba putanju da podesim
                        // Upisemo deo rezultata ovde
                        // IFM je uvek istih dimenzija
                        for(int x = 0; x < (int)(IFM.size()); x++)
                        {
                            for(int y = 0; y < (int)(IFM[0].size()); y++)
                            {
                                for(int c = 0; c < (int)IFM[0][0].size(); c++)
                                {
                                    IFM_new[x][y][c] = IFM[x][y][z + 64];
                                }
                            }
                        }

                        temp = desc[i].path;
                        temp.erase(temp.lenght() - 4);
                        temp += "_3.txt";
                        IFM = IFM_temp;
                        convlove(IFM, temp, bias_address + 2, desc[i].relu); // treba putanju da podesim
                        // Upisemo deo rezultata ovde
                        // IFM je uvek istih dimenzija
                        for(int x = 0; x < (int)(IFM.size()); x++)
                        {
                            for(int y = 0; y < (int)(IFM[0].size()); y++)
                            {
                                for(int c = 0; c < (int)IFM[0][0].size(); c++)
                                {
                                    IFM_new[x][y][c] = IFM[x][y][z + 2 * 64];
                                }
                            }
                        }

                        temp = desc[i].path;
                        temp.erase(temp.lenght() - 4);
                        temp += "_4.txt";
                        IFM = IFM_temp;
                        convlove(IFM, temp, bias_address + 3, desc[i].relu); // treba putanju da podesim
                        // Upisemo deo rezultata ovde
                        // IFM je uvek istih dimenzija
                        for(int x = 0; x < (int)(IFM.size()); x++)
                        {
                            for(int y = 0; y < (int)(IFM[0].size()); y++)
                            {
                                for(int c = 0; c < (int)IFM[0][0].size(); c++)
                                {
                                    IFM_new[x][y][c] = IFM[x][y][z + 3 * 64];
                                }
                            }
                        }

                    }
                    else
                    {
                        if(desc[i].conv_num != 36)
                            convlove(IFM, desc[i].path, desc[i].conv_num, desc[i].relu);
                        else // else deo je za poslednji sloj, on ide klasicno
                        {
                            float4D W(desc[i].c, float3D(3, std :: vector<std :: vector<t>>(3, std :: vector<t>(desc[i - 1].c))));
                            std :: vector <t> b(desc[i].c); // bias deo
                            LoadFile(desc[i].path, W); // ucitavanje tezina za taj sloj
                            if(use_bias)
                                LoadBias(desc[i].bias_path, b);
                            Conv2D(W, IFM, b, use_bias, desc[i].relu);

                            W.clear(); // brisem za svaki slucaj ceo vector
                            b.clear();

                        }
                    }

                    if(desc[i].save)
                    {
                        output_stack.push(IFM);
                        output_stack.push(IFM);
                    }

                }

                break;

        }

        std :: cout << "Odradjen je " << ++counter << ". sloj, " << "Stak ima " << output_stack.size() << " elemenata" << std :: endl;
    }
	
	int height_o = (int)IFM.size();
	int width_o = (int)IFM[0].size();
	// Napravice novi Mat objekat pun nula
	Mat output = Mat::ones(height_o, width_o, CV_8UC3); // CV_8UC3 -> 8 znaci osam bita po pikselu, U = unisgned, C3 = tri kanala
	
	unsigned char pixel;
	
	for(int x = 0; x < height_o; x++)
	{
		for(int y = 0; y < width_o; y++)
		{
			for(int c = 0; c < 3; c++)
			{
				if(IFM[x][y][c] < 0) IFM[x][y][c] = 0.0;
				if(IFM[x][y][c] > 255) IFM[x][y][c] = 255.0;
				
				pixel = (unsigned char)IFM[x][y][c];
				output.at<unsigned char>(x, y, c) = pixel; // Ovo treba jos proveriti
				
			}
		}	
	}
	
	// Upisujemo sliku
	imwrite("result.png", output);
    // WriteFile("result.txt", IFM);
    std :: cout << "Upisan rezultat" << std :: endl;

    IFM.clear();

    return 0;
}
