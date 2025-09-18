function [] = artifact_Extract_Moments( file_list )

%{
    Alessandro: save what's the variance, skewness and kurtosis for all the
    files.
%}


for i=1:length(file_list)
    %LOAD IN THE EEG FILE
    load(file_list{i})  
    vars{i} = squeeze(var(EEG.data,[],2));
    skews{i} = squeeze(skewness(EEG.data,[],2));
    kurts{i} = squeeze(kurtosis(EEG.data,[],2));    
end


save(['dEEG_5sec_' name '.mat'], 'EEG')

save vars vars;
save skews skews;
save kurts kurts;
end

