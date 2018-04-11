function [ volumeArray ] = getStim( examArray, serie_regex, stim_regex, stim_type )
% Syntax  : fetch the stim_regex volume.(stim_type) corresponfing to the serie_regex, scanning the defined property.
% Example : run_vol  = examArray.getStim('run' , 'f'                      );
%           run1_vol = examArray.getStim('run1', '^rf$'                   );
%           run2_vol = examArray.getStim('run2', 'rf'                     );
%           run_vol  = examArray.getStim('run2', 'behav_data.mat', 'name' );

%% Check inputs

if nargin < 2
    serie_regex = '.*';
end

if nargin < 3
    stim_regex = '.*';
end

if nargin < 4
    stim_type = 'tag';
end


%% getStim from @exam

volumeArray = examArray.getSerie(serie_regex).getStim(stim_regex,stim_type);


end % function
