function [ mvFileArray ] = getFile( serieArray, target, regex, type, verbose )
% Syntax  : fetch the <target> corresponfing to the regex, scanning the defined property.
% Example : run_volumes     = serieArray.get<target>('f'                );
%           run1_rf_volumes = serieArray.get<target>('^rf'              );
%           anat_volume     = serieArray.get<target>('S03_t1_mpr','name');
%           anat_volume     = serieArray.get<target>({'^s','^brain'}    ); <== works with cellstr


%% Check inputs

if ~exist('regex','var')
    regex = '.*';
end

if ~exist('type','var')
    type = 'tag';
end

if ~exist('verbose','var')
    verbose = 1;
end


AssertIsCharOrCellstr(regex)
assert(ischar(type ), 'type must be a char')

% Concatenate if regex is a cellstr
regex = cellstr2regex(regex);


%% Type managment

obj = feval(target); % create empty object, to make some tests
assert( isprop(obj,type) && ischar(obj.(type) ), 'type must refer to a char property of the the @%s object', target )


%% get<target> from @serie

% "empty" array but with the right dimension
mvFileArray =  obj.empty([size(serieArray) 0]);

for ex = 1 : size(serieArray,1)
    
    for ser = 1 : size(serieArray,2)
        
        counter = 0;
        
        for vol = 1 : numel(serieArray(ex,ser).(target))
            
            if ...
                    ~isempty(serieArray(ex,ser).(target)(vol).(type)) && ...                      % (type) is present in the @volume ?
                    ~isempty(regexp(serieArray(ex,ser).(target)(vol).(type)(1,:), regex, 'once')) % found a corresponding volume.(type) to the regex ?
                
                % Above is a problem : I only scan the first line of char array : regexp doesnt work on char array, only char vector
                % It could also work if we scan over a cellstr, but the management would bring other problems : which line to take into account ?
                
                counter = counter + 1;
                mvFileArray(ex,ser,counter) = serieArray(ex,ser).(target)(vol);
                
            end
            
        end % vol in serie
        
    end % serie in exam
    
end % exam


%% Error if nothing found

if verbose && isempty(mvFileArray)
    warning('No @%s.%s found for regex [ %s ]', target, type, regex )
end


end % function
