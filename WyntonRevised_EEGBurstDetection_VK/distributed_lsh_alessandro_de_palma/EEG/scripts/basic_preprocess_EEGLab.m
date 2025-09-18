function [ output ] = basic_preprocess_EEGLab( input )
%PREP_EEGLab Apply the PREP pipeline to an input in EEGLab format.
%   Perform preprocessing on a single EEGLab lab format input.
%   remove_bad_channels is true if interpolated bad channels shall be
%   removed.
%   The PREP pipeline is applied separately on 5min epochs of the file.
%
%   Output format:
%       eeglab structure with additional fields
%       interpolatedChannels (cell of lists of interpolated channel indices per EPOCH)
%       n_epochs (number of epochs)
