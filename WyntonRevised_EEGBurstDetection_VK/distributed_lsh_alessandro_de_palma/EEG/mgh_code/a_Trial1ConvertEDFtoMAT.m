clc
clear all
addpath(genpath('Z:\_folders_moved_to_mad3\EDA_Eddy\Sunil Codes'))
pw=pwd;
s=dir('Z:\_folders_moved_to_mad3\EDA_Eddy\bwh*');
for pp=1:length(s)
    foldername=s(1).name;
    str=strcat('Z:\EDA_Eddy\',foldername);
    cd(str)
    s1=dir('*.edf');
    
    for kk=1:length(s1)
        fname=s1(kk).name;
        [hdr, rec] = edfread(fname);
        str2=strcat(fname(1:end-4),'.mat');
        save(str2,'hdr','rec','-v7.3')
        kk
    end
    pp
 cd(pwd)   
end
