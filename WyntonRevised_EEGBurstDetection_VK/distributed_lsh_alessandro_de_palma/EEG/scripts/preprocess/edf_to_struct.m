function [ output ] = edf_to_struct( filename, folder )
%EDF_TO_STRUCT Convert the .edf stored at filename in folder folder into a struct.
%   Relies on edf reading tool (edfread.m)
%
%   Struct format (example, for the header please check edf's specifications):
%   header
%        ver: 0
%      patientID: string (it's de-identified so no information)                                       '
%       recordID: string                                                '
%      startdate: e.g. '09.04.12'
%      starttime: e.g. '04.43.14'
%          bytes: int
%        records: int
%       duration: int
%             ns: int
%          label: {1×ns cell}
%     transducer: {1×ns cell}
%          units: {1×ns cell}
%    physicalMin: [1×ns double]
%    physicalMax: [1×ns double]
%     digitalMin: [1×ns double]
%     digitalMax: [1×ns double]
%      prefilter: {1×ns cell}
%        samples: [1×ns double]
%      frequency: [1×ns double]
%
%   matrix: [ns x max(samples)*records double]
%   name: string
%
%  i.e., matrix is a matrix with all the samples for all the channels. Name
%  is the filename.

    [hdr, record] = edfread(fullfile(folder, filename));
    output.header = hdr;
    output.matrix = record;
    [filepath,name,ext] = fileparts(filename);
    output.name = char(name);

end

