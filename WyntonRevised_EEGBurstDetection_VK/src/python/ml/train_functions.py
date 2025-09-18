import torch
from torch import nn
from torch.autograd import Variable

from prettytable import PrettyTable
from tqdm import tqdm
import numpy as np

from datasets import BurstDataset, ShuffledBatchSequentialSampler, FakeBurstDataset

import sys
import os
import random

import losswise

def flip(x, dim):
    xsize = x.size()
    dim = x.dim() + dim if dim < 0 else dim
    x = x.contiguous().view(-1, *xsize[dim:])
    x = x.view(x.size(0), x.size(1), -1)[:, getattr(torch.arange(x.size(1)-1, 
                      -1, -1), ('cpu','cuda')[x.is_cuda])().long(), :]
    return x.view(xsize)

class TeacherForcingProb:
    def __init__(self, slope, start_epoch_num):
        self.slope = slope
        self.tf_prob = 1
        for i in range(1, start_epoch_num):
            # if resuming training rather than starting at beginning, 
            # fast-forward probability to proper place
            self.epoch_seen()
        
    def epoch_seen(self):
        if self.slope is None:
            return
        self.tf_prob = max(0, self.tf_prob - self.slope)
        
    def should_teacher_force(self):
        if self.slope is None:
            return False
        rand_num = random.uniform(0, 1)
        if rand_num < self.tf_prob:
            return True
        return False        
        
def run_batch(masks, bursts, encoder, decoder, teacher_forcing, train_reversed, is_training):
    burst_lens = masks.sum(dim=1)
    max_seq_length = int(burst_lens.max().data.cpu().numpy()[0])

    # trim bursts and masks to be padded only up to the max_seq_length
    bursts_trimmed = bursts.narrow(1, 0, max_seq_length)
    masks_trimmed = masks.narrow(1, 0, max_seq_length)

    # print burst_lens.min().data.numpy()[0], burst_lens.max().data.numpy()[0]
    enc_out, hidden, cell = encoder(bursts_trimmed)

    if train_reversed:
        target_bursts = flip(bursts_trimmed, 1)   # still batch_size x output_seq_length, but reversed in seq_length dimension
    else:
        target_bursts = bursts_trimmed
        
    # output is size batch_size x output_seq_length x input_size
    if is_training and teacher_forcing.should_teacher_force():
        # to do teacher forcing, pass in something for target_output
        output = decoder(hidden, cell, max_seq_length, target_output=target_bursts.permute(1,0).unsqueeze(2))
    else:
        output = decoder(hidden, cell, max_seq_length)

    loss_fn = torch.nn.MSELoss(reduce=False)
    mses = loss_fn(output.squeeze(), target_bursts)
    # avg_mses is size [batch_size], giving mse for each elt in batch
    avg_mses = torch.sum(mses * masks_trimmed, 1) / burst_lens
    loss = avg_mses.mean()
    return loss
    
def summarize_params(model):
    params = []
    for param in model.parameters():
        params.append(param.sum().data.cpu().numpy()[0])
    return params

def run_epoch(dataset, batch_size, is_training, encoder, decoder, encoder_optimizer, decoder_optimizer, 
              teacher_forcing, train_reversed, batch_by_len, save_path):
    if is_training:
        print('encoder params at epoch start', summarize_params(encoder))
        print('decoder params at epoch start', summarize_params(decoder))
    sys.stdout.flush()
    batch_sampler = ShuffledBatchSequentialSampler(dataset, batch_size=batch_size, drop_last=False)
    if batch_by_len:
        data_loader = torch.utils.data.DataLoader(dataset, batch_sampler=batch_sampler)
    else:
        data_loader = torch.utils.data.DataLoader(dataset, batch_size=batch_size, shuffle=False, drop_last=True)
    losses = []
    if is_training:
        encoder.train()
        decoder.train()
    else:
        encoder.eval()
        decoder.eval()
    for batch in tqdm(data_loader):
        if is_training:
            encoder_optimizer.zero_grad()
            decoder_optimizer.zero_grad()
        masks = Variable(batch['mask']) # [batch_size x pad_length]
        bursts = Variable(batch['burst'])   # [batch_size x pad_length]
        if torch.cuda.is_available():
            masks = masks.cuda()
            bursts = bursts.cuda()
        loss = run_batch(masks, bursts, encoder, decoder, teacher_forcing, train_reversed, is_training)
        
        if is_training:
            loss.backward()
            encoder_optimizer.step()
            decoder_optimizer.step()
        losses.append(loss.cpu().data[0])
    if is_training and save_path is not None:
        # save the model
        enc_save_path = save_path + '_enc.pkl'
        dec_save_path = save_path + '_dec.pkl'
        torch.save(encoder.state_dict(), enc_save_path)
        torch.save(decoder.state_dict(), dec_save_path)
    if is_training:
        teacher_forcing.epoch_seen()
    avg_loss = np.mean(losses)
    return avg_loss

def train_model(train_data, dev_data, test_data, encoder, decoder, save_dir=None, batch_size=50, 
                num_epochs=50, start_epoch_num=1, lr=1e-3, weight_decay=1e-1, teacher_forcing_slope=None, train_reversed=False, batch_by_len=True, 
               losswise_graph=None, params_dict={}):
    # Note: params dict is used only for printing
    if (save_dir is not None) and (not os.path.exists(save_dir)):
        os.makedirs(save_dir)
    print("start train_model")
    print("****************************************")
    print(params_dict)
    print("Batch size: {}, num_epochs: {}, lr: {}, weight_decay: {}".format(batch_size, num_epochs, lr, weight_decay))
    print("Encoder", encoder)
    print("Decoder", decoder)
    print("*****************************************")

    # might need to do parameters = filter(lambda p: p.requires_grad, model.parameters())
    encoder_optimizer = torch.optim.Adam(encoder.parameters(), lr=lr, weight_decay=weight_decay)
    decoder_optimizer = torch.optim.Adam(decoder.parameters(), lr=lr, weight_decay=weight_decay)
    teacher_forcing = TeacherForcingProb(teacher_forcing_slope, start_epoch_num)
    result_table = PrettyTable(["Epoch", "train loss", "dev loss", "test loss"])
    for epoch in range(start_epoch_num, num_epochs + start_epoch_num):
        print("epoch", epoch)
        if save_dir is None:
            save_path = None
        else:
            save_path = os.path.join(save_dir, 'epoch{}'.format(epoch))
        sys.stdout.flush()
        train_loss = run_epoch(train_data, batch_size, True, encoder, decoder, encoder_optimizer, decoder_optimizer, teacher_forcing, train_reversed, batch_by_len, save_path)
        dev_loss = run_epoch(dev_data, batch_size, False, encoder, decoder, encoder_optimizer, decoder_optimizer, teacher_forcing, train_reversed, batch_by_len, save_path)
        test_loss = run_epoch(test_data, batch_size, False, encoder, decoder, encoder_optimizer, decoder_optimizer, teacher_forcing, train_reversed, batch_by_len, save_path)
        result_table.add_row(
                            [ epoch ] +
                            [ "%.7f" % x for x in [train_loss, dev_loss, test_loss]
                                         ])
        print("{}".format(result_table))
        if losswise_graph is not None:
            losswise_graph.append(epoch, {'train_loss': train_loss, 'dev_loss': dev_loss, 'test_loss': test_loss})
        sys.stdout.flush()