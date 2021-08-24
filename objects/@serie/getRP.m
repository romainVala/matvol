function [ rpArray ] = getRP( serieArray, regex, type, verbose )
% Syntax  : fetch the rp corresponfing to the regex, scanning the defined property.
% Example : rp = serieArray.getRP('rp'                     );
%           rp = serieArray.getRP({'^rp_spm','^rp_fsl'}    ); <== works with cellstr


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

obj = rp; % create empty object, to make some tests
assert( isprop(obj,type) && ischar(obj.(type) ), 'type must refer to a char property of the the @rp object' )


%% getRP from @serie

% "empty" array but with the right dimension
rpArray =  rp.empty([size(serieArray) 0]);

for ex = 1 : size(serieArray,1)
    
    for ser = 1 : size(serieArray,2)
        
        counter = 0;
        
        for vol = 1 : numel(serieArray(ex,ser).rp)
            
            if ...
                    ~isempty(serieArray(ex,ser).rp(vol).(type)) && ...                      % (type) is present in the @rp ?
                    ~isempty(regexp(serieArray(ex,ser).rp(vol).(type)(1,:), regex, 'once')) % found a corresponding rp.(type) to the regex ?
                
                % Above is a problem : I only scan the first line of char array : regexp doesnt work on char array, only char vector
                % It could also work if we scan over a cellstr, but the management would bring other problems : which line to take into account ?
                
                counter = counter + 1;
                rpArray(ex,ser,counter) = serieArray(ex,ser).rp(vol);
                
            end
            
        end % vol in serie
        
    end % serie in exam
    
end % exam


%% Error if nothing found

if verbose && isempty(rpArray)
    warning('No @rp.%s found for regex [ %s ]', type, regex )
end


end % function
