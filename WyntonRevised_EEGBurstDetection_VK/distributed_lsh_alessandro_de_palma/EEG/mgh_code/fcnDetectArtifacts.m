function a=fcnDetectArtifacts(Fs,data,dataEMG);

%% check for artifacts in 5 second blocks-- each block is counted all-or-none as artifact

% returns vector a, with 1=artifact, 0=no artifact

% checks: 
% 1. amplitude in any channel > 500uv 
% 2. loose channel (gotman criteria)
% 3. emg artifact >50%

i0=1; i1=1;
ct=0; 
dn=0; 
Nt=size(data,2); 
chunkSize=5; % 5 second chunks
a=zeros(1,Nt); 

while ~dn  
    %% get next data chunk
    i0=i1; 
    if i1==Nt; dn=1; end
    
    i1=i0+round(Fs*chunkSize); i1=min(i1,Nt); i01=i0:i1; ct=ct+1; % get next data chunk
    A(ct)=0; % set to 1 if artifact is detected
    
    s=data(i01); % 5 second data chunk
    de=dataEMG(i01);
    
    %% check for saturation
    if max(s>500); A(ct)=1; end; % max amplitude >500uv
    
    %% check for emg artifact
    v=std(de); if v>5; A(ct)=1; end; % max amplitude >500uv
    
    %% check for implausibly low variance
    v=std(s); if v<0.0001; A(ct)=1; end; % max amplitude >500uv
    
    a(i01)=A(ct); 
end
