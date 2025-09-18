import torch
from torch import nn
from torch.autograd import Variable

import numpy as np
import os
import sys


# # Define models
def CudaVariable(tensor):
    var = Variable(tensor)
    if torch.cuda.is_available():
        return var.cuda()
    return var

class Encoder(nn.Module):
    def __init__(self, input_size, hidden_size, bidirectional=False, num_layers=1):
        # input_size is size of vector for each element of the sequence (should be 1 for us)
        # hidden_size is size of hidden vector
        super(Encoder, self).__init__()
        self.hidden_size = hidden_size
        self.input_size = input_size
        # for now, assume 1 layer and 1 direction
        self.lstm = nn.LSTM(input_size, hidden_size, batch_first=True, num_layers=num_layers, 
                            bidirectional=bidirectional)


    def forward(self, inp):
        #inp is of size batch_size x pad_length
        #self.initHidden()
        # lstm expects batch_size x pad_length x num_features because of batch_first=True
        output, (hidden, last_cell) = self.lstm(inp.unsqueeze(-1))
        # output is batch_size x pad_length x (hidden_size x num_directions)
        # hidden is (num_layers x num_directions) x batch_size x hidden_size
        # last_cell has same dims as hidden
        return output, hidden, last_cell

    def initHidden(self):
        result = CudaVariable(torch.zeros(1, 1, self.hidden_size))
        #result.cuda()
        return result


# In[ ]:


class Decoder(nn.Module):
    def __init__(self, hidden_size, output_size, extra_input_dim=True, encoder_bidirectional=False, num_layers=1):
        # output_size should be same as input_size of encoder (for us, 1)
        # hidden_size is size of hidden state for each direction/layer.
        # extra_input_dim - whether or not to extend input to include 0/1 for sos_input or not

        super(Decoder, self).__init__()
        self.encoder_bidirectional = encoder_bidirectional
        if self.encoder_bidirectional:
            self.hidden_size = hidden_size * 2
        else:
            self.hidden_size = hidden_size
        self.output_size = output_size
        if extra_input_dim:
            self.input_size = output_size + 1 # extra dim in input because of 0/1 SOS label
        else:
            self.input_size = output_size
        self.extra_input_dim = extra_input_dim
        self.rnn = nn.LSTM(self.input_size, self.hidden_size, num_layers=num_layers)
        self.linear = nn.Linear(self.hidden_size, output_size)

    def forward_one(self, rnn_input, rnn_hidden, rnn_cell):
        # seq_len for going forward one is 1
        # for the d:= rnn-linear combo, we have that input_size for d = output_size + 1 of d

        # rnn expects inp = 1 x batch_size x input_size
        # rnn_hidden, rnn_cell = num_layers x batch_size x (self.hidden_size)
        # rnn_output = 1 x batch_size x (self.hidden_size)
        rnn_output, (rnn_hidden, rnn_cell) = self.rnn(rnn_input, (rnn_hidden, rnn_cell))
        # linear input is [batch_size x hidden_size]
        # linear output is [batch_size x output_size]
        output = self.linear(rnn_output[0])
        # output is ([1 x batch_size x output_size], [num_layers x batch_size x self.hidden_size])
        return output.unsqueeze(0), rnn_hidden, rnn_cell
    
    def forward(self, hidden_0, cell_0, output_seq_len, target_output=None):
        # sos_input should be tensor of batch_size SOS tokens (size batch_size x output_size)
        # hidden_0 should be last hidden state , size (num_layers x num_directions) x batch_size x hidden_size
        # cell_0 should be last cell, size (num_layers x num_directions) x batch_size x hidden_size
        # output_seq_length (integer) = length of sequence to be outputted
        # target_output - for teacher forcing only. [pad_length x batch_size x output_size]
        
        batch_size = hidden_0.size(1)

        sos_input = CudaVariable(torch.zeros(batch_size, 1))
        decoder_outputs = CudaVariable(torch.zeros(output_seq_len, batch_size, self.output_size))
                
        dec_input = sos_input.unsqueeze(0) # 1 x batch_size x output_size
        if self.extra_input_dim:
            # extend the input features to have 0 for sos symbol, and 1 otherwise.
            dec_input_vec = torch.cat((dec_input, CudaVariable(torch.zeros(1, batch_size, 1))), 2) # 1 x batch_size x (output_size + 1)
        else:
            dec_input_vec = dec_input
        dec_hidden = self._cat_directions(hidden_0)
        dec_cell = self._cat_directions(cell_0)
        for i in range(output_seq_len):
            dec_output, dec_hidden, dec_cell = self.forward_one(dec_input_vec, dec_hidden, dec_cell)
            if target_output is not None:
                dec_input = (target_output[i]).unsqueeze(0)
            else:
                dec_input = dec_output
            if self.extra_input_dim:
                # extend the input features to have 0 for sos symbol, and 1 otherwise.
                dec_input_vec = torch.cat((dec_input, CudaVariable(torch.ones(1, batch_size, 1))), 2)
            else:
                dec_input_vec = dec_input
            decoder_outputs[i] = dec_output
        
        # decoder_outputs is [output_seq_length x batch_size x output_size]
        # permute() makes it [batch_size x output_seq_length x output_size] 
        decoder_outputs = decoder_outputs.permute(1,0,2)
        return decoder_outputs
    
    def _cat_directions(self, hidden):
        """ If the encoder is bidirectional, do the following transformation.
            (#directions * #layers, #batch, hidden_size) -> (#layers, #batch, #directions * hidden_size)
        """
        if self.encoder_bidirectional:
            hidden = torch.cat([hidden[0:hidden.size(0):2], hidden[1:hidden.size(0):2]], 2)
        return hidden

