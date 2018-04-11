function [ volumeArray ] = getVolume( examArray, serie_regex, volume_regex, volume_type )
% Syntax  : fetch the volume_regex volume.(volume_type) corresponfing to the serie_regex, scanning the defined property.
% Example : run_vol  = examArray.getVolume('run' , 'f'           );
%           run1_vol = examArray.getVolume('run1', '^rf$'        );
%           run2_vol = examArray.getVolume('run2', 'rf'          );
%           anat_vol = examArray.getVolume('anat', 't1mpr','name');

%% Check inputs

if nargin < 2
    serie_regex = '.*';
end

if nargin < 3
    volume_regex = '.*';
end

if nargin < 4
    volume_type = 'tag';
end


%% getVolume from @exam

volumeArray = examArray.getSerie(serie_regex).getVolume(volume_regex,volume_type);


end % function
