function checkreg( volumeArray, center, fov, res )
% CHECKREG uses spm_check_registration
% center: X, Y & Z coordinates of centre voxel -> [0 0 0] is the center of the volume
% fov   : width of field of view in mm         -> 0 o rInf in fullview, 20 means fov=20x20 mm²
% res   : resolution in mm
%
% Exemple: examArray.getExams('Subject03').getSeries('anat').getVolumes('normalized').checkreg

% For the moment, there is no easy method to overide the maxium image displayed.
% This limit value (24 in my case) is hard coded in spm_orthviews -> max_img

AssertIsVolumeArray(volumeArray);

spm_check_registration( volumeArray.paths )

if exist('center','var')
    spm_orthviews('Reposition',center)
end

if exist('fov','var')
    if exist('res','var')
        spm_orthviews('Zoom',fov,res)
    else
        spm_orthviews('Zoom',fov)
    end
end

end % function
