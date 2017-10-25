function [ volumeArray ] = getVolumes( serieArray, regex, type )
% Syntax  : fetch the volume corresponfing to the regex, scanning the defined property.
% Example : run_volumes     = serieArray.getVolumes('f'                );
%           run1_rf_volumes = serieArray.getVolumes('^rf'              );
%           anat_volume     = serieArray.getVolumes('S03_t1_mpr','name');
%           anat_volume     = serieArray.getVolumes({'^s','^brain'}    ); <== works with cellstr

%% Check inputs

AssertIsSerieArray(serieArray);

if nargin < 2
    regex = '.*';
end

if nargin < 3
    type = 'tag';
end

AssertIsCharOrCellstr(regex)
assert(ischar(type ), 'type must be a char')

% Concatenate if regex is a cellstr
regex = cellstr2regex(regex);


%% Type managment

obj = volume; % create empty object, to make some tests
assert( isprop(obj,type) && ischar(obj.(type) ), 'type must refer to a char property of the the @volume object' )


%% getVolumes from @serie

volumeArray = volume.empty;

for ex = 1 : size(serieArray,1)
    
    for ser = 1 : size(serieArray,2)
        
        counter = 0;
        
        for vol = 1 : numel(serieArray(ex,ser).volumes)
            
            if ...
                    ~isempty(serieArray(ex,ser).volumes(vol).(type)) && ...                      % (type) is present in the @volume ?
                    ~isempty(regexp(serieArray(ex,ser).volumes(vol).(type)(1,:), regex, 'once')) % found a corresponding volume.(type) to the regex ?
                
                % Above is a problem : I only scan the first line of char array : regexp doesnt work on char array, only char vector
                % It could also work if we scan over a cellstr, but the management would bring other problems : which line to take into account ?
                
                counter = counter + 1;
                volumeArray(ex,ser,counter) = serieArray(ex,ser).volumes(vol);
                
            end
            
        end % vol in serie
        
    end % serie in exam
    
end % exam

end % function
