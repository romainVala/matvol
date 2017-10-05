function [fo job] = mask_erode(fin,par)
%function fo = do_fsl_bin(f,prefix,seuil)
%if seuil is a vector [min max] min<f<max
%if seuil is a number f>seuil


if ~exist('par','var'),par ='';end

defpar.type = {'erode','dilate'};
defpar.suffix = '';
for kk=1:length(defpar.type)
    defpar.suffix=[defpar.suffix ,'_',defpar.type{kk}];
end
defpar.numpass  = 1;

par = complet_struct(par,defpar);

fo = addsuffixtofilenames(fin,par.suffix);

for nbf=1:length(fin)
    
    [pp ff ] = fileparts(fin{nbf});
    cmd = sprintf('cd %s\n',pp);
    for k=1:length(par.type)
        if k==1
            cmd = sprintf('%s maskfilter -force -npass %d %s %s ',cmd,par.numpass,fin{nbf},par.type{k});
        else
            cmd =  sprintf('%s maskfilter -force -npass %d - %s  ',cmd,par.numpass,par.type{k});
        end
        if k==length(par.type)
            cmd = sprintf('%s %s',cmd,fo{nbf});
        else
            cmd = sprintf('%s - | ',cmd);
        end
    end
    
    job{nbf} = cmd;
    
end

job = do_cmd_sge(job,par);