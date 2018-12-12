function [ serieArray ] = getSerie( examArray, regex, type, verbose )
% Syntax  : fetch the series corresponfing to the regex, scanning the defined property.
% Example : run_series  = examArray.getSerie('run'              );
%           run1_series = examArray.getSerie('run1'             );
%           run2_series = examArray.getSerie('run2'             );
%           anat_serie  = examArray.getSerie('S03_t1_mpr','name');
%           anat_serie  = examArray.getSerie({'run1','run2'}    ); <== works with cellstr

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
assert(ischar(type) , 'type must be a char')

% Concatenate if regex is a cellstr
regex = cellstr2regex(regex);


%% Type managment

obj = serie; % create empty object, to make some tests
assert( isprop(obj,type) && ischar(obj.(type) ), 'type must refer to a char property of the the @serie object' )


%% getSerie from @exam

% "empty" array but with the right dimension
serieArray =  serie.empty([size(examArray,1) 0]);

for ex = 1 : numel(examArray)
    
    counter = 0;
    
    for ser = 1 : numel(examArray(ex).serie)
        
        if ...
                ~isempty(examArray(ex).serie(ser).(type)) && ...                 % (type) is present in the @serie ?
                ~isempty(regexp(examArray(ex).serie(ser).(type), regex, 'once')) % found a corresponding serie.(type) to the regex ?
            
            counter = counter + 1;
            serieArray(ex,counter) = examArray(ex).serie(ser);
            
        end
        
    end % serie in exam
    
end % exam

% I fill the empty series with some pointers and references, only useful for diagnostic and future warnings
% I cannot do this filling during the previous loop, because at that point, we don't know the size (columns) of serieArray
for ex_ = 1 : numel(examArray)
    for ser_ = 1 : size(serieArray,2)
        if isempty(serieArray(ex_,ser_).path)
            serieArray(ex_,ser_).exam = examArray(ex_);
        end
    end
end


%% Error if nothing found

if verbose && isempty(serieArray)
    warning('No @serie.%s found for regex [ %s ]', type, regex )
end


end % function
