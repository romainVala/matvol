function do_T1_mp2rage(funi,finv2,par)

if ~exist('par'),par ='';end

defpar.B0=3;           % in Tesla
defpar.TR=5;           % defpar TR in seconds
defpar.TRFLASH=7.1e-3; % TR of the GRE readout
defpar.TIs=[700e-3 2500e-3];% inversion times - time between middle of refocusing pulse and excitatoin of the k-space center encoding
defpar.NZslices=[88 88];% Slices Per Slab * [PartialFourierInSlice-0.5  0.5]
defpar.FlipDegrees=[4 5];% Flip angle of the two readouts in degrees
defpar.inversionefficiency = 1;
defpar.T1prefix = 'T1map_';
defpar.M0prefix = 'M0map_';

%defpar.filenameUNI=fa{1}; % file with UNI
%defpar.filenameINV2=fai2{1} % file with INV2

par = complet_struct(par,defpar);

a=which('T1M0estimateMP2RAGE')
if isempty(a)
    add
end

was_in_zip = 0;

for nbs = 1:length(funi)
    
    ffuni = funi{nbs};
    ffinv = finv2{nbs};
    
    if strcmp(ffuni(end),'z')
        was_in_zip = 1;
        ffuni = unzip_volume(ffuni);
        ffinv = unzip_volume(ffinv);
    end
    
    M1=load_untouch_nii(ffuni);
    M2=load_untouch_nii(ffinv);
    
    [T1map , M0map , R1map]=T1M0estimateMP2RAGE(M1,M2,par,par.inversionefficiency);
    
    fot1 = addprefixtofilenames(ffuni,'T1map1_');foM0 = addprefixtofilenames(ffuni,'M0map1_')
    
    T1map.img= T1map.img*1000;
    
    save_untouch_nii(T1map, fot1);save_untouch_nii(M0map, foM0)
    
    if was_in_zip
        ffuni = gzip_volume(ffuni);
        ffinv = gzip_volume(ffinv);
        fot1 = gzip_volume(fot1);
        foM0 = gzip_volume(foM0);
    end
end
