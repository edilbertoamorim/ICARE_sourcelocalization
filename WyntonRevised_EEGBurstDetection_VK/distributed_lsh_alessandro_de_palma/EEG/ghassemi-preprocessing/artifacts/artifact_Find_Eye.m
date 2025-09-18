function [] = artifact_Find_Eye( file_list, fband_0_2, numchannels, i )

%load fband_0_2;
for j = 1:length(fband_0_2)
    fband_0_2{j} = mean(fband_0_2{j});
end

%Eye_Movements where +/- 50 db from the mean in 0-2Hz Band
eye_upper = mean(mean([fband_0_2{:}]))*316;
eye_lower = mean(mean([fband_0_2{:}]))* 0.00001;

    %point to the data matrix
    ptm=matfile(file_list,'Writable',true);

    % Alessandro: how can this piece of code work, if he just overwrote "fband_0_2"?

    %find the artifact locations
    [chans,epoch_num] = (find(fband_0_2{i} > eye_upper | fband_0_2{i} < eye_lower));

    %for each of the channel
    artifacts = logical(zeros(size(fband_0_2{i},1),size(fband_0_2{i},2)));
    for j = 1:numchannels
       ind = logical(chans == j);
       artifacts(j,epoch_num(ind)) = true ;
    end
    ptm.rejeye = artifacts;




end
