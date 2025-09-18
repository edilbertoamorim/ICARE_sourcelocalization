function [] = artifact_Find_Skew( file_list, numstds, skews, i)

for j = 1:length(skews)
    skews2{j} = reshape(skews{j},1,size(skews{j},1)*size(skews{j},2));
end

%load skews
this_skew = [skews2{:}]; this_skew = reshape(this_skew,1, size(this_skew,1)*size(this_skew,2));
pop_m_skew = nanmean(this_skew);
pop_s_skew = nanstd(this_skew);

    ptm=matfile(file_list,'Writable',true);
    
    ptm.rejskew = skews{i} > pop_m_skew + numstds*pop_s_skew |...
                  skews{i} < pop_m_skew - numstds*pop_s_skew; 


end

