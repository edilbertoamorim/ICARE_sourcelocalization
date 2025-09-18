from sklearn.base import TransformerMixin
import numpy as np
import scipy
import scipy.stats

def get_masked_stats(bursts, masks):
    np_mask = 1 - masks
    bursts_masked = np.ma.array(bursts, mask=np_mask)
    mean = np.ma.mean(bursts_masked)
    std = np.ma.std(bursts_masked)
    q25, q50, q75 = scipy.stats.mstats.mquantiles(bursts_masked, [0.25, 0.5, 0.75])
    data_median = q50
    inter_quartile_range = q75 - q25
    return mean, std, data_median, inter_quartile_range

class BurstDatasetStandardizer(TransformerMixin):
        
    def fit(self, burst_dataset):
        # takes in an instance of BurstDataset
        # fits preprocessing to the dataset
        
        all_bursts_masked = self._make_np_masked_bursts(burst_dataset)
        self.data_mean = np.ma.mean(all_bursts_masked)
        self.data_std = np.ma.std(all_bursts_masked)
        q25, q50, q75 = scipy.stats.mstats.mquantiles(all_bursts_masked, [0.25, 0.5, 0.75])
        self.data_median = q50
        self.inter_quartile_range = q75 - q25
        return self
    
    def transform(self, burst_dataset, robust=False):
        # if robust is True, uses median and interquartilerange instead of mean, std
        # transforms the data in burst_dataset to be standardized
        all_bursts_masked = self._make_np_masked_bursts(burst_dataset)
        burst_dataset.all_bursts = self._standardize_masked_array(all_bursts_masked, robust)
        return burst_dataset
    
    def transform_one_burst(self, burst, mask=None, robust=False):
        # transforms one single burst
        # if no mask is given, we assume none of burst is masked
        if mask is None:
            mask = np.array([0]*len(burst))
        burst_masked = np.ma.array(burst, mask=mask)
        return self._standardize_masked_array(burst_masked, robust)
    
    def _make_np_masked_bursts(self, burst_dataset):
        # flip our mask to get numpy mask (0=not masked, 1=masked)
        np_mask = 1 - burst_dataset.all_burst_masks
        all_bursts_masked = np.ma.array(burst_dataset.all_bursts, mask=np_mask)
        return all_bursts_masked
        
    def _standardize_masked_array(self, masked_array, robust):
        # standardize a masked np array, and return normal np array with masked values as 0
        if robust:
            standardized = (masked_array - self.data_median) / self.inter_quartile_range
        else:
            standardized = (masked_array - self.data_mean) / self.data_std
        return standardized.filled(fill_value=0)


# In[ ]:


# data_dir = '/Users/tzhan/Dropbox (MIT)/1 mit classes/thesis/script_output/describe_bs'
# d = BurstDataset()
# d.init_dataset(data_dir, 20)
# a, b, c = d.split(0.60, 0.20)
# standardizer = BurstDatasetStandardizer()
# standardizer.fit_transform(a)
# standardizer.transform(b)
# standardizer.transform(c)

