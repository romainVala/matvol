function varargout = addModel( examArray, varargin)
% General syntax : jobInput = examArray.addModel('dir_regex_1', 'dir_regex_2', ... , 'tag' )
%
% Example :
%
% examArray.addModel('path','to','modeldir','modelname')
%
% examArray.addModel('models', 'retinotpy', 'rotatingWedge', 'model_rotatingWedge') <= Model 1
% examArray.addModel('models', 'retinotpy', 'eccentricity ', 'model_eccentricity' ) <= Model 2
% examArray.addModel('models', 'motor'                     , 'model_motor'        ) <= Model 3
%
% jobInput is the output examArray.getModel("all tags combined").toJob
%

%% Check inputs

% Need at least dir_regex + tag
assert( length(varargin)>=2 , '[%s]: requires at least 2 input arguments dir_regex + tag', mfilename)

recursive_args = varargin(1:end-1); AssertIsCharOrCellstr(recursive_args)
tag            = varargin{end    }; AssertIsCharOrCellstr(tag           )


%% addModel to @exam

for ex = 1 : numel(examArray)
    
    % Remove duplicates
    if examArray(ex).cfg.remove_duplicates
        
        if examArray(ex).model.checkTag(tag)
            examArray(ex).model = examArray(ex).model.removeTag(tag);
        end
        
    else
        
        % Allow duplicate ?
        if examArray(ex).cfg.allow_duplicate % yes
            % pass
        else% no
            if examArray(ex).model.checkTag(tags)
                continue
            end
        end
        
    end
    
    % Fetch the directories
    modelDir  = get_subdir_regex( examArray(ex).path, recursive_args{:} );
    
    % Be sure to add new model to the modelArray
    lengthModel = length(examArray(ex).model);
    counter     = 0;
    
    % Non-empy Dir ?
    if ~isempty(modelDir)
        if length(modelDir) > 1
            
            warning([
                'Found %d/1 dir corresponding to the recursive_regex_path : \n'...
                '%s %s'],...
                length(modelDir), examArray(ex).path, sprintf('%s ', recursive_args{:}))
            
            examArray(ex).is_incomplete = 1; % set incomplete flag
            
        else
            
            try
                SPMfile = get_subdir_regex_files(modelDir,'^SPM.mat$',1);
                counter = counter + 1;
                examArray(ex).model(lengthModel + counter) = model(char(SPMfile), tag, examArray(ex));
            catch
                warning(['SPM.mat file not found in the dir : \n' ...
                    '%s'], char(modelDir))
                examArray(ex).is_incomplete = 1; % set incomplete flag
            end
            
        end
        
    else
        
        warning([
            'Dir not found corresponding to the recursive_regex_path : \n'...
            '%s %s'],...
            examArray(ex).path, sprintf('%s ', recursive_args{:}))
        
        examArray(ex).is_incomplete = 1; % set incomplete flag
        
    end
    
    
end % exam


%% Output

if nargout > 0
    
    varargout{1} = examArray.getModel( tag ).toJob;
    
end

end % function
