function [es pdir TE totes] = get_EPI_param_from_json(fi)
%function [es totes] = get_EPI_readout_time(dcminf)
%   es echo spacing (ipat is taken into acount)
%   totes total readouttime in ms

fi=cellstr(char(fi));


for nbs=1:length(fi)
    [pp ff ] = fileparts(fi{nbs});
    try
        fdic = get_subdir_regex_files(pp,'^dic.*json') ;
        fdic{1} = deblank(fdic{1}(1,:) );
        
    catch
        error('can not find json dicom parama in %s ',pp)
    end
    j=loadjson(fdic{1});
    
    hz =  j.global.const.BandwidthPerPixelPhaseEncode;
    
    nbline =  j.global.const.sKSpace_lPhaseEncodingLines;
    
    vo=nifti_spm_vol(fi{1});
    
    if nbline~=vo(1).dim(2)
        fprintf('WARNING nb phase line is %d but taking volume %d',nbline,vo(1).dim(2));
    end
    
    echo_spacing = 1000 ./ hz / vo(1).dim(2);
        
    totes(nbs) = 1/hz * 1E3;

    phase_dir = j.global.const.InPlanePhaseEncodingDirection;
    phase_sign = j.global.const.PhaseEncodingDirectionPositive;
    switch phase_dir
        case 'COL'
            phase_dir = 'y';
        case 'ROW'
            phase_dir = 'x';
    end
    if phase_sign
        phase_dir = [phase_dir '-'];
    end
    
    TE(nbs) = j.global.const.alTE_0_
    es(nbs) = echo_spacing;
    pdir{nbs} = phase_dir;
    
end

if length(pdir)==1
    pdir=char(pdir);
end

% CsaImage.BandwidthPerPixelPhaseEncode"
% "CsaSeries.MrPhoenixProtocol.sKSpace.lPhaseEncodingLines": 128,
% nbline =  j.global.const.sKSpace_lPhaseEncodingLines
% 
% "CsaSeries.MrPhoenixProtocol.sKSpace.dPhaseResolution": 1,
% "CsaSeries.MrPhoenixProtocol.sKSpace.dSeqPhasePartialFourierForSNR": 1,
% "CsaSeries.MrPhoenixProtocol.sKSpace.ucPhasePartialFourier": 4,
