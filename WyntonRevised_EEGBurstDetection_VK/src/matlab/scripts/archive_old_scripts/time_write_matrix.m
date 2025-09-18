n = 1000000;
global_zs = randi([0 1], 19,n);
local_zs = randi([0 1], 1, n);

labels = {};
for i=1:19
    labels{i} = ['col' num2str(i)];
end

disp('write_matrix')
tic
write_matrix('test.csv', local_zs', '%.0f', '\t', {''});
toc
tic
write_matrix('test.csv', global_zs', '%.0f', '\t', labels);
toc

disp('ascii')
local_zs = local_zs';
global_zs = global_zs';
tic
save('test.txt', 'local_zs', '-ascii');
toc
tic
save('test.txt', 'global_zs', '-ascii');
toc

disp('mat')
tic
save('test.mat', 'local_zs');
toc
tic
save('test.mat', 'global_zs');
toc