function varargout = mv_jsonread( fname, varargin )
% MV_JSONREAD will use spm_jsonread (compiled routine) to parse .json file
% 
% SYNTAX
%        content                  = MV_JSONREAD( fname )
%       [content, converter_name] = MV_JSONREAD( fname )
%
% INPUTS
%       - fname (REQUIRED) : path of the .json file
%


if nargin==0, help(mfilename('fullpath')); return; end


%%

narginchk(1,2)

content_jsonread = spm_jsonread(fname);
is_dcm2niix = isfield(content_jsonread,'ConversionSoftware') && strcmp(content_jsonread.ConversionSoftware,'dcm2niix');
is_dcmstack = isfield(content_jsonread,'dcmmeta_version'   );

varargout{1} = content_jsonread;

if     nargin==1 && is_dcm2niix
    varargout{2} = 'dcm2niix';
    
elseif nargin==1 && is_dcmstack
    varargout{2} = 'dcmstack';
    
else
    varargout{2} = 'unknown';
    
end


end % function
