
function S=computeMP2RAGE(magn1,phase1,magn2,phase2,output,gamma,equation)
%% Help
% computeMP2RAGE The function takes in input 2 magnitude and phase images.
% magn1: filename magnitude image - echo 1
% phase1: filename phase image - echo 1
% magn2: filename magnitude image - echo 2
% phase2: filename phase image - echo 2
% Phase have to be in the range of 0-2pi
% output: filename output image
% OPTIONAL
% gamma: variable whith decrease the noise (default gamma = 0.4)
% equation: method used - simple or complex (default complex)

if nargin < 6
    gamma=0.01;
end
if nargin < 7
     equation=2;
end

if iscell(magn1)
    for nbs=1:length(magn1)
        computeMP2RAGE(magn1{nbs}(1,:),magn1{nbs}(2,:),magn1{nbs}(3,:),magn1{nbs}(4,:),phase1{nbs});
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

if equation==1
    gamma=gamma*max(I2_mgn(:));
    S=abs(complexe_img1./(complexe_img2+gamma));
elseif equation==2
    gamma=gamma*max(I2_mgn(:)).^2;
    S=real((conj(complexe_img1).*complexe_img2-gamma)./(I1_mgn.^2+I2_mgn.^2+2*gamma));
else
    error('incorrect equation');
end

%romain why ?
S=(S+0.5)*1000;

Vout=V1_mgn;
Vout.dt=[16 0];
Vout.fname=output;
spm_write_vol(Vout,S);

