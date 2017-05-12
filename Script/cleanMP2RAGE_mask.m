
function  cleanMP2RAGE_mask(uni,refmask,output,noise_level)

if ~exist('noise_level','var')
    noise_level=100
end

%% Help
%  cleanMP2RAGE_mask(uni,refmask,output)


for nbs=1:length(uni)
    
    
    %% Header
    
    Vuni=spm_vol(uni{nbs});
    Iuni=spm_read_vols(Vuni);
    
    V_mask = spm_vol(refmask{nbs});
    I1_mask = spm_read_vols(V_mask);
        
    black = I1_mask;
    
    s0=noise_level; % center
    s1=0.1 * noise_level; % std
    
    sigm=1./(1+exp(-(black-s0)./s1));
    
    new=sigm.*Iuni + ((1-sigm).*black);
    
    Vout=Vuni;
    %Vout.dt=[16 0];
    Vout.fname=output{nbs};
    spm_write_vol(Vout,new);
    
    
end


