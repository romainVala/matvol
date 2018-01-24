function [ modelArray ] = getModel( examArray, regex, type )
% Syntax  : fetch the models corresponfing to the regex, scanning the defined property.
% Example :  localizer_models = examArray.getModel('localizer'                   );
%           retinotopy_models = examArray.getModel('retinotopy'                  );
%                 both_models = examArray.getModel({'localizer','retinotopy'}    ); <== works with cellstr

%% Check inputs

AssertIsExamArray(examArray);

if nargin < 2
    regex = '.*';
end

if nargin < 3
    type = 'tag';
end

AssertIsCharOrCellstr(regex)
assert(ischar(type) , 'type must be a char')

% Concatenate if regex is a cellstr
regex = cellstr2regex(regex);


%% Type managment

obj = model; % create empty object, to make some tests
assert( isprop(obj,type) && ischar(obj.(type) ), 'type must refer to a char property of the the @model object' )


%% getModel from @exam

% Create 0x0 @model object
modelArray = model.empty;

for ex = 1 : numel(examArray)
    
    counter = 0;
    
    for ser = 1 : numel(examArray(ex).models)
        
        if ...
                ~isempty(examArray(ex).models(ser).(type)) && ...                 % (type) is present in the @model ?
                ~isempty(regexp(examArray(ex).models(ser).(type), regex, 'once')) % found a corresponding model.(type) to the regex ?
            
            counter = counter + 1;
            modelArray(ex,counter) = examArray(ex).models(ser);
            
        end
        
    end % model in exam
    
end % exam

% I fill the empty models with some pointers and references, only useful for diagnostic and future warnings
% I cannot do this filling during the previous loop, because at that point, we don't know the size (columns) of modelArray
for ex_ = 1 : size(modelArray,1)
    for ser_ = 1 : size(modelArray,2)
        if isempty(modelArray(ex_,ser_).(type))
            modelArray(ex_,ser_).exam = examArray(ex);
        end
    end
end

end % function
