function dirname = nettoie_dir(dirname)

if iscell(dirname)
    for k=1:length(dirname)
        dirname{k} = nettoie_dir(dirname{k});
    end
    return
  end    
  
% cherche s'il y a des caracteres non alphanumeriques dans la chaine
str = isstrprop(dirname,'alphanum');
spec = find(~str);
% remplace les caracteres non alphanumeriques par des '_'
dirname(spec) = '_';

ii =strfind(dirname,'µ');
dirname(ii) = 'm';

%trouve le é
dirname(double(dirname)==233) = 'e';
%trouve le è
dirname(double(dirname)==232) = 'e';
%trouve le ^o
dirname(double(dirname)==244) = 'o';

% pour fignoler, on supprime un '_' s'il y en a 2 qui se suivent
while ~isempty(strfind(dirname,'__'));
    dirname = strrep(dirname,'__','_');
end
% toujours pour fignoler, si le nom se termine par un '_', on l'elimine
if(dirname(length(dirname)) == '_')
    dirname(length(dirname)) = '';
end
if(dirname(1) == '_')
    dirname(1) = '';
end


