import torch
import numpy as np
import matplotlib.pyplot as plt 
from torch.autograd import Variable
import math

def encode(bursts, masks, encoder):
    try:
        if isinstance(bursts, np.ndarray):
            bursts = torch.Tensor(bursts)
        if isinstance(masks, np.ndarray):
            masks = torch.Tensor(masks)
        bursts = Variable(bursts)
        masks = Variable(masks)
        if torch.cuda.is_available():
            bursts = bursts.cuda()
            masks = masks.cuda()

        burst_lens = masks.sum(dim=1)
        max_seq_length = int(burst_lens.max().data.cpu().numpy()[0])

        # trim bursts and masks to be padded only up to the max_seq_length
        bursts_trimmed = bursts.narrow(1, 0, max_seq_length)
        masks_trimmed = masks.narrow(1, 0, max_seq_length)

        # print burst_lens.min().data.numpy()[0], burst_lens.max().data.numpy()[0]
        enc_out, hidden, cell = encoder(bursts_trimmed)
    except Exception as e:
        return bursts, masks, None
        print e
    return enc_out, hidden, cell

def autoencode(inp_array, encoder, decoder, toss_encoder_output=False, reverse=False):
    # inp_array - numpy array or tensor of burst data
    # returns numpy array of output
    if isinstance(inp_array, np.ndarray):
        inp_array = torch.Tensor(inp_array)
    inp_var = Variable(inp_array)
    if torch.cuda.is_available():
        inp_var = inp_var.cuda()
    pad_length = inp_var.size(0)
    enc_out, hidden, cell = encoder(inp_var.view(1,pad_length))
    # output is size batch_size x pad_length x input_size
    hidden_size = hidden.size(0)
    output = decoder(hidden, cell, pad_length)
    if toss_encoder_output:
        output = decoder(torch.zeros_like(hidden), torch.zeros_like(cell), pad_length)
    out_array = output.data.cpu().numpy()
    out_array = out_array.reshape(pad_length)
    if reverse:
        return np.flip(out_array,axis=0).copy()
    return out_array

def plot_autoencoding(sample, encoder, decoder, toss_encoder_output=False, reverse=False, undownsampled=None):
    # sample is just an element of the dataset
    # undownsampled is same as sample, except without downsampling. Used to plot the original, complete, un-downsampled
        # burst for comparison with the output
    seq_len = int(sample['mask'].sum())
    inp_array = sample['burst'].cpu().numpy()
    out_array = autoencode(inp_array, encoder, decoder, toss_encoder_output, reverse)
    if undownsampled is None:
        plt.plot(inp_array[:seq_len], label='Original burst')
        plt.plot(out_array[:seq_len], label='Autoencoder output')
    else:
        unds_seq_len = int(undownsampled['mask'].sum())
        unds_inp_array = undownsampled['burst'].cpu().numpy()
        out_array_trim = out_array[:seq_len]
        unds_inp_array_trim = unds_inp_array[:unds_seq_len]
        out_xrange = np.arange(0,len(out_array_trim),1)
        ds_factor = math.ceil(len(unds_inp_array_trim)/(0.0+len(out_array_trim)))
        undownsampled_xrange = np.arange(0, len(out_array_trim), 1.0/ds_factor)[:len(unds_inp_array_trim)]
        
        undownsampled_xrange = np.arange(0, len(unds_inp_array_trim), 1)
        out_xrange = np.arange(0,len(unds_inp_array_trim),ds_factor)
        plt.plot(undownsampled_xrange, unds_inp_array_trim, label='Original burst')
        plt.plot(out_xrange, out_array_trim, label='Autoencder output')
    plt.title('Original vs autoencoded')
    plt.xlabel('Samples')
    plt.ylabel('Signal')
    plt.legend()
    plt.show()

def get_mse(sample, encoder, decoder, toss_encoder_output=False, reverse=False):
    # sample is just an element of the dataset
    seq_len = int(sample['mask'].sum())
    inp_array = sample['burst'].cpu().numpy()
    out_array = autoencode(inp_array, encoder, decoder, toss_encoder_output, reverse)

    loss_fn = torch.nn.MSELoss(reduce=False)
    out_var = Variable(torch.Tensor(out_array))
    burst_var = Variable(sample['burst'])
    mask_var = Variable(sample['mask'])
    if torch.cuda.is_available():
        out_var = out_var.cuda()
        burst_var = burst_var.cuda()
        mask_var = mask_var.cuda()
    mses = loss_fn(out_var, burst_var)
    # avg_mses is size [batch_size], giving mse for each elt in batch
    avg_mse = torch.sum(mses * mask_var) / seq_len
    avg_mse = avg_mse.data.cpu().numpy()[0]
    return avg_mse