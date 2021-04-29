#include "Add.h"
#include "Conv2D.h"
#include "load_store.h"
#include "Normalization.h"
#include "Pixel_Shuffle.h"
#include <stack>

#include "common.h"
#include <cmath>

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

} layer_block;

// void ResBlock(float3D &, float4D &, std :: vector<t> &, std :: string, std :: string, std :: string, std :: string, bool);

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
int sc_main(int argc, char* argv[])
{

//    num_t q(16, 1);
//    num_t q1(16, 1);
//    t val = -1.7299201;
//    q = val;
//    q1 = val;
//
//    std :: cout << q << " " <<  val << " " << q1 << std :: endl;


    std :: vector <layer_block> desc;
    std :: stack <float3D> output_stack;
    int counter = 0;
    bool use_bias = true;
    bool quantize = true;
    int w_data, f_data, w_weights, f_weights, w_conv, f_conv, w_bias, f_bias;

    LoadModelDescription("model_desc.txt", desc);// Ucitavanje opisa modela
    std :: cout << "Ucitan opis modela" << std :: endl;

    float3D IFM(desc[0].x, std :: vector <std :: vector <t>> (desc[0].y, std :: vector <t> (desc[0].c)));

    LoadInput(desc[0].path, IFM); // Ucitaj ulaz
    std :: cout << "Ucitan je ulaz iz datoteke " << desc[0].path << std :: endl;
    desc.erase(desc.begin());


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
                    if(quantize)
                    {
                        // prvi put kad se dodaje u stack, onda mora dupli
                        float4D W(desc[i].c, float3D(3, std :: vector<std :: vector<t>>(3, std :: vector<t>(desc[i - 1].c))));
                        std :: vector <t> b(desc[i].c); // bias deo
                        LoadFile(desc[i].path, W); // ucitavanje tezina za taj sloj
                        if(use_bias)
                            LoadBias(desc[i].bias_path, b);

                        /* Kvantizacija */

                        w_data = 11;
                        f_data = 5;

                        w_weights = 11;
                        f_weights = 1;

                        w_bias = 11;
                        f_bias = 1;

                        w_conv = 24;
                        f_conv = 8;

                        /*
                        std :: cout << "IFM: " << IFM.size() << " " << IFM[0].size() << " " << IFM[0][0].size() << std :: endl;
                        std :: cout << "IFM_Q: " << IFM_Q.size() << " " << IFM_Q[0].size() << " " << IFM_Q[0][0].size() << std :: endl;
                        std :: cout << "W: " << W.size() << " " << W[0].size() << " " << W[0][0].size() << " " << W[0][0][0].size() << std :: endl;
                        std :: cout << "W_Q: " << W_Q.size() << " " << W_Q[0].size() << " " << W_Q[0][0].size() << " " << W_Q[0][0][0].size() << std :: endl;
                        std :: cout << "b: " << b.size() << std :: endl;
                        std :: cout << "b_q: " << b_q.size() << std :: endl;
                        */

                        Quantize3D_uniform(IFM, w_data, f_data); // kvantizuj IFM
                        Quantize4D_uniform(W, w_weights, f_weights); // kvantizuj W
                        Quantized1D_uniform(b, w_bias, f_bias);

                        Conv2D_Q(W, IFM, b, use_bias, w_conv, f_conv, w_data, f_data, desc[i].relu);

                        /* ------------ */

                        if(desc[i].save)
                        {
                            output_stack.push(IFM);
                            output_stack.push(IFM);
                        }

                        W.clear(); // brisem za svaki slucaj ceo vector
                        b.clear();

                    }
                    else
                    {
                        // prvi put kad se dodaje u stack, onda mora dupli
                        float4D W(desc[i].c, float3D(3, std :: vector<std :: vector<t>>(3, std :: vector<t>(desc[i - 1].c))));
                        std :: vector <t> b(desc[i].c); // bias deo
                        LoadFile(desc[i].path, W); // ucitavanje tezina za taj sloj
                        if(use_bias)
                            LoadBias(desc[i].bias_path, b);
                        Conv2D(W, IFM, b, use_bias, desc[i].relu);
                        if(desc[i].save)
                        {
                            output_stack.push(IFM);
                            output_stack.push(IFM);
                        }

                        W.clear(); // brisem za svaki slucaj ceo vector
                        b.clear();
                    }
                }

                break;

        }

        std :: cout << "Odradjen je " << ++counter << ". sloj, " << "Stak ima " << output_stack.size() << " elemenata" << std :: endl;
    }

    WriteFile("result_11_5__11_1__11_1__24_8.txt", IFM);
    std :: cout << "Upisan rezultat" << std :: endl;

    IFM.clear();

    return 0;
}
