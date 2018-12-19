function [ jsonArray ] = getJson( serieArray, regex, type, verbose )
% Syntax  : fetch the json corresponfing to the regex, scanning the defined property.
% Example : run_jsons     = serieArray.getJson('f'                );
%           run1_rf_jsons = serieArray.getJson('^rf'              );
%           anat_json     = serieArray.getJson('S03_t1_mpr','name');
%           anat_json     = serieArray.getJson({'^s','^brain'}    ); <== works with cellstr

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

obj = json; % create empty object, to make some tests
assert( isprop(obj,type) && ischar(obj.(type) ), 'type must refer to a char property of the the @json object' )


%% getJson from @serie

% "empty" array but with the right dimension
jsonArray =  json.empty([size(serieArray) 0]);

for ex = 1 : size(serieArray,1)
    
    for ser = 1 : size(serieArray,2)
        
        counter = 0;
        
        for vol = 1 : numel(serieArray(ex,ser).json)
            
            if ...
                    ~isempty(serieArray(ex,ser).json(vol).(type)) && ...                      % (type) is present in the @json ?
                    ~isempty(regexp(serieArray(ex,ser).json(vol).(type)(1,:), regex, 'once')) % found a corresponding json.(type) to the regex ?
                
                % Above is a problem : I only scan the first line of char array : regexp doesnt work on char array, only char vector
                % It could also work if we scan over a cellstr, but the management would bring other problems : which line to take into account ?
                
                counter = counter + 1;
                jsonArray(ex,ser,counter) = serieArray(ex,ser).json(vol);
                
            end
            
        end % vol in serie
        
    end % serie in exam
    
end % exam


%% Error if nothing found

if verbose && isempty(jsonArray)
    warning('No @json.%s found for regex [ %s ]', type, regex )
end


end % function
