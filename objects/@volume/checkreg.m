function checkreg( volumeArray, center, fov, resolution )
% CHECKREG uses spm_check_registration
% center     : X, Y & Z coordinates of centre voxel -> [0 0 0] is the center of the volume
% fov        : width of field of view in mm         -> 0 or Inf is fullview, 20 means fov = 20mm x 20mm
% resolution : resolution in mm
%
% Exemple: examArray.getExam('Subject03').getSerie('anat').getVolume('normalized').checkreg

% For the moment, there is no easy method to overide the maxium image displayed.
% This limit value (24 in my case) is hard coded in spm_orthviews -> max_img


% Remove the empty volumes.path from volumeArray
list = volumeArray.print;
vol = {};
for l = 1 : size(list,1)
    if ~isempty(deblank(list(l,:)))
        vol{end+1} = list(l,:); %#ok<AGROW>
    end
end

spm_check_registration( char(vol) )

if exist('center','var')&& ~isempty(center)
    spm_orthviews('Reposition',center)
end

if exist('fov','var') && ~isempty(fov)
    spm_orthviews('Zoom',fov)
end

if exist('resolution','var') && ~isempty(resolution)
    spm_orthviews('Resolution',resolution)
end

end % function
