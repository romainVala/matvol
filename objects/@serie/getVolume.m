function [ volumeArray ] = getVolume( serieArray, regex, type, verbose )
% Syntax  : fetch the volume corresponfing to the regex, scanning the defined property.
% Example : run_volumes     = serieArray.getVolume('f'                );
%           run1_rf_volumes = serieArray.getVolume('^rf'              );
%           anat_volume     = serieArray.getVolume('S03_t1_mpr','name');
%           anat_volume     = serieArray.getVolume({'^s','^brain'}    ); <== works with cellstr

%% Check inputs

if nargin < 2
    regex = '.*';
end

if nargin < 3
    type = 'tag';
end

if nargin < 4
    verbose = 1;
end


AssertIsCharOrCellstr(regex)
assert(ischar(type ), 'type must be a char')

% Concatenate if regex is a cellstr
regex = cellstr2regex(regex);


%% Type managment

obj = volume; % create empty object, to make some tests
assert( isprop(obj,type) && ischar(obj.(type) ), 'type must refer to a char property of the the @volume object' )


%% getVolume from @serie

% "empty" array but with the right dimension
volumeArray =  volume.empty([size(serieArray) 0]);

for ex = 1 : size(serieArray,1)
    
    for ser = 1 : size(serieArray,2)
        
        counter = 0;
        
        for vol = 1 : numel(serieArray(ex,ser).volume)
            
            if ...
                    ~isempty(serieArray(ex,ser).volume(vol).(type)) && ...                      % (type) is present in the @volume ?
                    ~isempty(regexp(serieArray(ex,ser).volume(vol).(type)(1,:), regex, 'once')) % found a corresponding volume.(type) to the regex ?
                
                % Above is a problem : I only scan the first line of char array : regexp doesnt work on char array, only char vector
                % It could also work if we scan over a cellstr, but the management would bring other problems : which line to take into account ?
                
                counter = counter + 1;
                volumeArray(ex,ser,counter) = serieArray(ex,ser).volume(vol);
                
            end
            
        end % vol in serie
        
    end % serie in exam
    
end % exam


%% Error if nothing found

if verbose && isempty(volumeArray)
    warning('No @volume.%s found for regex [ %s ]', type, regex )
end


end % function
