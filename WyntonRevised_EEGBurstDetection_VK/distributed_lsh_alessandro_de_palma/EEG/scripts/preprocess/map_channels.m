function [ map ] = map_channels(slave_header )
%{ 
    Alessandro: Make naming consistent across hospitals.
    Author: Mohammad Ghassemi.
%}

master_map = lower({'Fp1',	'EEG Fp1-Ref1',	'EEG FP1-Ref',	'EEG FP1' '';
                    'Fp2',	'EEG Fp2-Ref1',	'EEG FP2-Ref',	'EEG FP2' '';
                    'F7',	'EEG F7-Ref1',	'EEG F7-Ref',	'EEG F7' '';
                    'F8',	'EEG F8-Ref1',	'EEG F8-Ref',	'EEG F8' '';
                    'T3',	'EEG T3-Ref1',	'EEG T3-Ref',	'EEG T3' 'T7';
                    'T4',	'EEG T4-Ref1',	'EEG T4-Ref',	'EEG T4' 'T8';
                    'T5',	'EEG T5-Ref1',	'EEG T5-Ref',	'EEG T5' 'P7';
                    'T6',	'EEG T6-Ref1',	'EEG T6-Ref',	'EEG T6' 'P8';
                    'O1',	'EEG O1-Ref1',	'EEG O1-Ref',	'EEG O1' '';
                    'O2',	'EEG O2-Ref1',	'EEG O2-Ref',	'EEG O2' '';
                    'F3',	'EEG F3-Ref1',	'EEG F3-Ref',	'EEG F3' '';
                    'F4',	'EEG F4-Ref1',	'EEG F4-Ref',	'EEG F4' '';
                    'C3',	'EEG C3-Ref1',	'EEG C3-Ref',	'EEG C3' '';
                    'C4',	'EEG C4-Ref1',	'EEG C4-Ref',	'EEG C4' '';
                    'P3',	'EEG P3-Ref1',	'EEG P3-Ref',	'EEG P3' '';
                    'P4',	'EEG P4-Ref1',	'EEG P4-Ref',	'EEG P4' '';
                    'Fz',	'EEG Fz-Ref1',	'EEG FZ-Ref',	'EEG FZ' '';
                    'Cz',	'EEG Cz-Ref1',	'EEG CZ-Ref',	'EEG CZ' '';
                    'Pz',	'EEG Pz-Ref1',	'EEG PZ-Ref',	'EEG PZ' ''});

% python dictionary of channels: {'Fp1': 1,'Fp2': 2,'F7': 3,'F8': 4,'T3': 5,'T4': 6,'T5': 7,'T6': 8,'O1': 9,'O2' : 10,'F3': 11,'F4': 12,'C3': 13, 'C4': 14, 'P3': 15,'P4': 16, 'Fz': 17, 'Cz': 18, 'Pz': 19}

%slave_header  = {'EEG Fp2-Ref1','c3','O1','O2','A1','A2','Cz','F3','F4','F7','F8','Fz','Fp1','Fp2','Fpz','P3','P4','Pz','T3','T4','T5','T6','LOC','ROC','CHIN1','CHIN2','ECGL','ECGR','LAT1','LAT2','RAT1','RAT2','CHEST','ABD','FLOW','SNORE','DIF5','DIF6','POS','DC2','DC3','DC4','DC5','DC6','DC7','DC8','DC9','DC10','OSAT','PR'}
for i = 1:length(slave_header)
    if ( ~ isempty(find(strcmpi(slave_header{i},master_map)==1) ))
        [r,c] = find(strcmpi(slave_header{i},master_map)==1);
        map(i) = r;
    else
        map(i) = nan;
    end
    
end
end

