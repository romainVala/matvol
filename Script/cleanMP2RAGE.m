
function  cleanMP2RAGE(magn1,phase1,magn2,phase2,uni,output,gamma)
%% Help 
% cleanMP2RAGE(magn1,phase1,magn2,phase2,uni,output,gamma)
% computeMP2RAGE The function takes in input 2 magnitude and phase images.
% magn1: filename magnitude image - echo 1
% phase1: filename phase image - echo 1
% magn2: filename magnitude image - echo 2
% phase2: filename phase image - echo 2
% Phase have to be in the range of 0-2pi
% Optional is uni file is given value will be use for inside the brain if empty it will not be taken
% output: filename output image
% OPTIONAL
% gamma: variable whith decrease the noise (default gamma = 0.01)
% black_thr : 
% in case you call it with cell input the first argument is a cell of
% matrix of filepath (order mag1 phase1 mag2 phase2 uni)
% second argument is a cell of output filepath
% example of uses with cells : 
%   anats=get_subdir_regex_multi(suj,{'INV','UNI'}) 
%   fanats=get_subdir_regex_files(anats,'img',1);
%   aa=r_mkdir(suj,'anat')
%   fo =addsuffixtofilenames(aa,'/T1_bg_remove.nii')
%   cleanMP2RAGE(fanats,fo)



if nargin < 7
    gamma=0.01;
end

if iscell(magn1)
    fin = magn1;
    fout = phase1;
    
    for nbs=1:length(magn1)
        M1 = deblank(fin{nbs}(1,:));
        P1 = deblank(fin{nbs}(2,:));
        M2 = deblank(fin{nbs}(3,:));
        P2 = deblank(fin{nbs}(4,:));
        if size(fin{nbs},1)>4
            U = deblank(fin{nbs}(5,:));
        else
            U='';
        end
        
        cleanMP2RAGE(M1,P1,M2,P2,U,fout{nbs});
    end
    return
end

if nargin < 5 || nargin > 7
    error('wrong number of arguments')
end
        
%% Header

V1_mgn=spm_vol(char(magn1));
I1_mgn=spm_read_vols(V1_mgn);

V1_phs=spm_vol(char(phase1));
I1_phs=spm_read_vols(V1_phs);
  
V2_mgn=spm_vol(char(magn2));
I2_mgn=spm_read_vols(V2_mgn);

V2_phs=spm_vol(char(phase2));
I2_phs=spm_read_vols(V2_phs);


%% Normalisation

I1_phs_norm=I1_phs.*(pi/4092);
I2_phs_norm=I2_phs.*(pi/4092);

%% Complexe

complexe_img1=I1_mgn.*cos(I1_phs_norm)+1i*I1_mgn.*sin(I1_phs_norm);
complexe_img2=I2_mgn.*cos(I2_phs_norm)+1i*I2_mgn.*sin(I2_phs_norm);

%% Equation

gamma=gamma*max(I2_mgn(:)).^2;
S=real((conj(complexe_img1).*complexe_img2-gamma)./(I1_mgn.^2+I2_mgn.^2+2*gamma));

S=(S+0.5)*4096;

%the S volume should be clean but since we have some artefac in the phase
%(for the 32 channel coil) we will use this image only for the background

if exist(uni,'file')
    
    black = S;
    
    Vuni=spm_vol(char(uni));
    Iuni=spm_read_vols(Vuni);
    
    
    s0=0.20 * 4096; % center
    s1=0.05 * 4096; % std
    
    sigm=1./(1+exp(-(black-s0)./s1));
    
    new=sigm.*Iuni + ((1-sigm).*black);
else
    new=S;
end

Vout=V1_mgn;
%Vout.dt=[16 0];
Vout.fname=output;
spm_write_vol(Vout,new);

