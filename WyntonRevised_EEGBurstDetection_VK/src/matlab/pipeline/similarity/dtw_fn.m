function [distance] = dtw_fn(x,y)
%DTW_SIMILARITY - Returns the dtw distance between signals x and y
maxsamp = SimilarityParams.get_params('maxsamp');
distance = dtw(x, y, maxsamp);
end

