function [suj empty_suj] = get_series(serie_name,suj,reg_ex,varargin)


ind_to_remove = [];
ser = {};

for nbsuj = 1:length(suj.sujdir)
    if ~isempty(varargin)
        aa = get_subdir_regex(suj.sujdir(nbsuj),reg_ex,varargin);
    else
        aa = get_subdir_regex(suj.sujdir(nbsuj),reg_ex);
    end
    
    if length(aa) == 1;
        ser(nbsuj) = aa;
        
    else
        ser{nbsuj} = aa;
    end
    
    if isempty(aa)
        ind_to_remove(end+1) = nbsuj;
    end
    
    
   
end

if ~isempty(ind_to_remove)
    fn = fieldnames(suj);
    for nf=1:length(fn)
        aa = getfield(suj,fn{nf});
        aa(ind_to_remove) = [];
        suj = setfield(suj,fn{nf},aa);
    end
    ser(ind_to_remove) = [];    
end

suj = setfield(suj,serie_name,ser);
    
% ind_to_remove = [];
% ser = {};
% 
% for nbsuj = 1:length(suj)
%     if ~isempty(varargin)
%         aa = get_subdir_regex(suj(nbsuj).sujdir,reg_ex,varargin);
%     else
%         aa = get_subdir_regex(suj(nbsuj).sujdir,reg_ex);
%     end
%     
%     if length(aa) > 1;
%         %error('find %d subdir for subject %s \n redefine the regular expression to get only one subdir',...
%         %    length(aa),suj.sujdir{nbsuj});
%     end
%     
%     if isempty(aa)
%         ind_to_remove(end+1) = nbsuj;
%     end
%     
%     so(nbsuj) = setfield(suj(nbsuj),serie_name,aa);
%     
% end
% 
% suj = so;
% 
% if ~isempty(ind_to_remove)
%     fn = fieldnames(suj);
%     for nf=1:length(fn)
%         aa = getfield(suj,fn{nf});
%         aa(ind_to_remove) = [];
%         suj = setfield(suj,fn{nf},aa);
%     end
%     ser(ind_to_remove) = [];
% end

