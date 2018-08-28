function [ resultArray ] = checkIntegrity( mvArray )
%CHECKINTEGRITY verify if all mvObject.path exist recursively

resultArray = nan( size(mvArray) );

classname = class(mvArray);

for idx = 1 : numel( mvArray )
    
    
    if ~isempty(mvArray(idx).path)
        
        result = exist(deblank(mvArray(idx).path(1,:))) ~= 0; %#ok<EXIST>
        
        % Recursivity
        if result == 1
            
            switch classname
                case 'exam'
                    res1 = mvArray(idx).serie.checkIntegrity;
                    res2 = mvArray(idx).model.checkIntegrity;
                    result = all([res1 res2]);
                case 'serie'
                    res1 = mvArray(idx).volume.checkIntegrity;
                    res2 = mvArray(idx).stim  .checkIntegrity;
                    res3 = mvArray(idx).json  .checkIntegrity;
                    result = all([res1 res2 res3]);
                case 'model'
                    % pass
                case 'volume'
                    % pass
                case 'stim'
                    % pass
                case 'json'
                    % pass
                otherwise
                    warning('non-coded routine for the object')
            end
            
        end % reccursivity, when necessary
        
        resultArray(idx) = result;
        
    end % non empty path
    
end % for

end % function
