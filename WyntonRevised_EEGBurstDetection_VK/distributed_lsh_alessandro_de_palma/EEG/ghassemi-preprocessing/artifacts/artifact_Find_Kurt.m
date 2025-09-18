function [] = artifact_Find_Kurt( file_list, numstds, kurts, i)
%load kurts

for j = 1:length(kurts)
    kurts2{j} = reshape(kurts{j},1,size(kurts{j},1)*size(kurts{j},2));
end

this_kurt = [kurts2{:}]; this_kurt = reshape(this_kurt,1, size(this_kurt,1)*size(this_kurt,2));
pop_m_kurt = nanmean(this_kurt);
pop_s_kurt = nanstd(this_kurt);

    ptm=matfile(file_list,'Writable',true);
    
    ptm.rejkurt = kurts{i} > pop_m_kurt + numstds*pop_s_kurt |...
                  kurts{i} < pop_m_kurt - numstds*pop_s_kurt;

end

