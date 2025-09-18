function [] = artifact_Find_Muscle( file_list, fband_20_40, numchannels , i )

%load fband_20_40;

for j = 1:length(fband_20_40)
    fband_20_40{j} = mean(fband_20_40{j});
end

%Muscle where + 25 or -100 db from the mean in 20-40Hz band
muscle_upper = mean(mean([fband_20_40{:}]))*10^(25/10);
muscle_lower = mean(mean([fband_20_40{:}]))*10^(-100/10);

    ptm=matfile(file_list,'Writable',true);
    %find the artifact locations
    [chans,epoch_num] = (find(fband_20_40{i} > muscle_upper | fband_20_40{i} < muscle_lower));
    
    %for each of the channel
    artifacts = logical(zeros(size(fband_20_40{i},1),size(fband_20_40{i},2)));
    for j = 1:numchannels
       ind = logical(chans == j);
       artifacts(j,epoch_num(ind)) = true ;
    end
    ptm.rejmusc = artifacts;
      



end

