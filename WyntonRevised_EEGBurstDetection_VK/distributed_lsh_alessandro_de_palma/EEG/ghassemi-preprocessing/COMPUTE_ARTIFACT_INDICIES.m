%%Compute Artifact Indicies
%% GO TO THE MAIN DIRECTORY
cd('/nobackup1b/users/ghassemi/EEGs/CA_Merged')
search_me = '/nobackup1b/users/ghassemi/EEGs/CA_Merged'

%%  Extract all .mat files under this directory
file_list = getAllFiles([search_me]);
file_list = getSubsetWithKeywords(file_list,{'ar_'},[]);

% Alessandro: the variables in this loop are loaded from the file.
for i = 1:length(file_list)
   load(file_list{i}); 
   under = strfind(file_list{i},'_');
   index(i) = str2num(file_list{i}(under(end)+1:end-4));
   var{i} = ar.vars;
   skews{i} = ar.skews; 
   kurts{i} = ar.kurts;
   fband_0_2{i} = ar.band_0_2;
   fband_20_40{i} = ar.band_20_40;
   i
end
[~,index] = sort(index);

% Alessandro: I believe this file just does some reordering.

var = var(index);
skews = skews(index);
kurts = kurts(index);
fband_0_2 = fband_0_2(index);
fband_20_40 = fband_20_40(index);

vars = var;

save('vars', 'vars', '-v7.3');
save('skews', 'skews', '-v7.3');
save('kurts', 'kurts', '-v7.3');
save('fband_0_2', 'fband_0_2', '-v7.3');
save('fband_20_40', 'fband_20_40', '-v7.3');