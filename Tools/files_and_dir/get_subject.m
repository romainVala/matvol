function suj = get_subject(indir,reg_ex,varargin)

if ~isempty(varargin)
    o = get_subdir_regex(indir,reg_ex,varargin);
else
    o = get_subdir_regex(indir,reg_ex);
end

% for k=1:length(o)
%     suj(k).sujdir = o{k};
% end

suj.sujdir=o;