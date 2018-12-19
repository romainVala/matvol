function [ modelArray ] = getModel( examArray, regex, type, verbose )
% Syntax  : fetch the models corresponfing to the regex, scanning the defined property.
% Example :  localizer_models = examArray.getModel('localizer'                   );
%           retinotopy_models = examArray.getModel('retinotopy'                  );
%                 both_models = examArray.getModel({'localizer','retinotopy'}    ); <== works with cellstr

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

obj = model; % create empty object, to make some tests
assert( isprop(obj,type) && ischar(obj.(type) ), 'type must refer to a char property of the the @model object' )


%% getModel from @exam

% "empty" array but with the right dimension
modelArray =  model.empty([size(examArray,1) 0]);

for ex = 1 : numel(examArray)
    
    counter = 0;
    
    for mod = 1 : numel(examArray(ex).model)
        
        if ...
                ~isempty(examArray(ex).model(mod).(type)) && ...                 % (type) is present in the @model ?
                ~isempty(regexp(examArray(ex).model(mod).(type), regex, 'once')) % found a corresponding model.(type) to the regex ?
            
            counter = counter + 1;
            modelArray(ex,counter) = examArray(ex).model(mod);
            
        end
        
    end % model in exam
    
end % exam

% I fill the empty models with some pointers and references, only useful for diagnostic and future warnings
% I cannot do this filling during the previous loop, because at that point, we don't know the size (columns) of modelArray
for ex_ = 1 : numel(examArray)
    for ser_ = 1 : size(modelArray,2)
        if isempty(modelArray(ex_,ser_).path)
            modelArray(ex_,ser_).exam = examArray(ex_);
        end
    end
end


%% Error if nothing found

if verbose && isempty(modelArray)
    warning('No @model.%s found for regex [ %s ]', type, regex )
end


end % function
