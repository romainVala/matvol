function fo = ants_buildTemplate(fin,outdir,par)
%function fo = do_fsl_bin(f,prefix,seuil)
%if seuil is a vector [min max] min<f<max
%if seuil is a number f>seuil


if ~exist('par'),par ='';end

if ischar(outdir)
    outdir = {outdir};
end


defpar.sge=1;
defpar.jobname = 'antsBT';
defpar.walltime = '00:10:00';
defpar.copy = 'link'; % or "copy"
defpar.nbthread = 1 ;
defpar.extra_args = '';


par = complet_struct(par,defpar);

if length(outdir)==1 %then all files should be used
    fin ={char(fin)};
end


for k=1:length(outdir)
    od = outdir{k}
    if ~exist(od,'dir')
        mkdir(od)
    end
    
    
    for kk=1:size(fin{k},1)
        [pp ff ext] = fileparts(fin{k}(kk,:));
        [pp ff ext2] = fileparts(ff);
        
        fo{kk} = fullfile(od,sprintf('Suj%.2d%s%s',kk,ext2,ext));
    end
    r_movefile(cellstr(char(fin(k)))',fo,par.copy);
    
    if par.nbthread>1
        extra_args = sprintf('%s -c2 -j %d',par.extra_args, par.nbthread)
    else
        extra_args = sprintf('%s -c0 ', par.extra_args)
    end
    
    cmd{k}  =  sprintf('cd %s \n buildtemplateparallel.sh %s -d 3 -o ants_ Suj* \n',od, extra_args);

   
end


do_cmd_sge(cmd,par)
