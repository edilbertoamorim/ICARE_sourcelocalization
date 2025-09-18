function [] = artifact_Find_Vari( file_list, numstds, variance_lower_threshold,vars, i)

%load vars;
for j = 1:length(vars)
    vars2{j} = reshape(vars{j},1,size(vars{j},1)*size(vars{j},2));
end

this_var  = [vars2{:}]; this_var = reshape(this_var,1, size(this_var,1)*size(this_var,2));
pop_m_var = nanmean(this_var(this_var ~= 0));
pop_s_var = nanstd(this_var(this_var ~= 0));

    ptm=matfile(file_list,'Writable',true);

    % Alessandro: this creates a matrix of logical values (per channel per epoch).

    %LOAD IN THE EEG FILE
    ptm.rejvariance = vars{i} > pop_m_var + numstds*pop_s_var |...
                      vars{i} < variance_lower_threshold;


end
